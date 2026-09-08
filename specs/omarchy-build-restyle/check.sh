#!/usr/bin/env bash
# Restyle gates. Fail closed.
set -euo pipefail
cd "$(dirname "$0")/../.."

omarchy plugin validate .

python3 - <<'PY'
import re, pathlib, sys
root = pathlib.Path(".")
fails = []

def lines(p):
    return p.read_text(encoding="utf-8", errors="replace")

panel = lines(pathlib.Path("Panel.qml"))
bar = lines(pathlib.Path("BarWidget.qml"))

if "PanelHero" not in panel:
    fails.append("Panel.qml missing PanelHero")
if "IpcHandler" not in panel:
    fails.append("Panel.qml missing IpcHandler")
if "bar ? bar.foreground" not in panel and "bar.foreground" not in panel:
    fails.append("Panel.qml missing bar.foreground token")
if "button.active" not in bar and "active: root.opened" not in bar:
    fails.append("BarWidget.qml missing button.active: root.opened")
if "Selected:" in panel:
    fails.append("Panel.qml still has Selected: duplicate line")
if "Style.font.size" in panel:
    fails.append("Panel.qml still uses Style.font.size")
if re.search(r"font\.pixelSize:\s*[^;\n]*\*", panel):
    fails.append("Panel.qml has font.pixelSize expression (must be int token)")
if "Qt.darker(Color.foreground" in panel:
    fails.append("Panel.qml uses Qt.darker(Color.foreground")
if re.search(r"onClicked:[\s\S]{0,500}doAction\(\s*[\"']recall[\"']", panel):
    fails.append("single click still recalls")

# every Text { block should contain textFormat: (best-effort, not a full parser)
text_opens = list(re.finditer(r"\b(Text|Label|TextEdit)\s*\{", panel))
missing_fmt = 0
for m in text_opens:
    i, depth = m.end(), 1
    src = panel
    while i < len(src) and depth:
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
        i += 1
    block = src[m.end() : i]
    if "textFormat:" not in block:
        missing_fmt += 1
        lineno = src[: m.start()].count("\n") + 1
        fails.append(f"MISSING textFormat Panel.qml:{lineno}")
if missing_fmt:
    fails.append(f"{missing_fmt} Text sinks missing textFormat")

for token in ("recall", "summarize", "spawn", "rollback", "rollforward", "anomaly", "lagging"):
    if token not in panel:
        fails.append(f"missing action id {token}")

if fails:
    print("FAIL")
    for f in fails:
        print(" -", f)
    sys.exit(1)
print("ok restyle checks")
PY
