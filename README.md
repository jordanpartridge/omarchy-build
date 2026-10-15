# Omarchy Build

Early Omarchy bar plugin. The bar panel shows the session list returned by a loopback daemon on this computer.

Version 0.1.3 does not read agent transcripts. It does not open a Tailscale SSH session, send a message into a live session, or restore a chapter. That behavior is described as later work in [specs/omarchy-build/spec.md](specs/omarchy-build/spec.md). It is not in this build.

The stock Agents widget remains the usage meter. This plugin does not replace it.

## Status

| | |
|---|---|
| Plugin | Bar widget `jordan.build`. A click opens a panel. |
| Daemon | `GET /health` and `GET /sessions` on `127.0.0.1:18765`. The session list is empty. |
| Ingest, Tailscale SSH, send, chapters | Not implemented. `POST` returns 501. |
| Screenshot | None. This panel has not been captured on a running Omarchy bar. |

## Requirements

- Omarchy, with shell plugins, for the bar widget.
- Python 3.9 or newer for the daemon. The standard library is enough. There are no pip packages.

Installing the plugin does not start the daemon. Start the daemon yourself when you want the panel to get a reply.

## Install

Omarchy clones this repo and leaves the plugin disabled until you enable it. Read the tree first. Plugins run as unsandboxed code inside `omarchy-shell`. The installer only clones files. It does not run helpers or sudo.

```bash
omarchy plugin add https://github.com/jordanpartridge/omarchy-build.git
omarchy plugin enable jordan.build
```

`omarchy plugin add` asks for confirmation before it clones. Pass `--yes` only when you mean to skip that prompt.

The checkout is placed at `~/.config/omarchy/plugins/jordan.build`. Enable places the widget on the right side of the bar.

To install by hand, clone this repo into that directory, then run:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable jordan.build
```

## Usage

Click **Build** on the bar. Escape closes the panel. You can also ask the shell to open it:

```bash
omarchy-shell shell summon jordan.build '{}'
```

The panel requests `http://127.0.0.1:18765/sessions`. Until the daemon is running, the panel says it is not reachable.

From a checkout of this repo:

```bash
python3 daemon/server.py
```

The process binds `127.0.0.1` by default. It also accepts `localhost` and `::1`, and it refuses any other host. Stop it with Ctrl-C. It writes no files, credentials, or units.

```bash
curl -sS http://127.0.0.1:18765/health
curl -sS http://127.0.0.1:18765/sessions
```

`GET /sessions` returns:

```json
{
  "sessions": [],
  "ingest": "not_implemented"
}
```

`POST` returns HTTP 501 and `{"error": "not_implemented"}`.

Move the widget with:

```bash
omarchy bar move jordan.build --section right
```

## Test

```bash
python3 -m unittest discover -s tests -v
```

## Remove

```bash
omarchy plugin remove jordan.build
```

This build writes no state, cache, credentials, units, or hooks. Removing the plugin deletes Omarchy's checkout of it. A clone you made yourself, outside that directory, stays where you put it.

## License

MIT. See [LICENSE](LICENSE).
