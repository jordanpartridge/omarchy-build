#!/usr/bin/env python3
"""Omarchy Build user-local daemon — loopback GET /sessions stub.

Binds 127.0.0.1 only. No secrets in JSON. Fixture list unlocks panel/API
wiring before Tailscale/send/chapters land.
"""

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 18765

# Fixture sessions — shape matches the Quickshell demo panel (no secrets).
FIXTURE_SESSIONS = [
    {
        "id": "sess-pfc-today",
        "name": "PFC Today UX",
        "host": "thor",
        "user": "jordan",
        "harness": "grok",
        "state": "trying",
        "summary": "Collapse radar; simplify capture.",
    },
    {
        "id": "sess-asgard-sessionend",
        "name": "Asgard SessionEnd",
        "host": "odin",
        "user": "lexi",
        "harness": "grok",
        "state": "blocked",
        "summary": "Solo token stale — needs Jordan.",
    },
    {
        "id": "sess-omarchy-build",
        "name": "Omarchy Build daemon",
        "host": "thor",
        "user": "jordan",
        "harness": "grok",
        "state": "next",
        "summary": "cass ingest + loopback REST.",
    },
]


class Handler(BaseHTTPRequestHandler):
    server_version = "omarchy-build-daemon/0.1"

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _json(self, code: int, payload) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8") + b"\n"
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        if path in ("/sessions", "/sessions/"):
            self._json(200, {"sessions": FIXTURE_SESSIONS})
            return
        if path in ("/health", "/up", "/"):
            self._json(200, {"status": "up", "service": "omarchy-build", "bind": "127.0.0.1"})
            return
        self._json(404, {"error": "not_found", "path": path})


def main() -> int:
    parser = argparse.ArgumentParser(description="Omarchy Build loopback daemon (sessions stub)")
    parser.add_argument("--host", default=DEFAULT_HOST, help="bind address (default 127.0.0.1)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="bind port (default 18765)")
    args = parser.parse_args()

    if args.host not in ("127.0.0.1", "localhost", "::1"):
        print(
            f"refusing non-loopback bind {args.host!r}; use 127.0.0.1",
            file=sys.stderr,
        )
        return 2

    httpd = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"omarchy-build daemon listening on http://{args.host}:{args.port}", flush=True)
    print("  GET /sessions  → fixture session list (JSON)", flush=True)
    print("  GET /health    → {status: up}", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nshutting down", flush=True)
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
