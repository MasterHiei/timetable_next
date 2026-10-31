"""Smoke-test the actual Release bundle through the installed ChromeDriver."""

import base64
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import sys
import threading
import time
import urllib.error
import urllib.request

import ci


DRIVER = "http://127.0.0.1:4444"
LOCAL = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def request(method, path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(DRIVER + path, data=data, method=method, headers={"Content-Type": "application/json"})
    with LOCAL.open(req, timeout=45) as response:
        return json.load(response)["value"]


def ready():
    deadline = time.monotonic() + 30
    while True:
        try:
            if request("GET", "/status")["ready"]:
                return
        except urllib.error.URLError:
            pass
        if time.monotonic() >= deadline:
            raise ValueError("ChromeDriver was not ready within 30 seconds")
        time.sleep(0.2)


class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        if not path.startswith("/timetable_next/"):
            return str(Path(self.directory) / "__not_found__")
        return super().translate_path(path[len("/timetable_next"):])

    def log_message(self, *_args):
        pass


def smoke(url):
    ready()
    chrome = {"args": ["--headless=new", "--no-sandbox", "--disable-dev-shm-usage", "--enable-unsafe-swiftshader", "--window-size=1280,900"]}
    if os.environ.get("CHROME_EXECUTABLE"):
        chrome["binary"] = os.environ["CHROME_EXECUTABLE"]
    session = request("POST", "/session", {"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": chrome, "goog:loggingPrefs": {"browser": "ALL"}}}})["sessionId"]
    prefix = "/session/" + session
    def execute(script):
        return request("POST", prefix + "/execute/sync", {"script": script, "args": []})
    query = """
        const roots = [document];
        for (let i = 0; i < roots.length; i++) {
          for (const node of roots[i].querySelectorAll('*')) {
            if (node.shadowRoot) roots.push(node.shadowRoot);
          }
        }
        const all = selector => roots.flatMap(root => [...root.querySelectorAll(selector)]);
        const placeholder = all('flt-semantics-placeholder')[0];
        if (placeholder) placeholder.click();
        """
    def wait_for(label):
        deadline = time.monotonic() + 45
        while True:
            element = execute(query + "return all('[role], button').find(node => (node.getAttribute('aria-label') || node.textContent).trim() === " + json.dumps(label) + ") || null;")
            if element:
                return element["element-6066-11e4-a52e-4f735466cecf"]
            if time.monotonic() >= deadline:
                raise ValueError("Release application did not show: " + label)
            time.sleep(0.2)

    try:
        request("POST", prefix + "/url", {"url": url})
        today = wait_for("Go to today")
        request("POST", prefix + "/element/" + today + "/click", {})
        theme = wait_for("Theme")
        request("POST", prefix + "/element/" + theme + "/click", {})
        wait_for("dark")
        errors = [entry for entry in request("POST", prefix + "/log", {"type": "browser"}) if entry["level"] == "SEVERE"]
        if errors:
            raise ValueError("Browser console errors: " + json.dumps(errors))
        print("Release controls, Theme menu interaction and resource loading passed")
    except Exception:
        destination = ci.ROOT / "build/diagnostics"
        destination.mkdir(parents=True, exist_ok=True)
        try:
            (destination / "web-failure.png").write_bytes(base64.b64decode(request("GET", prefix + "/screenshot")))
            (destination / "browser.json").write_text(json.dumps(request("POST", prefix + "/log", {"type": "browser"}), indent=2))
        except Exception as diagnostic_error:
            print("Could not capture browser diagnostics:", diagnostic_error, file=sys.stderr)
        raise
    finally:
        try:
            request("DELETE", prefix)
        except OSError as cleanup_error:
            print("Could not close browser session:", cleanup_error, file=sys.stderr)


def main():
    if sys.argv[1] == "driver-ready":
        ready()
    elif sys.argv[1] == "local":
        server = ThreadingHTTPServer(("127.0.0.1", 0), partial(Handler, directory=str(Path(sys.argv[2]).resolve())))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            smoke(f"http://127.0.0.1:{server.server_port}/timetable_next/")
        finally:
            server.shutdown()
            server.server_close()
    else:
        raise ValueError("Unknown smoke-test mode")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, urllib.error.URLError) as error:
        sys.exit(str(error))
