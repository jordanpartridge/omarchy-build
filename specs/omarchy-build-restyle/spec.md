# SPEC: Omarchy Build popout restyle (weather/agents kit)

Status: LOCKED (factory-buildable)
Repo: `jordanpartridge/omarchy-build` plugin `jordan.build`
Parent: Asgard#213 session control plane. This slice is **skin only**.

**The lie:** the bar popout is a grey ghost on the wallpaper. Weather next door is an opaque purple card with mint type and a pink edge. Build has the live session list and still looks like it did not open.

## Ownership

| Surface | Owner |
|---|---|
| `Panel.qml` / `BarWidget.qml` restyle | this slice |
| Daemon, ingest, send, chapters, Tailscale, PFC | **not this slice** |

## Locked

- Copy the **Omarchy kit** used by `/usr/share/omarchy/shell/plugins/agents/Panel.qml` and `panels/weather/Panel.qml`. Do not invent a palette.
- Tokens (required):
  - `readonly property color foreground: bar ? bar.foreground : Color.foreground`
  - `readonly property color dim: Qt.darker(foreground, 1.55)`
  - `readonly property color urgent: bar ? bar.urgent : Color.urgent`
  - `readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family`
- Every `Text` / `Label` / `TextEdit`: `textFormat: Text.PlainText`, `color: root.foreground` or `root.dim` or `root.urgent`, `font.family: root.fontFamily`.
- Font sizes: only `Style.font.body`, `Style.font.caption`, `Style.font.title`, `Style.font.display`, `Style.bar.iconFont`. **Never** `Style.font.size` (undefined → journal `Unable to assign [undefined] to int`). **Never** `font.pixelSize: … * 0.8` (double → int).
- `PanelHero` at the top: title `Omarchy Build`, meta `LIVE` or `OFFLINE`.
- `KeyboardPanel` height: `fittedContentHeight(column.implicitHeight, Style.space(640))` — not a fixed `Style.space(560)`.
- Session list is the product. Drop the duplicate `Selected:` line. Session viewport ~5 rows (`Style.space(44) * 5`), scroll inside. Actions stay below.
- Rows: click **selects**. Enter / double-click / existing Recall button runs `doAction("recall")`. Do not recall on single click.
- State color: `trying` → accent/foreground, `blocked` → `root.urgent`, `done`/`next` → `root.dim`.
- Actions: **the same seven ids** (`recall`, `summarize`, `spawn`, `rollback`, `rollforward`, `anomaly`, `lagging`). Use `qs.Ui` `Button` with `bordered: true` and `foreground: root.foreground`. No new verbs. Do not remove them.
- `TextField` (search + inject): `qs.Ui` TextField, `foreground: root.foreground`.
- IPC: keep `manageIpc: false`, add an `IpcHandler` on `jordan.build` with `open/close/show/hide/toggle` like weather.
- Bar: `button.active: root.opened`. Do not change the `{.}` glyph this slice.
- Do **not** rewrite `loadSessions`, `doAction`, `Process`, curl, daemon, or session JSON shape.

## Done when

- [ ] `omarchy plugin validate .` passes
- [ ] `specs/omarchy-build-restyle/check.sh` exits 0
- [ ] Click `{.}` on Thor: card is as readable as Weather (opaque surface, mint/theme foreground, visible border)
- [ ] `j`/`k` move, Enter recalls, `/` focuses search; single click only highlights
- [ ] Journal no longer spam `Unable to assign double to int` / `undefined to int` from this Panel
- [ ] PR to `jordanpartridge/omarchy-build` `master`

## Out of scope

- New daemon routes, cass, Tailscale SSH, chapters, spawn implementation, PFC Needs
- Changing fetch (`Process` / curl)
- Marketplace submission
- Rewriting `daemon/`
