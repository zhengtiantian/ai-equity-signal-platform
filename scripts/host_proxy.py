#!/usr/bin/env python3
"""Minimal host-side HTTP/HTTPS forward proxy (stdlib only).

Purpose: give Docker Desktop a working egress path. The host can reach the
internet through the VPN TUN, but Docker's VM/containers cannot route the
VPN fake-ip addresses. This proxy runs as a normal host process (so its
connections go through the TUN like any host app) and relays CONNECT
tunnels + plain HTTP, letting Docker pull/build via the macOS system proxy.

Listens on 127.0.0.1:8890. Set it as the macOS web + secure web proxy.
"""

import select
import socket
import threading
from urllib.parse import urlparse

LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 8890
BUFSIZE = 65536
CONNECT_TIMEOUT = 30


def pipe(a: socket.socket, b: socket.socket) -> None:
    try:
        while True:
            r, _, _ = select.select([a, b], [], [], 120)
            if not r:
                break
            for s in r:
                data = s.recv(BUFSIZE)
                if not data:
                    return
                (b if s is a else a).sendall(data)
    except Exception:
        pass
    finally:
        for s in (a, b):
            try:
                s.close()
            except Exception:
                pass


def handle(client: socket.socket) -> None:
    upstream = None
    try:
        client.settimeout(CONNECT_TIMEOUT)
        req = b""
        while b"\r\n\r\n" not in req:
            chunk = client.recv(BUFSIZE)
            if not chunk:
                client.close()
                return
            req += chunk
        headers, _, rest = req.partition(b"\r\n\r\n")
        first = headers.split(b"\r\n")[0]
        parts = first.split(b" ")
        if len(parts) < 2:
            client.close()
            return
        method = parts[0].decode()
        target = parts[1].decode()

        if method.upper() == "CONNECT":
            host, _, port = target.partition(":")
            upstream = socket.create_connection((host, int(port or 443)), timeout=CONNECT_TIMEOUT)
            client.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
        else:
            u = urlparse(target)
            host = u.hostname
            port = u.port or 80
            path = u.path or "/"
            if u.query:
                path += "?" + u.query
            upstream = socket.create_connection((host, port), timeout=CONNECT_TIMEOUT)
            rest_headers = b"\r\n".join(headers.split(b"\r\n")[1:])
            new_req = f"{method} {path} HTTP/1.1".encode() + b"\r\n" + rest_headers + b"\r\n\r\n" + rest
            upstream.sendall(new_req)

        client.settimeout(None)
        upstream.settimeout(None)
        pipe(client, upstream)
    except Exception:
        for s in (client, upstream):
            try:
                if s:
                    s.close()
            except Exception:
                pass


def main() -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN_HOST, LISTEN_PORT))
    srv.listen(128)
    print(f"host proxy listening on {LISTEN_HOST}:{LISTEN_PORT}", flush=True)
    while True:
        c, _ = srv.accept()
        threading.Thread(target=handle, args=(c,), daemon=True).start()


if __name__ == "__main__":
    main()
