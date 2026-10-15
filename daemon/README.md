# Daemon

Early loopback process for the bar panel. It does not read agent transcripts.

## Run

From the repo root:

```bash
python3 daemon/server.py
```

Default bind is `127.0.0.1:18765`. `localhost` and `::1` are also accepted. Any other host is refused.

## Check

```bash
curl -sS http://127.0.0.1:18765/health
curl -sS http://127.0.0.1:18765/sessions
```

`GET /sessions` returns an empty list and `"ingest": "not_implemented"`. `POST` returns 501.

Install, the panel, and removal are in the [root README](../README.md).
