#!/usr/bin/env python3
"""
kiosk-server.py — dead simple file server + config write endpoint
Usage: python3 kiosk-server.py [port]
Default port: 8080
"""

import json
import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "config.json")


class KioskHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.dirname(__file__), **kwargs)

    def do_POST(self):
        if self.path == "/save-config":
            try:
                length = int(self.headers.get("Content-Length", 0))
                raw = self.rfile.read(length)
                data = json.loads(raw)
                # Basic sanity: must have a buttons key
                if "buttons" not in data:
                    raise ValueError("Missing buttons key")
                with open(CONFIG_FILE, "w") as f:
                    json.dump(data, f, indent=2)
                self._respond(200, b"ok")
            except Exception as e:
                self._respond(400, str(e).encode())
        else:
            self._respond(404, b"not found")

    def _respond(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        # Quiet by default — uncomment below to debug
        # print(f"  {self.address_string()} {fmt % args}")
        pass


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(("", port), KioskHandler)
    print(f"  Kiosk server running → http://localhost:{port}/kiosk.html")
    print(f"  Config file: {CONFIG_FILE}")
    print(f"  Ctrl+C to stop\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Stopped.")


if __name__ == "__main__":
    main()
