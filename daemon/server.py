#!/usr/bin/env python3
"""Early loopback status process for the Omarchy Build bar plugin.

GET /sessions returns an empty list. This process does not read agent
transcripts and does not keep a session store.
"""

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 18765
LOOPBACK_HOSTS = frozenset({"127.0.0.1", "localhost", "::1"})
VERSION = "0.1.3"


def loopback_host(host: str) -> bool:
    return host in LOOPBACK_HOSTS


class Handler(BaseHTTPRequestHandler):
    server_version = "omarchy-build/" + VERSION

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send_json(self, code: int, payload: object) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8") + b"\n"
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _route(self) -> tuple[str, list[str]]:
        parts = self.path.split("?", 1)[0].strip("/").split("/")
        if parts == [""]:
            return "", []
        return parts[0], parts[1:]

    def do_GET(self) -> None:  # noqa: N802
        base, rest = self._route()
        if base in ("health", "up") and not rest:
            self._send_json(
                200,
                {
                    "status": "up",
                    "service": "omarchy-build",
                    "bind": DEFAULT_HOST,
                    "ingest": "not_implemented",
                },
            )
            return
        if base == "sessions" and not rest:
            self._send_json(200, {"sessions": [], "ingest": "not_implemented"})
            return
        self._send_json(404, {"error": "not_found", "path": self.path})

    def do_POST(self) -> None:  # noqa: N802
        self._send_json(501, {"error": "not_implemented", "path": self.path})


def make_server(host: str, port: int) -> ThreadingHTTPServer:
    if not loopback_host(host):
        raise ValueError(host)
    return ThreadingHTTPServer((host, port), Handler)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Omarchy Build loopback status daemon. "
            "Does not read agent transcripts."
        )
    )
    parser.add_argument(
        "--host",
        default=DEFAULT_HOST,
        help="bind address (default 127.0.0.1)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help="bind port (default 18765)",
    )
    args = parser.parse_args(argv)

    if not loopback_host(args.host):
        print(
            "refusing non-loopback bind %r; use 127.0.0.1" % args.host,
            file=sys.stderr,
        )
        return 2

    httpd = make_server(args.host, args.port)
    host, port = httpd.server_address[:2]
    print(
        "omarchy-build daemon listening on http://%s:%s" % (host, port),
        flush=True,
    )
    print("  GET /health", flush=True)
    print("  GET /sessions", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nshutting down", flush=True)
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
