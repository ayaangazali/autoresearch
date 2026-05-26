#!/usr/bin/env python3
"""Minimal hardened static server for the paper-hunt dashboard.

`python -m http.server --bind 0.0.0.0` serves the ENTIRE working directory with a
browsable index — over LAN/Tailscale that exposed ~/.paperhunt/logs/run.log (raw claude
output), run-hunt.sh, hunt-prompt.md and the runs/ backups to anyone on the network.

This server binds all interfaces (so the MacBook can still view over LAN/Tailscale) but
serves ONLY index.html and hunt.json. Everything else is 404. No directory listing.

Usage: python3 serve.py [port]   (default 8732)
"""
import http.server
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
ALLOWED = {"/": "index.html", "/index.html": "index.html", "/hunt.json": "hunt.json"}
TYPES = {
    "index.html": "text/html; charset=utf-8",
    "hunt.json": "application/json; charset=utf-8",
}


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "paperhunt/1.0"

    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]          # drop the ?t=… cache-buster
        fname = ALLOWED.get(path)
        if not fname:
            self._send(404, b"not found")
            return
        try:
            with open(os.path.join(ROOT, fname), "rb") as f:
                body = f.read()
        except OSError:
            self._send(404, b"not found")
            return
        self._send(200, body, TYPES.get(fname, "application/octet-stream"))

    do_HEAD = do_GET

    def log_message(self, *args):                  # stay quiet in server.log
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8732
    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"paperhunt dashboard on 0.0.0.0:{port} (serving only index.html + hunt.json)")
    httpd.serve_forever()
