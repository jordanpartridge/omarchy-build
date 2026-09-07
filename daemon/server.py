#!/usr/bin/env python3
"""Omarchy Build user‑local daemon – demo control‑plane.

Implements the SPEC v1 REST endpoints in a lightweight in‑memory store.
All data is volatile – the daemon is intended for local demos only.
"""

from __future__ import annotations

import argparse
import json
import sys
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 18765

# ---------------------------------------------------------------------
# Global in‑memory state
# ---------------------------------------------------------------------
# Each session dict contains its base fields plus:
#   "chapters": List[dict] – snapshots of the session (excluding bookkeeping fields)
#   "current": int – index of the active snapshot in "chapters"
#   "messages": List[str] – injected messages for the demo
_sessions: dict[str, dict] = {
    "sess-pfc-today": {
        "id": "sess-pfc-today",
        "name": "PFC Today UX",
        "host": "thor",
        "user": "jordan",
        "harness": "grok",
        "state": "trying",
        "summary": "Collapse radar; simplify capture.",
        "messages": [],
        "chapters": [],
        "current": -1,
    },
    "sess-asgard-sessionend": {
        "id": "sess-asgard-sessionend",
        "name": "Asgard SessionEnd",
        "host": "odin",
        "user": "lexi",
        "harness": "grok",
        "state": "blocked",
        "summary": "Solo token stale — needs Jordan.",
        "messages": [],
        "chapters": [],
        "current": -1,
    },
    "sess-omarchy-build": {
        "id": "sess-omarchy-build",
        "name": "Omarchy Build daemon",
        "host": "thor",
        "user": "jordan",
        "harness": "grok",
        "state": "next",
        "summary": "cass ingest + loopback REST.",
        "messages": [],
        "chapters": [],
        "current": -1,
    },
}

# Simple global collections for the demo UI
_anomalies: list[str] = []
_lagging: list[str] = []

