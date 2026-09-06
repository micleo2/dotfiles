#!/usr/bin/env python3
"""Bridge between the shell and the raw HID link of one or more QMK boards.

Run with no arguments it is a daemon for services/Qmk.qml. It knows the
boards by USB id (BOARDS below, matching ~/oss/keyboards/host/boards/*.json), opens each
one's raw HID interface (usage page 0xFF60, usage 0x61) as it appears,
says HELLO, repeats it every two seconds as a keep-alive, and turns every
packet a board pushes into one JSON line on stdout, tagged with the board's
name. Commands arrive as JSON lines on stdin, addressed by "board". A board
that goes away is reported and looked for again.

    stdout events
      {"event": "connected", "board": "unicorne", "path": "..."}
      {"event": "disconnected", "board": "unicorne"}
      {"event": "state", "board": "unicorne", "layers": 1, "defaultLayers": 1,
       "layer": 0, "layerCount": 8, "rgbOn": true, "mode": 3, "modeCount": 40,
       "h": 0, "s": 0, "v": 120, "max": 150, "capsWord": false, "os": 3}
      {"event": "key", "board": "unicorne", "row": 1, "col": 4,
       "pressed": true, "keycode": 4}
      {"event": "error", "board": "unicorne", "message": "..."}

    stdin commands  (all take "board"; without it, every open board)
      {"cmd": "state"}
      {"cmd": "brightness", "value": 0..max}
      {"cmd": "toggle"}
      {"cmd": "enable", "on": true}
      {"cmd": "mode", "step": 1 | -1}   or   {"cmd": "mode", "id": n}
      {"cmd": "hsv", "h": 0, "s": 0, "v": 0}
      {"cmd": "layer", "toggle": n}     or   {"cmd": "layer", "clear": true}

One-shot use from a terminal:

    qmk-bridge.py state [board]                      one state line per board
    qmk-bridge.py send '{"cmd": "toggle"}' [board]   send, then print state

The protocol is documented in ~/oss/keyboards/users/micleo2/host_link.c. Needs
python-hid (the `hid` module, hidapi) and read/write access to the hidraw
nodes: a udev rule tagging each board's VID/PID with uaccess (keyboards/host/udev).
"""

import json
import queue
import struct
import sys
import threading
import time

try:
    import hid
except ImportError:
    sys.stdout.write(json.dumps({"event": "error", "message": "python-hid is not installed"}) + "\n")
    sys.stdout.flush()
    sys.exit(1)

# (vid, pid) -> board name, as in the keymap JSON the shell draws.
BOARDS = {
    (0x4273, 0x7563): "unicorne",
    (0x4273, 0x7685): "lulu",
    (0x303A, 0x4044): "svalboard",
}

USAGE_PAGE = 0xFF60
USAGE = 0x61
PACKET = 32

CMD_HELLO = 0x41
CMD_STATE = 0x42
CMD_RGB_VAL = 0x50
CMD_RGB_TOGGLE = 0x51
CMD_RGB_ENABLE = 0x52
CMD_RGB_MODE_STEP = 0x53
CMD_RGB_MODE = 0x54
CMD_RGB_HSV = 0x55
CMD_LAYER_TOGGLE = 0x60
CMD_LAYER_CLEAR = 0x61
CMD_BYE = 0x6F

EV_STATE = 0x80
EV_KEY = 0x81

KEEPALIVE_S = 2.0
SCAN_S = 1.0


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def find_paths():
    """{board name: hidraw path} for every known board's raw interface."""
    out = {}
    for info in hid.enumerate():
        name = BOARDS.get((info.get("vendor_id"), info.get("product_id")))
        if name and info.get("usage_page") == USAGE_PAGE and info.get("usage") == USAGE:
            out.setdefault(name, info["path"])
    return out


def packet(cmd, *args):
    body = bytes([cmd] + [a & 0xFF for a in args])
    # hidraw wants the report id in front; the boards have none, so zero.
    return b"\x00" + body.ljust(PACKET, b"\x00")


def command_packet(cmd):
    """The packet for a command, or None for one that is not one."""
    kind = cmd.get("cmd")
    if kind == "state":
        return packet(CMD_STATE)
    if kind == "brightness":
        return packet(CMD_RGB_VAL, max(0, min(255, int(cmd.get("value", 0)))))
    if kind == "toggle":
        return packet(CMD_RGB_TOGGLE)
    if kind == "enable":
        return packet(CMD_RGB_ENABLE, 1 if cmd.get("on") else 0)
    if kind == "mode":
        if "id" in cmd:
            return packet(CMD_RGB_MODE, int(cmd["id"]))
        return packet(CMD_RGB_MODE_STEP, 0xFF if int(cmd.get("step", 1)) < 0 else 1)
    if kind == "hsv":
        return packet(CMD_RGB_HSV, int(cmd.get("h", 0)), int(cmd.get("s", 0)), int(cmd.get("v", 0)))
    if kind == "layer":
        if cmd.get("clear"):
            return packet(CMD_LAYER_CLEAR)
        return packet(CMD_LAYER_TOGGLE, int(cmd.get("toggle", 0)))
    return None


