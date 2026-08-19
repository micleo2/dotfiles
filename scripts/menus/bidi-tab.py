#!/usr/bin/env python3
# Open a URL in a running Firefox via its WebDriver BiDi debug port:
# reuse an open tab for the same host:port if there is one (no new tab),
# otherwise create one. Stdlib only.
#
# usage: bidi-tab.py <port> <url>
# exit:  0 reused an existing tab, 1 opened a new tab, 2 error (caller falls back)
import socket, os, base64, struct, json, sys, signal
from urllib.parse import urlparse

class WS:
    def __init__(self, host, port, path="/session"):
        self.s = socket.create_connection((host, port), timeout=15)
        key = base64.b64encode(os.urandom(16)).decode()
        # NOTE: no Origin header on purpose. Firefox accepts absence but
        # rejects a non-matching one with 400.
        req = (f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\n"
               "Upgrade: websocket\r\nConnection: Upgrade\r\n"
               f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
        self.s.sendall(req.encode())
        buf = b""
        while b"\r\n\r\n" not in buf:
            buf += self.s.recv(4096)
        if b"101" not in buf.split(b"\r\n")[0]:
            raise RuntimeError(f"handshake failed: {buf[:200]!r}")
        self.buf = buf.split(b"\r\n\r\n", 1)[1]

    def _exact(self, n):
        while len(self.buf) < n:
            self.buf += self.s.recv(65536)
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def recv(self, timeout=15):
        self.s.settimeout(timeout)
        ln = self._exact(2)[1] & 0x7F
        if ln == 126:
            ln = struct.unpack(">H", self._exact(2))[0]
        elif ln == 127:
            ln = struct.unpack(">Q", self._exact(8))[0]
        return self._exact(ln).decode("utf-8", "replace")

    def send(self, obj):
        data = json.dumps(obj).encode()
        mask = os.urandom(4)
        hdr = bytearray([0x81])
        n = len(data)
        if n < 126:
            hdr.append(0x80 | n)
        elif n < 65536:
            hdr.append(0x80 | 126)
            hdr += struct.pack(">H", n)
        else:
            hdr.append(0x80 | 127)
            hdr += struct.pack(">Q", n)
        hdr += mask
        self.s.sendall(bytes(hdr) + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def rpc(self, method, params=None, mid=1, timeout=15):
        self.send({"jsonrpc": "2.0", "id": mid, "method": method, "params": params or {}})
        while True:
            msg = json.loads(self.recv(timeout))
            if msg.get("id") == mid:
                return msg

def hostport(url):
    p = urlparse(url)
    if p.scheme not in ("http", "https") or not p.hostname:
        return None
    return (p.hostname.lower(), p.port or (443 if p.scheme == "https" else 80))

def matches(tab_hp, target_hp):
    th, tp = tab_hp
    mh, mp = target_hp
    return tp == mp and (th == mh or th.endswith("." + mh) or mh.endswith("." + th))

def fail(msg, code=2):
    print(f"bidi-tab: {msg}", file=sys.stderr)
    sys.exit(code)

def main():
    # a SIGTERM (e.g. from `timeout`) must still run `finally` so the single
    # global BiDi session is released instead of leaked until firefox restart.
    def _term(sig, frame):
        raise SystemExit(2)
    signal.signal(signal.SIGTERM, _term)
    if len(sys.argv) != 3:
        fail("usage: bidi-tab.py <port> <url>")
    port, url = int(sys.argv[1]), sys.argv[2]
    target = hostport(url)
    if target is None:
        fail(f"unsupported url: {url}")

    try:
        ws = WS("127.0.0.1", port)
    except (OSError, RuntimeError) as e:
        fail(f"connect: {e}")

    have_session = False
    new_ctx = None
    try:
        msg = ws.rpc("session.new", {"capabilities": {}}, 1)
        if msg.get("type") == "error":
            if "Maximum number of active sessions" in msg.get("message", ""):
                fail("firefox has a leaked BiDi session (a previous run was killed "
                     "mid-session); restart firefox to clear it", 2)
            fail(f"session.new: {msg.get('message', msg)}", 2)
        have_session = True

        msg = ws.rpc("browsingContext.getTree", {}, 2)
        if msg.get("type") == "error":
            fail(f"getTree: {msg.get('message', msg)}", 2)
        tabs = msg["result"].get("contexts", [])

        for tab in tabs:
            hp = hostport(tab.get("url") or "")
            if hp and matches(hp, target):
                msg = ws.rpc("browsingContext.activate", {"context": tab["context"]}, 3)
                if msg.get("type") == "error":
                    fail(f"activate: {msg.get('message', msg)}", 2)
                print(f"bidi-tab: reused existing tab for {url}", file=sys.stderr)
                code = 0
                break
        else:
            # Fx 153 silently ignores create's `url` arg, and a bare create
            # (anchored to the "current" window) can hit
            # DiscardedBrowsingContextError; create blank anchored to a live
            # context, then navigate explicitly.
            params = {"type": "tab"}
            if tabs:
                params["context"] = tabs[0]["context"]
            msg = ws.rpc("browsingContext.create", params, 3)
            if msg.get("type") == "error":
                fail(f"create: {msg.get('message', msg)}", 2)
            new_ctx = msg["result"].get("context")
            if not new_ctx:
                fail("create: no context id in response", 2)
            msg = ws.rpc("browsingContext.navigate",
                         {"context": new_ctx, "url": url}, 4)
            if msg.get("type") == "error":
                try:
                    ws.rpc("browsingContext.close", {"context": new_ctx}, 5)
                except Exception:
                    pass
                fail(f"navigate: {msg.get('message', msg)}", 2)
            print(f"bidi-tab: opened new tab for {url}", file=sys.stderr)
            code = 1
    except (OSError, json.JSONDecodeError, KeyError, ValueError) as e:
        fail(f"protocol: {e}", 2)
    finally:
        if have_session:
            try:
                # release the (single) global session so the next run can create one
                ws.rpc("session.end", {}, 99, timeout=5)
            except Exception:
                pass
        ws.s.close()

    sys.exit(code)

main()