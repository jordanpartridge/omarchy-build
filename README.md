# Omarchy Build

See every AI coding thread on this computer and on machines you reach with Tailscale SSH. Send a message into a live session. Restore a chapter and retry.

This is not a usage meter. The stock Agents widget already shows subscription limits. Omarchy Build is the timeline: what a session is trying to do, what it did, what is next, what is blocked.

## Install

```bash
omarchy plugin add https://github.com/jordanpartridge/omarchy-build.git
omarchy plugin enable jordan.build
```

Plugins run as unsandboxed code inside `omarchy-shell`. Review the tree before enabling. The installer only clones files; it does not run helpers or sudo.

## Status (0.1.0)

The bar panel is a stub. The local daemon (session ingest, REST, Tailscale SSH, send, chapters) is specified in `specs/omarchy-build/spec.md` and is not shipping in this snapshot.

v1 target:

- Read existing session files (Claude Code, Codex, OpenCode, Amp, Grok Build, and friends) — do not invent a seventh transcript format
- One-click Tailscale: pick a peer and a unix user, `tailscale ssh user@host`
- `GET /sessions`, `GET /sessions/:id`, `GET /sessions/:id/timeline` on loopback
- Inject a message into a live session; restore a chapter to retry
- Open the session in Herdr on that machine

## Removing

```bash
omarchy plugin remove jordan.build
```

This snapshot writes no state, cache, credentials, units, or hooks. Nothing survives removal except this git checkout if you cloned it yourself outside Omarchy.

## License

MIT
