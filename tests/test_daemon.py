import importlib.util
import json
import selectors
import subprocess
import sys
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_server():
    path = ROOT / "daemon" / "server.py"
    spec = importlib.util.spec_from_file_location("omarchy_build_server", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DaemonTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server_mod = load_server()
        cls.httpd = cls.server_mod.make_server("127.0.0.1", 0)
        cls.thread = threading.Thread(target=cls.httpd.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = "http://127.0.0.1:%s" % cls.httpd.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()
        cls.thread.join(timeout=5)

    def get(self, path):
        with urllib.request.urlopen(self.base + path, timeout=2) as resp:
            body = resp.read()
            return resp.status, resp.headers.get("Content-Type", ""), json.loads(body)

    def test_health(self):
        status, content_type, payload = self.get("/health")
        self.assertEqual(status, 200)
        self.assertIn("application/json", content_type)
        self.assertEqual(payload["status"], "up")
        self.assertEqual(payload["service"], "omarchy-build")
        self.assertEqual(payload["bind"], "127.0.0.1")
        self.assertEqual(payload["ingest"], "not_implemented")

    def test_up_alias(self):
        status, _, payload = self.get("/up")
        self.assertEqual(status, 200)
        self.assertEqual(payload["status"], "up")

    def test_sessions_are_empty(self):
        status, _, payload = self.get("/sessions")
        self.assertEqual(status, 200)
        self.assertEqual(payload, {"sessions": [], "ingest": "not_implemented"})

    def test_unknown_route_is_404(self):
        with self.assertRaises(urllib.error.HTTPError) as caught:
            urllib.request.urlopen(self.base + "/sessions/missing", timeout=2)
        self.assertEqual(caught.exception.code, 404)
        payload = json.loads(caught.exception.read())
        self.assertEqual(payload["error"], "not_found")

    def test_post_is_not_implemented(self):
        req = urllib.request.Request(
            self.base + "/sessions",
            data=b"{}",
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with self.assertRaises(urllib.error.HTTPError) as caught:
            urllib.request.urlopen(req, timeout=2)
        self.assertEqual(caught.exception.code, 501)
        payload = json.loads(caught.exception.read())
        self.assertEqual(payload["error"], "not_implemented")

    def test_loopback_guard(self):
        self.assertTrue(self.server_mod.loopback_host("127.0.0.1"))
        self.assertTrue(self.server_mod.loopback_host("localhost"))
        self.assertTrue(self.server_mod.loopback_host("::1"))
        self.assertFalse(self.server_mod.loopback_host("0.0.0.0"))
        with self.assertRaises(ValueError):
            self.server_mod.make_server("0.0.0.0", 0)

    def test_cli_refuses_public_bind(self):
        proc = subprocess.run(
            [
                sys.executable,
                str(ROOT / "daemon" / "server.py"),
                "--host",
                "0.0.0.0",
                "--port",
                "9",
            ],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        self.assertEqual(proc.returncode, 2)
        self.assertIn("127.0.0.1", proc.stderr)
        self.assertNotIn("listening", proc.stdout)

    def test_readme_command_serves_default_port(self):
        proc = subprocess.Popen(
            [sys.executable, str(ROOT / "daemon" / "server.py")],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        try:
            selector = selectors.DefaultSelector()
            selector.register(proc.stdout, selectors.EVENT_READ)
            events = selector.select(timeout=3)
            self.assertTrue(events, "daemon did not print a listen line")
            line = proc.stdout.readline()
            self.assertIn("http://127.0.0.1:18765", line)
            with urllib.request.urlopen(
                "http://127.0.0.1:18765/sessions", timeout=2
            ) as resp:
                payload = json.loads(resp.read())
            self.assertEqual(payload["sessions"], [])
            self.assertEqual(payload["ingest"], "not_implemented")
        finally:
            if proc.poll() is None:
                proc.terminate()
                proc.wait(timeout=5)
            if proc.stdout:
                proc.stdout.close()