# ---------------------------------------------------------------------
# HTTP request handler
# ---------------------------------------------------------------------
class Handler(BaseHTTPRequestHandler):
    server_version = "omarchy-build-daemon/0.1"

    # -----------------------------------------------------------------
    # Logging / JSON helpers
    # -----------------------------------------------------------------
    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write(f"{self.address_string()} - {fmt % args}\n")

    def _send_json(self, code: int, payload) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8") + b"\n"
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        data = self.rfile.read(length)
        try:
            return json.loads(data)
        except json.JSONDecodeError:
            return {}

    def _parse_path(self):
        """Return (base, parts) where *base* is the first path component and *parts* is the list of the remaining components."""
        parts = self.path.split("?")[0].strip("/").split("/")
        if not parts or parts == [""]:
            return "", []
        return parts[0], parts[1:]

    # -----------------------------------------------------------------
    # Session management helpers (used by POST handlers)
    # -----------------------------------------------------------------
    def _save_chapter(self, sid: str) -> None:
        """Create a shallow snapshot of the session (excluding bookkeeping) and store it.
        The snapshot is appended to ``chapters`` and ``current`` points to it.
        """
        sess = _sessions[sid]
        snapshot = {k: v for k, v in sess.items() if k not in ("chapters", "current")}
        sess.setdefault("chapters", []).append(snapshot)
        sess["current"] = len(sess["chapters"]) - 1

    def _load_chapter(self, sid: str, idx: int) -> None:
        """Replace the session dict with the snapshot at *idx* (if valid)."""
        sess = _sessions[sid]
        chapters = sess.get("chapters", [])
        if not chapters or idx < 0 or idx >= len(chapters):
            return
        snapshot = chapters[idx]
        sess.update(snapshot)
        sess["current"] = idx

    def _detect_anomalies(self, sid: str) -> None:
        """Add any message that appears three or more times to the global ``_anomalies`` list."""
        msgs = _sessions[sid]["messages"]
        counts: dict[str, int] = {}
        for m in msgs:
            counts[m] = counts.get(m, 0) + 1
        for m, c in counts.items():
            if c >= 3 and m not in _anomalies:
                _anomalies.append(m)

    def _run_summarize(self, sid: str) -> str:
        """Create a very simple summary from the session's messages.
        The demo concatenates the messages (up to 200 chars) and stores it.
        """
        sess = _sessions[sid]
        txt = " ".join(sess["messages"]) or sess.get("summary", "")
        summary = f"Summarized: {txt[:200]}"
        sess["summary"] = summary
        return summary

    def _collect_lagging(self, sid: str) -> None:
        """Add any message not present in the current summary to the global ``_lagging`` list."""
        sess = _sessions[sid]
        for m in sess["messages"]:
            if m not in sess.get("summary", "") and m not in _lagging:
                _lagging.append(m)

    # -----------------------------------------------------------------
    # GET handlers
    # -----------------------------------------------------------------
    def do_GET(self) -> None:  # noqa: N802
        base, parts = self._parse_path()
        if base == "sessions" and not parts:
            self._send_json(200, {"sessions": list(_sessions.values())})
            return
        if base == "anomalies":
            self._send_json(200, {"anomalies": _anomalies})
            return
        if base == "lagging-ideas":
            self._send_json(200, {"ideas": _lagging})
            return
        if base in ("health", "up") and not parts:
            self._send_json(200, {"status": "up", "service": "omarchy-build", "bind": "127.0.0.1"})
            return
        self._send_json(404, {"error": "not_found", "path": self.path})

    # -----------------------------------------------------------------
    # POST handlers (create, send, summarize, rollback, rollforward)
    # -----------------------------------------------------------------
    def do_POST(self) -> None:  # noqa: N802
        base, parts = self._parse_path()
        # ----- spawn new session ------------------------------------------------
        if base == "sessions" and not parts:
            body = self._read_json()
            new_id = f"sess-{uuid.uuid4().hex[:8]}"
            session = {
                "id": new_id,
                "name": body.get("name", "Unnamed"),
                "host": body.get("host", "thor"),
                "user": body.get("user", "jordan"),
                "harness": body.get("harness", "grok"),
                "state": body.get("state", "next"),
                "summary": body.get("summary", ""),
                "messages": [],
                "chapters": [],
                "current": -1,
            }
            _sessions[new_id] = session
            # save initial chapter so rollback works immediately
            self._save_chapter(new_id)
            self._send_json(201, {"session": session})
            return
        # ----- inject a message ------------------------------------------------
        if base == "sessions" and len(parts) == 2 and parts[1] == "send":
            sid = parts[0]
            if sid not in _sessions:
                self._send_json(404, {"error": "session_not_found", "id": sid})
                return
            body = self._read_json()
            msg = body.get("message", "")
            _sessions[sid]["messages"].append(msg)
            # update anomaly and lagging collections
            self._detect_anomalies(sid)
            self._collect_lagging(sid)
            self._send_json(200, {"status": "sent", "id": sid, "message": msg})
            return
        # ----- summarize -------------------------------------------------------
        if base == "sessions" and len(parts) == 2 and parts[1] == "summarize":
            sid = parts[0]
            if sid not in _sessions:
                self._send_json(404, {"error": "session_not_found", "id": sid})
                return
            summary = self._run_summarize(sid)
            self._save_chapter(sid)  # store snapshot after summarising
            self._send_json(200, {"status": "summarized", "id": sid, "summary": summary})
            return
        # ----- rollback --------------------------------------------------------
        if base == "sessions" and len(parts) == 2 and parts[1] == "rollback":
            sid = parts[0]
            if sid not in _sessions:
                self._send_json(404, {"error": "session_not_found", "id": sid})
                return
            cur = _sessions[sid].get("current", 0)
            if cur > 0:
                self._load_chapter(sid, cur - 1)
                self._send_json(200, {"status": "rollback_ok", "id": sid, "chapter": _sessions[sid]["current"]})
            else:
                self._send_json(400, {"error": "cannot_rollback", "id": sid})
            return
        # ----- rollforward -----------------------------------------------------
        if base == "sessions" and len(parts) == 2 and parts[1] == "rollforward":
            sid = parts[0]
            if sid not in _sessions:
                self._send_json(404, {"error": "session_not_found", "id": sid})
                return
            sess = _sessions[sid]
            cur = sess.get("current", 0)
            chapters = sess.get("chapters", [])
            if cur < len(chapters) - 1:
                self._load_chapter(sid, cur + 1)
                self._send_json(200, {"status": "rollforward_ok", "id": sid, "chapter": _sessions[sid]["current"]})
            else:
                self._send_json(400, {"error": "cannot_rollforward", "id": sid})
            return
        # ----- unknown endpoint ------------------------------------------------
        self._send_json(404, {"error": "not_found", "path": self.path})

# ---------------------------------------------------------------------
# Server entry point
# ---------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(description="Omarchy Build demo daemon (loopback REST)")
    parser.add_argument("--host", default=DEFAULT_HOST, help="bind address (default 127.0.0.1)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="bind port (default 18765)")
    args = parser.parse_args()

    if args.host not in ("127.0.0.1", "localhost", "::1"):
        print(f"refusing non‑loopback bind {args.host!r}; use 127.0.0.1", file=sys.stderr)
        return 2

    httpd = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"omarchy-build daemon listening on http://{args.host}:{args.port}", flush=True)
    print("  GET /sessions             → list sessions", flush=True)
    print("  POST /sessions            → spawn new session", flush=True)
    print("  POST /sessions/:id/send   → inject message", flush=True)
    print("  POST /sessions/:id/summarize → produce summary", flush=True)
    print("  POST /sessions/:id/rollback → previous chapter", flush=True)
    print("  POST /sessions/:id/rollforward → next chapter", flush=True)
    print("  GET /anomalies            → detected anomalies", flush=True)
    print("  GET /lagging-ideas        → unfinished intents", flush=True)
    print("  GET /health               → service health", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nshutting down", flush=True)
    finally:
        httpd.server_close()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
