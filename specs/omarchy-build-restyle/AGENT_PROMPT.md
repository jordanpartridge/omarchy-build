Restyle `jordan.build` popout to match Omarchy Weather + Agents. Skin only. No new verbs.

Working tree Panel.qml is the LIVE 417-line panel (search, list, inject, seven actions, curl Process). Restyle that file. Do not revert it to the shorter origin stub.

Read first:
- specs/omarchy-build-restyle/spec.md
- /usr/share/omarchy/shell/plugins/agents/Panel.qml (tokens, PanelHero, Button bordered, fittedContentHeight)
- /usr/share/omarchy/shell/plugins/panels/weather/Panel.qml (IpcHandler + manageIpc: false, implicitHeight)
- /usr/share/omarchy/shell/Ui/Button.qml
- /usr/share/omarchy/shell/Ui/PanelHero.qml
- /usr/share/omarchy/shell/Ui/TextField.qml

## Do

1. Panel.qml chrome:
   - Add the four token properties from spec (foreground, dim, urgent, fontFamily).
   - Replace every `Color.foreground` text color with `root.foreground` / `root.dim` / `root.urgent`.
   - Replace every `Style.font.size` and every `font.pixelSize: … * 0.8` with `Style.font.body` or `Style.font.caption` or `Style.font.title`.
   - `textFormat: Text.PlainText` on every Text.
   - Add `PanelHero` (title Omarchy Build, meta LIVE/OFFLINE). Remove the old title+DEMO/LIVE Text row.
   - Delete the `Selected:` Text.
   - Session Flickable height: `Style.space(44) * 5` (not 220 magic if you can use that).
   - `contentHeight: panel.fittedContentHeight(bodyCol.implicitHeight, Style.space(640))`
   - Row MouseArea: `onClicked` sets `root.selected` only. Add `onDoubleClicked: root.doAction("recall")`.
   - Keep `onActivateRequested: root.doAction("recall")`.
   - State Text color via a `function stateColor(s)` as spec.
   - Action Buttons: `qs.Ui` Button, `bordered: true`, `foreground: root.foreground`, `fontFamily: root.fontFamily`. Same seven labels/ids.
   - Search + inject TextField: `foreground: root.foreground`.
   - `IpcHandler { target: root.ipcTarget; function open/close/show/hide/toggle }` matching weather. Keep `manageIpc: false`.

2. BarWidget.qml:
   - `button.active: root.opened`
   - Do not change the icon glyph.

3. Do not touch daemon/, do not change loadSessions/doAction/Process/curl.

4. Run `bash specs/omarchy-build-restyle/check.sh` until it passes.
5. Commit on `feat/restyle-popout`. Push. Open PR to master. ship.sh may also open it — that is fine.

## Do not

- Add verbs, daemon routes, XMLHttpRequest, Asgard, cass, sudo, AGENTS.md
- `font.pixelSize` expressions that are not an int Style token
- `Qt.darker(Color.foreground` (use `root.dim`)
- Recall on single click
- Rewrite fetch


## Stop rule

You are not done until `bash specs/omarchy-build-restyle/check.sh` prints `ok restyle checks` and exits 0.
After every edit, run it. If it prints FAIL, keep editing the same files. Do not stop after adding PanelHero.
Type is `PanelHero` (qs.Ui is already imported). Not `qs.Ui.PanelHero`.
Do not add a Refresh verb. loadSessions already runs on open.
