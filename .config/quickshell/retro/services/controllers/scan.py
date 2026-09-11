#!/usr/bin/env python3
"""List the gamepads the kernel currently has, as one JSON array on stdout.

Run by services/Controllers.qml on every udev joystick event. Grew out of
the DualSense probe in
~/creative-synced/obsidian/investigations/dualsense-detect.sh, generalised
to any pad.

Which input devices are gamepads is udev's call, not ours: the kernel hands
a /dev/input/js* node to anything with absolute axes, so a raw walk of
/sys/class/input/js* also lists a virtual mouse and the DualSense's motion
sensors. udev's input_id builtin sorts that out and stamps the real pads
with ID_INPUT_JOYSTICK=1, which is the same classification SDL, Steam and
libinput trust. Each js node is asked about individually: dumping the whole
udev database costs twenty times as much for the same answer.

Virtual pads are left out. Steam Input, xboxdrv and friends create a uinput
device that udev classes as a joystick too, but it stands in for a physical
pad that is already listed; it has no parent device, which is the tell.

Each entry:

    {"key": "<sysfs path of the HID/USB parent, stable while connected>",
     "name": "DualSense",             friendly name from PRODUCTS, else the kernel's
     "kernelName": "Wireless Controller",
     "transport": "Bluetooth" | "USB" | "",
     "vid": "054c", "pid": "0ce6",
     "uniq": "02:00:a3:4b:07:c9",     MAC for Bluetooth pads, often "" over USB
     "powerSupply": "ps-controller-battery-02:00:a3:4b:07:c9" | "",
     "capacity": 55 | null,           from sysfs, a fallback for UPower
     "status": "Discharging" | "Charging" | "Full" | ""}

`powerSupply` is the name upowerd uses as the device's native-path, which is
how the shell joins a pad to its live UPower battery. One entry per physical
pad: a driver that exposes two joystick nodes for one device (xpadneo does)
collapses onto the shared parent. Exits 0 with `[]` at worst, so a missing
udevadm is an answer rather than a spawn error in the shell; sysfs and udev
strings are decoded leniently, since one odd byte anywhere must not take
the whole list down.
"""

import glob
import json
import os
import subprocess
import sys

PRODUCTS = {
    ("054c", "0ce6"): "DualSense",
    ("054c", "0df2"): "DualSense Edge",
    ("054c", "05c4"): "DualShock 4",
    ("054c", "09cc"): "DualShock 4",
    ("054c", "0268"): "DualShock 3",
}

TRANSPORTS = {
    "0003": "USB",
    "0005": "Bluetooth",
}


def read(path, default=""):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read().strip()
    except OSError:
        return default


def is_joystick(js_path):
    try:
        out = subprocess.run(
            ["udevadm", "info", "-q", "property", "-p", js_path],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        ).stdout
    except OSError:
        return False
    return "ID_INPUT_JOYSTICK=1" in out.splitlines()


def describe(inp, parent):
    bus = read(os.path.join(inp, "id", "bustype"))
    vid = read(os.path.join(inp, "id", "vendor")).lower()
    pid = read(os.path.join(inp, "id", "product")).lower()
    kernel_name = read(os.path.join(inp, "name"))

    power_supply = ""
    capacity = None
    status = ""
    try:
        supplies = sorted(os.listdir(os.path.join(parent, "power_supply")))
    except OSError:
        supplies = []
    if supplies:
        power_supply = supplies[0]
        ps = os.path.join(parent, "power_supply", power_supply)
        try:
            capacity = int(read(os.path.join(ps, "capacity")))
        except ValueError:
            capacity = None
        status = read(os.path.join(ps, "status"))

    return {
        "key": parent,
        "name": PRODUCTS.get((vid, pid), kernel_name),
        "kernelName": kernel_name,
        "transport": TRANSPORTS.get(bus, ""),
        "vid": vid,
        "pid": pid,
        "uniq": read(os.path.join(inp, "uniq")),
        "powerSupply": power_supply,
        "capacity": capacity,
        "status": status,
    }


def main():
    pads = {}
    for js in sorted(glob.glob("/sys/class/input/js*")):
        inp = os.path.realpath(os.path.join(js, "device"))
        link = os.path.join(inp, "device")
        if not os.path.exists(link):
            continue  # uinput: a virtual pad with no hardware behind it
        parent = os.path.realpath(link)
        if parent in pads:
            continue  # second joystick node of a pad already listed
        if not is_joystick(os.path.realpath(js)):
            continue
        pads[parent] = describe(inp, parent)
    json.dump(list(pads.values()), sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
