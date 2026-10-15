# Omarchy Build

Status: draft. The only shipped behavior is the bar widget and the loopback daemon described below. Everything under "Later" is not implemented.

## Shipped in 0.1.3

- Omarchy bar widget `jordan.build`. A click opens a panel.
- `daemon/server.py` listens on `127.0.0.1:18765` and refuses other hosts.
- `GET /health` and `GET /up` report that the process is up.
- `GET /sessions` returns `{"sessions": [], "ingest": "not_implemented"}`.
- There is no session store. `POST` returns 501.

## Later

A timeline of AI coding sessions that are already on the machine: what a session is trying to do, what it did, what is next, and what is blocked. This plugin stays separate from the stock Agents usage meter.

Not started:

- Read the session files existing tools already write (Claude Code, Codex, OpenCode, Amp, Grok Build, and similar). Do not invent another transcript format. The QML panel does not parse those files. A daemon would.
- `GET /sessions/:id` and `GET /sessions/:id/timeline` on loopback, with no secrets in the JSON.
- Tailscale SSH from `tailscale status`: pick a peer and a unix user, then `tailscale ssh user@host`. If Tailscale SSH is off, stop and say so. No password prompt.
- Inject a message only through that harness's own resume or inject path, and only after an explicit action. If that path does not exist, do nothing.
- Treat a chapter as a decision point. Restoring one would be how a retry works. Moving forward only applies when a later chapter exists.
- List local panes (title, class, pid, and cwd when the compositor exposes them) so a session can be tied to the pane it is running in.

## Out of scope

- Replacing the Agents usage meter.
- Parsing transcripts inside the QML panel.
- Binding the daemon to anything other than loopback.
- A new transcript format.
