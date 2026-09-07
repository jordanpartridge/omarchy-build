# SPEC: Omarchy Build — Jordan session control plane

Status: DRAFT (factory-buildable)

Parents: Omarchy shell plugins (`jordan.build`), cass / OpenSession ingest, house asks (GitHub issues), PFC Today, Asgard knowledge

**Story:** Jordan cannot keep every AI thread — this machine or Tailscale SSH as a unix user — recall one, send into it, spawn another, roll back a bad spiral, or catch a lagging idea before it dies. Omarchy Build is that control plane. Usage meters stay usage meters.

## Ownership

| Surface | Owner |
|---|---|
| Plugin + user-local daemon (sessions, timeline, send, chapters, summarize, spawn, anomaly) | **`jordan.build`** on Thor (repo `jordanpartridge/omarchy-build`) |
| Books / lasting facts distilled from sessions | **Asgard** |
| Needs-Jordan decisions / should-we-work-on-this | **PFC Today** (Need plates) — no Need spam; only when a human call is real |
| GitHub PRs for this repo | **Godbot** |

## Control plane (v1 locked)

1. **Recall + send/inject** — list live sessions; open timeline; inject a message into a running harness (explicit click / named API). Prefer each harness’s native resume/inject; fail closed if unavailable.
2. **Summarize** — **local models always summarizing** (bias locked). Continuous/cheap local summarize of trying/done/next/blocked. On-demand kick OK for a deeper pass. Cloud summarize is opt-in only, never default.
3. **Spawn** — start any supported session type on this host or via Tailscale SSH (`tailscale ssh user@host`) into an isolated clone (not a daily-checkout worktree).
4. **Rollback / rollforward** — chapter = decision point. Rollback restores chapter (native rewind if harness has it; else user-turn snapshot). Rollforward moves to a later chapter when one exists. Cancel kills the process.
5. **Anomaly detection** — detect drift / mistake spirals (repeated failing loops, thrash, runaway tool churn). When confidence is high, surface a **single** PFC Need (or update an existing anomaly Need) — never flood.
6. **Lagging ideas** — capture unfinished intents from sessions/notes that never became work. Route to a **should-we-work-on-this** PFC surface (one plate / digest), not a pile of Needs.

## Already locked (from prior draft — keep)

- Catalog plugin = thin Quickshell panel. Daemon owns timeline, REST, chapters, summarize, spawn, anomaly.
- Ingest: prefer **cass** (+ Grok `updates.jsonl` / `summary.json`). Normalize toward OpenSession-shaped events. **No seventh transcript format.** QML does not parse JSONL.
- Hosts: one-click Tailscale SSH from `tailscale status`. Tailscale SSH off → fail closed, named miss, no password prompt. Per unix user.
- Panel: trying / done / next / blocked. Tool calls reduce to what the agent actually did.
- REST (loopback only): `GET /sessions`, `GET /sessions/:id`, `GET /sessions/:id/timeline`, progress on the session resource. No secrets in JSON.
- Put up: Herdr opens the session on that machine.
- `omarchy.agents` / `jordan.agents` stay usage meters — do not grow them into this.
- Marketplace: Omarchy plugin security. Unsandboxed plugin must not be a remote control plane.
- Asks stay GitHub issues. Asgard is not the session store.

## Add REST (v1)

- `POST /sessions/:id/send` — inject (explicit)
- `POST /sessions` — spawn `{harness, host, user, repo|prompt}`
- `POST /sessions/:id/rollback` / `POST /sessions/:id/rollforward` — chapter move
- `POST /sessions/:id/summarize` — on-demand deeper local summarize (always-on summarize is daemon-side)
- `GET /anomalies` — current drift candidates (PFC consume; do not auto-open N Needs)
- `GET /lagging-ideas` — digest for PFC should-we surface

## Done when

- [ ] This SPEC is on `jordanpartridge/omarchy-build` `master` (Godbot PR if needed)
- [ ] Factory can build slices without re-asking ownership
- [ ] Candidate sit: from Thor, Tailscale SSH `lexi@odin`, list a session, send one line, local summarize shows, restore chapter 3, Herdr that pane; one fake anomaly routes to one PFC Need only

## Out of scope

- Parsing every JSONL inside `omarchy-shell`
- A seventh transcript format
- Thor-only (daemon is user-local; Thor is primary seat)
- Stuffing this into the usage-meter plugin
- Lexi PHP / Asgard as session DB
- Need spam / auto-filing every blip to PFC
- Night-ready until SPEC is on repo master and a build slice ships

## Open decisions

- Send: PTY inject vs harness-native stdin — prefer native
- Chapter tree: git commit in isolated clone vs tarball — prefer git
- Anomaly thresholds: tune after first week of local summaries; start fail-closed (high confidence only)
- Lagging-ideas → PFC: digest Need vs dedicated Today section — Prefrontal/Godbot pick when first slice ships

## Pane / workspace map (Jordan Homelab lock 2026-09-06)

Always know what is in **every Thor Hyprland workspace and pane** (title, class, pid, cwd if known, linked AI session id when detectable).

- **Consumer:** Omarchy Build — answer “what’s running where”, resume a session in a specific pane surgically.
- **Shape:** lightweight **portable** loopback service (Go / Rust / Python / TS — pick one at first slice). Not a Thor-only snowflake; later may sit in **Asgard’s army** of small host agents.
- **Inputs:** Hyprland (`hyprctl clients/workspaces`), terminal titles (`foot`/`org.omarchy.agent`), optional cass/session file correlation.
- **API (loopback):** e.g. `GET /panes`, `GET /workspaces`, `GET /sessions/by-pane/:id` — no secrets; fail closed off-host.
- **Out of scope v1:** remote control of other people’s machines without Tailscale SSH seat; parsing JSONL inside QML.

Done-when (slice): from Omarchy Build demo/API, list all Thor panes with workspace id + whether a grok/agent session is attached.
