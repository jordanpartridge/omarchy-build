# SPEC: Omarchy Build — every AI thread, any host, send and retry from a chapter

Status: DRAFT

**Story:** The Agents icon shows usage. You still cannot keep track of every AI coding thread — this machine or SSH as a unix user — send into one, or bring a project back at a decision point and retry.

## Locked

- Product: **Omarchy Build**. Repo: `jordanpartridge/omarchy-build`. Plugin id: `jordan.build`. Catalog plugin = thin Quickshell panel. Work is a **user-local daemon** (timeline, REST, chapters).
- Ingest: do not write six parsers. Prefer cass (Claude, Codex, OpenCode, Amp, Grok Build, and others) plus Grok Build `updates.jsonl` / `summary.json`. Normalize toward OpenSession-shaped events.
- Hosts: **one-click Tailscale.** Peer from `tailscale status` (MagicDNS) and a unix user; **Tailscale SSH** (`tailscale ssh user@host`). No key form. If Tailscale SSH is off, fail closed with that named miss — no password prompt. Per unix user, not a root scrape of `/home`.
- Panel shows: trying / done / next / blocked. Tool calls reduce to what the agent actually did.
- **Send:** inject a message into a live session (harness resume/inject). Explicit click. Localhost API. No secrets in JSON.
- **Chapter:** a decision point. Compress/snapshot session + tree. Restore that chapter = retry. Native rewind if the harness has it; else a user-turn snapshot. Isolation = this product's own clones, not a worktree in the daily checkout.
- **Put up:** Herdr on that machine opens the session. Cancel kills the process. Rollback restores the chapter.
- Distill per seat (git repo) into better prompts is a later writer; v1 is timeline + send + chapter retry.
- Vector search of sessions is v1-optional. REST is required: `GET /sessions`, `GET /sessions/:id`, `GET /sessions/:id/timeline`, progress on the session resource. Loopback only.
- The stock Agents usage widget stays a usage meter. Do not grow it into this.
- Marketplace: follow Omarchy plugin security review. QML does not parse JSONL. Unsandboxed plugin must not be a remote control plane.

## Done when

- [ ] From this machine, one click Tailscale SSH as a named user on another peer, list a Grok Build session, send one line, restore chapter 3, open that pane in Herdr

## Out of scope

- Parsing every JSONL inside `omarchy-shell`
- A seventh transcript format
- Thor-only
- Stuffing this into the usage-meter plugin
