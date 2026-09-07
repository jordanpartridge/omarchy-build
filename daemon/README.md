# Omarchy Build daemon (stub)

User-local loopback HTTP for the session control plane.

## Run

```bash
python3 daemon/server.py
# or: python3 daemon/server.py --port 18765
```

Binds **127.0.0.1 only** (refuses other hosts). Default port **18765**.

## Prove

```bash
curl -sS http://127.0.0.1:18765/sessions | python3 -m json.tool
curl -sS http://127.0.0.1:18765/health
```

## This slice

- `GET /sessions` — fixture JSON list (no secrets)
- `GET /health` / `GET /up` — liveness

Not yet: cass ingest, Tailscale SSH, send, chapters, `/sessions/:id`, timeline.