def parse(data):
    """A board packet as an event dict, or None (VIA echoes commands back;
    those and anything else unknown are dropped here)."""
    if not data:
        return None
    if data[0] == EV_STATE and len(data) >= 21:
        layers, default_layers = struct.unpack_from("<II", data, 2)
        return {
            "event": "state",
            "version": data[1],
            "layers": layers,
            "defaultLayers": default_layers,
            "layer": data[10],
            "layerCount": data[11],
            "rgbOn": bool(data[12]),
            "mode": data[13],
            "h": data[14],
            "s": data[15],
            "v": data[16],
            "max": data[17],
            "modeCount": data[18],
            "capsWord": bool(data[19]),
            "os": data[20],
        }
    if data[0] == EV_KEY and len(data) >= 6:
        return {
            "event": "key",
            "row": data[1],
            "col": data[2],
            "pressed": bool(data[3]),
            "keycode": data[4] | (data[5] << 8),
        }
    return None


def stdin_reader(commands):
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            commands.put(json.loads(line))
        except ValueError:
            emit({"event": "error", "message": "not JSON: " + line})
    commands.put(None)


class Link:
    def __init__(self, name, path):
        self.name = name
        self.path = path
        self.device = hid.Device(path=path)
        self.last_hello = 0.0

    def close(self, goodbye):
        try:
            if goodbye:
                self.device.write(packet(CMD_BYE))
            self.device.close()
        except Exception:  # noqa: BLE001
            pass


def serve():
    commands = queue.Queue()
    threading.Thread(target=stdin_reader, args=(commands,), daemon=True).start()
    links = {}
    failed = {}
    last_scan = 0.0

    while True:
        now = time.monotonic()

        # Look for boards that are not open yet.
        if now - last_scan >= SCAN_S:
            last_scan = now
            for name, path in find_paths().items():
                if name in links:
                    continue
                try:
                    links[name] = Link(name, path)
                except Exception as error:  # noqa: BLE001 - hidapi raises plain exceptions
                    if failed.get(name) != str(error):
                        failed[name] = str(error)
                        emit({"event": "error", "board": name, "message": f"cannot open {path.decode(errors='replace')}: {error}"})
                    continue
                failed.pop(name, None)
                emit({"event": "connected", "board": name, "path": path.decode(errors="replace")})

        # Commands from the shell.
        try:
            while True:
                cmd = commands.get_nowait()
                if cmd is None:
                    for link in links.values():
                        link.close(True)
                    return
                out = command_packet(cmd)
                if out is None:
                    emit({"event": "error", "message": "unknown command: " + json.dumps(cmd)})
                    continue
                targets = [links[cmd["board"]]] if cmd.get("board") in links else ([] if cmd.get("board") else list(links.values()))
                for link in targets:
                    try:
                        link.device.write(out)
                    except Exception as error:  # noqa: BLE001
                        emit({"event": "error", "board": link.name, "message": str(error)})
        except queue.Empty:
            pass

        if not links:
            time.sleep(0.2)
            continue

        # Keep-alives and reads, a short timeout per board so one quiet
        # board does not starve another.
        for name, link in list(links.items()):
            try:
                if now - link.last_hello >= KEEPALIVE_S:
                    link.device.write(packet(CMD_HELLO))
                    link.last_hello = now
                data = link.device.read(PACKET, timeout=20)
                event = parse(data)
                if event is not None:
                    event["board"] = name
                    emit(event)
            except Exception as error:  # noqa: BLE001 - any failure means the board went away
                emit({"event": "error", "board": name, "message": str(error)})
                link.close(False)
                del links[name]
                emit({"event": "disconnected", "board": name})


def one_shot(cmd, only):
    paths = find_paths()
    if only:
        paths = {k: v for k, v in paths.items() if k == only}
    if not paths:
        sys.exit("no raw HID interface for " + (only or "any known board") + " (is the firmware flashed with host_link.c, and is the board plugged in?)")
    for name, path in paths.items():
        device = hid.Device(path=path)
        # HELLO only answers with STATE when it opens the link, and the
        # shell's own bridge usually holds it open already; STATE always
        # answers.
        device.write(packet(CMD_HELLO))
        if cmd is not None:
            out = command_packet(cmd)
            if out is None:
                sys.exit("unknown command: " + json.dumps(cmd))
            device.write(out)
        device.write(packet(CMD_STATE))
        deadline = time.monotonic() + 1.0
        state = None
        while time.monotonic() < deadline:
            event = parse(device.read(PACKET, timeout=200))
            if event and event["event"] == "state":
                state = event
                break
        device.write(packet(CMD_BYE))
        device.close()
        if state is None:
            print(json.dumps({"board": name, "error": "no state from the board"}))
        else:
            state["board"] = name
            print(json.dumps(state))


def main(argv):
    if len(argv) == 1:
        serve()
    elif argv[1] == "state":
        one_shot(None, argv[2] if len(argv) > 2 else None)
    elif argv[1] == "send" and len(argv) >= 3:
        one_shot(json.loads(argv[2]), argv[3] if len(argv) > 3 else None)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
