"""Run the example interaction tests on an available iPhone in the CI runner."""

import json
import os
import re
import signal
import subprocess
import sys
import threading
import time

import ci


def redact(text):
    text = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text)
    text = re.sub(r"\b(?:https?|wss?)://[^\s<>\"']+", "[redacted URL]", text)
    return re.sub(r"(?i)((?:[\w-]*(?:token|password|secret|auth[_-]?code)|authorization)[\"']?\s*[:=]\s*)(?:\"[^\"]*\"|'[^']*'|(?:(?:Bearer|Basic)\s+)?[^\s,;]+)", r"\1[redacted]", text)


def report(message):
    print(redact(message), flush=True)


def capture_diagnostics(identifier, process):
    destination = ci.ROOT / "build/diagnostics/ios"
    destination.mkdir(parents=True, exist_ok=True)
    commands = [
        ["ps", "-axo", "pid=,ppid=,pgid=,etime=,state=,comm="],
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        ["xcrun", "simctl", "spawn", identifier, "launchctl", "list"],
    ]
    deadline = time.monotonic() + 30
    with (destination / "failure.log").open("w") as output:
        for command in commands:
            try:
                result = subprocess.run(command, capture_output=True, text=True, check=True, timeout=min(10, max(0, deadline - time.monotonic())))
                if command[0] == "ps":
                    content = "\n".join(line for line in result.stdout.splitlines() if process is not None and len(line.split()) >= 3 and line.split()[2] == str(process.pid))
                elif "devices" in command:
                    content = json.dumps([device for devices in json.loads(result.stdout)["devices"].values() for device in devices if device["udid"] == identifier])
                else:
                    content = "\n".join(line for line in result.stdout.splitlines() if "dev.liu.timetablenext.example" in line)
                output.write(redact(f"$ {' '.join(command)}\n{content or '(no matching process)'}\n"))
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                message = f"Could not capture iOS diagnostics: {error}"
                report(message)
                output.write(redact(message) + "\n")


def stop_process(process, reader):
    deadline = time.monotonic() + 15
    for sig, wait in ((signal.SIGTERM, 10), (signal.SIGKILL, 5)):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=min(wait, max(0, deadline - time.monotonic())))
        except subprocess.TimeoutExpired:
            pass
    if reader is not None:
        reader.join(timeout=max(0, deadline - time.monotonic()))
        if reader.is_alive():
            report("Could not finish reading iOS test output within the cleanup budget")


def stream_output(process, output, errors):
    try:
        with process.stdout:
            for line in process.stdout:
                line = redact(line)
                print(line, end="", flush=True)
                output.write(line)
                output.flush()
    except Exception as error:
        errors.append(error)


def select_device(devices):
    for runtime in sorted(devices, key=lambda key: tuple(map(int, re.findall(r"\d+", key))), reverse=True):
        if ".iOS-" not in runtime:
            continue
        phones = sorted((d for d in devices[runtime] if d["name"].startswith("iPhone") and d.get("isAvailable")), key=lambda d: d["name"])
        if phones:
            return runtime, phones[0]
    raise ValueError("No available iPhone simulator in the CI runner")


def main():
    started = time.monotonic()
    report("[iOS] Selecting simulator")
    data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], timeout=30))
    runtime, device = select_device(data["devices"])
    identifier = device["udid"]
    owned = device["state"] != "Booted"
    report(f"Selected {runtime} / {device['name']}: {identifier}")
    destination = ci.ROOT / "build/diagnostics/ios"
    destination.mkdir(parents=True, exist_ok=True)
    process = reader = None
    errors = []
    with (destination / "flutter-test.log").open("w") as output:
        try:
            report("[iOS] Waiting for simulator startup")
            if owned:
                subprocess.run(["xcrun", "simctl", "boot", identifier], check=True, timeout=60)
            subprocess.run(["xcrun", "simctl", "bootstatus", identifier, "-b"], check=True, timeout=300)
            report(f"[iOS] Simulator ready after {time.monotonic() - started:.1f}s; starting Flutter test (1200s limit)")
            command = ["flutter", "test", "integration_test/app_test.dart", "-d", identifier, "--verbose"]
            process = subprocess.Popen(command, cwd=ci.ROOT / "example", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace", start_new_session=True)
            reader = threading.Thread(target=stream_output, args=(process, output, errors), daemon=True)
            reader.start()
            result = process.wait(timeout=1200)
            if result:
                raise subprocess.CalledProcessError(result, command)
            reader.join(timeout=5)
            if reader.is_alive():
                raise OSError("Flutter exited but its output stream did not close")
            if errors:
                raise errors[0]
            report(f"[iOS] Flutter test passed after {time.monotonic() - started:.1f}s total")
        except Exception:
            report(f"[iOS] Failed after {time.monotonic() - started:.1f}s; capturing state before cleanup")
            try:
                capture_diagnostics(identifier, process)
            except Exception as error:
                report(f"Could not capture iOS diagnostics: {error}")
            if process is not None:
                try:
                    stop_process(process, reader)
                except Exception as error:
                    report(f"Could not stop iOS test process group: {error}")
            raise
        finally:
            report("[iOS] Cleaning up")
            if owned:
                try:
                    subprocess.run(["xcrun", "simctl", "shutdown", identifier], timeout=30, check=True)
                except (OSError, subprocess.SubprocessError) as error:
                    report(f"Could not shut down simulator: {error}")
            report(f"[iOS] Finished after {time.monotonic() - started:.1f}s")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        sys.exit(redact(str(error)))
