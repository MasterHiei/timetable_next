"""Run the example interaction tests on an available iPhone in the CI runner."""

import json
import re
import subprocess
import sys


def select_device(devices):
    for runtime in sorted(devices, key=lambda key: tuple(map(int, re.findall(r"\d+", key))), reverse=True):
        if ".iOS-" not in runtime:
            continue
        phones = sorted((d for d in devices[runtime] if d["name"].startswith("iPhone") and d.get("isAvailable")), key=lambda d: d["name"])
        if phones:
            return runtime, phones[0]
    raise ValueError("No available iPhone simulator in the CI runner")


def main():
    data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], timeout=30))
    runtime, device = select_device(data["devices"])
    identifier = device["udid"]
    owned = device["state"] != "Booted"
    print(f"Selected {runtime} / {device['name']}: {identifier}", flush=True)
    try:
        if owned:
            subprocess.run(["xcrun", "simctl", "boot", identifier], check=True, timeout=60)
        subprocess.run(["xcrun", "simctl", "bootstatus", identifier, "-b"], check=True, timeout=300)
        subprocess.run(["flutter", "test", "integration_test/app_test.dart", "-d", identifier], cwd="example", check=True, timeout=1200)
    finally:
        if owned:
            subprocess.run(["xcrun", "simctl", "shutdown", identifier], timeout=30, check=False)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        sys.exit(str(error))
