import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TEXT_SUFFIXES = {".md", ".py", ".qml", ".json", ".yml", ".yaml", ".txt"}


def text_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if ".git" in path.parts or "__pycache__" in path.parts:
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        yield path


class RepoTest(unittest.TestCase):
    def test_manifest_matches_the_plugin_contract(self):
        manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["schemaVersion"], 1)
        self.assertEqual(manifest["id"], "jordan.build")
        self.assertFalse(manifest["id"].startswith("omarchy."))
        self.assertNotIn("/", manifest["id"])
        self.assertNotIn("..", manifest["id"])
        self.assertEqual(manifest["version"], "0.1.3")
        self.assertEqual(manifest["kinds"], ["bar-widget"])
        entry = manifest["entryPoints"]["barWidget"]
        self.assertEqual(entry, "BarWidget.qml")
        self.assertTrue((ROOT / entry).is_file())
        self.assertIn(manifest["barWidget"]["defaultSection"], ("left", "center", "right"))
        self.assertIn("does not read agent transcripts", manifest["description"])

    def test_version_is_the_same_in_the_daemon(self):
        server = (ROOT / "daemon" / "server.py").read_text(encoding="utf-8")
        self.assertIn('VERSION = "0.1.3"', server)
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("0.1.3", readme)

    def test_readme_commands_exist(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        for heading in (
            "## Status",
            "## Requirements",
            "## Install",
            "## Usage",
            "## Test",
            "## License",
        ):
            self.assertIn(heading, readme)
        self.assertIn(
            "omarchy plugin add https://github.com/jordanpartridge/omarchy-build.git",
            readme,
        )
        self.assertIn("omarchy plugin enable jordan.build", readme)
        self.assertIn("omarchy plugin remove jordan.build", readme)
        self.assertIn("python3 daemon/server.py", readme)
        self.assertIn("python3 -m unittest discover -s tests -v", readme)
        self.assertIn("curl -sS http://127.0.0.1:18765/sessions", readme)
        self.assertIn("screenshot", readme.lower())
        self.assertIn("[LICENSE](LICENSE)", readme)
        self.assertTrue((ROOT / "LICENSE").is_file())

    def test_panel_asks_the_daemon_that_ships(self):
        panel = (ROOT / "Panel.qml").read_text(encoding="utf-8")
        widget = (ROOT / "BarWidget.qml").read_text(encoding="utf-8")
        self.assertIn("http://127.0.0.1:18765/sessions", panel)
        self.assertIn("function reload()", panel)
        self.assertIn("function toggle()", widget)
        self.assertIn(chr(0xF0626), widget)
        self.assertNotIn("demoSessions", panel)

    def test_public_copy_has_no_filler_or_em_dashes(self):
        banned = (
            "\u2014",
            "\u2013",
            "TO" + "DO",
            "FIX" + "ME",
            "lo" + "rem ipsum",
        )
        offenders = []
        for path in text_files():
            text = path.read_text(encoding="utf-8")
            for needle in banned:
                if needle in text:
                    offenders.append("%s contains %r" % (path.relative_to(ROOT), needle))
        self.assertEqual(offenders, [])
