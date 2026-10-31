"""Local and GitHub Actions checks; publishing itself stays in release.yml."""

import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "MasterHiei/timetable_next"
SEMVER = re.compile(
    r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)"
    r"(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?"
)


def run(*args, cwd=ROOT, timeout=None):
    return subprocess.check_output(args, cwd=cwd, text=True, timeout=timeout).strip()


def output(**values):
    for key, value in values.items():
        value = json.dumps(value, separators=(",", ":")) if not isinstance(value, str) else value
        if "\n" in value or "\r" in value:
            raise ValueError("Multiline workflow output")
        print(f"{key}={value}")
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as stream:
                stream.write(f"{key}={value}\n")


def read_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "timetable-next-ci"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def version(text):
    match = re.search(r"^version:\s*['\"]?([^'\"\s#]+)['\"]?\s*(?:#.*)?$", text, re.M)
    if not match or not SEMVER.fullmatch(match[1]):
        raise ValueError("Missing or invalid package SemVer")
    return match[1]


def compare_versions(left, right):
    a, b = SEMVER.fullmatch(left), SEMVER.fullmatch(right)
    if not a or not b:
        raise ValueError("Invalid SemVer")
    for i in (1, 2, 3):
        if int(a[i]) != int(b[i]):
            return 1 if int(a[i]) > int(b[i]) else -1
    if a[4] == b[4]:
        return 0
    if not a[4] or not b[4]:
        return 1 if not a[4] else -1
    aa, bb = a[4].split("."), b[4].split(".")
    for x, y in zip(aa, bb):
        if x == y:
            continue
        if x.isdigit() and y.isdigit():
            return 1 if int(x) > int(y) else -1
        if x.isdigit() != y.isdigit():
            return -1 if x.isdigit() else 1
        return 1 if x > y else -1
    return (len(aa) > len(bb)) - (len(aa) < len(bb))


def impact(paths):
    selected = dict.fromkeys(("package", "android", "ios", "web"), False)
    for path in paths:
        if path.startswith(("lib/", ".github/workflows/", "tool/")) or path in (
            "pubspec.yaml", "analysis_options.yaml", "example/pubspec.yaml",
            "example/pubspec.lock", "example/analysis_options.yaml", ".gitignore", ".pubignore",
        ):
            return dict.fromkeys(selected, True)
        if path.startswith(("example/lib/", "example/integration_test/", "example/test_driver/")):
            selected.update(android=True, ios=True, web=True)
            continue
        platform = next((p for p in ("android", "ios", "web") if path.startswith(f"example/{p}/")), None)
        if platform:
            selected[platform] = True
        elif not (path.startswith("test/") or path.endswith(".md") or
                  (path.startswith("doc/") and path.endswith((".png", ".webp", ".jpg")))):
            return dict.fromkeys(selected, True)
    return selected


def require_jobs(results, required):
    for name, expected in required.items():
        result = results.get(name, {}).get("result")
        if result != "success" and not (not expected and result == "skipped"):
            raise ValueError(f"Required check {name}: {result or 'missing'}")


def coverage(report, root=ROOT, threshold=95):
    records = {}
    current = None
    active = False
    source_lines = 0
    for line in Path(report).read_text().splitlines():
        if line.startswith("SF:"):
            if active:
                raise ValueError("Unterminated LCOV record")
            path = Path(line[3:])
            path = (root / path).resolve() if not path.is_absolute() else path.resolve()
            try:
                current = path.relative_to((root / "lib").resolve()).as_posix()
            except ValueError:
                current = None
            active = True
            if current:
                if not path.is_file():
                    raise ValueError(f"LCOV source does not exist: {current}")
                source_lines = len(path.read_text().splitlines())
                records.setdefault(current, {})
        elif line.startswith("DA:"):
            if not active:
                raise ValueError("LCOV line outside a source record")
            fields = line[3:].split(",")
            number, hits = int(fields[0]), int(fields[1])
            if number < 1 or hits < 0:
                raise ValueError("Invalid LCOV line or hit count")
            if current:
                if number > source_lines:
                    raise ValueError(f"LCOV line exceeds source length: {current}:{number}")
                records[current][number] = records[current].get(number, 0) + hits
        elif line == "end_of_record":
            if not active:
                raise ValueError("LCOV terminator outside a source record")
            active, current = False, None
    if active:
        raise ValueError("Unterminated LCOV record")
    for path in (root / "lib").rglob("*.dart"):
        name = path.relative_to(root / "lib").as_posix()
        if not records.get(name):
            text = re.sub(r"/\*.*?\*/|//[^\n]*", "", path.read_text(), flags=re.S)
            text = re.sub(r"\b(?:library|import|export|part)\b[^;]*;", "", text)
            if text.strip():
                raise ValueError(f"Production module missing from LCOV: {name}")
    total = sum(len(lines) for lines in records.values())
    hit = sum(sum(count > 0 for count in lines.values()) for lines in records.values())
    if not total:
        raise ValueError("No executable production lines in LCOV")
    print(f"Production line coverage: {hit}/{total} ({100 * hit / total:.4f}%)")
    if hit * 100 < total * threshold:
        raise ValueError(f"Production line coverage is below {threshold}%")
    return {"hit": hit, "total": total, "threshold": threshold}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def archive_files(data, *, mode="r:gz", required=("pubspec.yaml", "LICENSE", "README.md", "CHANGELOG.md", "lib/timetable.dart", "lib/timetable_next.dart")):
    files = {}
    with tarfile.open(fileobj=io.BytesIO(data), mode=mode) as archive:
        for member in archive:
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts or member.issym() or member.islnk():
                raise ValueError(f"Unsafe archive entry: {member.name}")
            if member.isdir():
                continue
            if not member.isfile() or path.as_posix() in files:
                raise ValueError(f"Invalid or duplicate archive entry: {member.name}")
            files[path.as_posix()] = archive.extractfile(member).read()
    for name in required:
        if name not in files:
            raise ValueError(f"Required archive file missing: {name}")
    return files


def manifest(archive, revision):
    data = Path(archive).read_bytes()
    files = archive_files(data)
    return {"revision": revision, "version": version(files["pubspec.yaml"].decode()),
            "sha256": digest(data)}


def verify_archive(archive, metadata, revision):
    expected = json.loads(Path(metadata).read_text())
    actual = manifest(archive, revision)
    if actual != expected:
        raise ValueError("Candidate archive, revision or manifest mismatch")
    if "CANDIDATE_SHA256" in os.environ and actual["sha256"] != os.environ["CANDIDATE_SHA256"]:
        raise ValueError("Candidate differs from the archive verified by this run")
    return actual


def release_notes(text, package_version):
    match = re.search(r"^##\s+" + re.escape(package_version) + r"(?:\s[^\n]*)?\n(.*?)(?=^##\s|\Z)", text, re.M | re.S)
    if not match or not match[1].strip():
        raise ValueError("Missing release notes")
    return match[1].strip() + f"\n\n[pub.dev](https://pub.dev/packages/timetable_next/versions/{package_version}) · [Demo](https://masterhiei.github.io/timetable_next/)\n"


def release_rehearsal(archive, metadata, pages, destination, revision):
    candidate = verify_archive(archive, metadata, revision)
    web = archive_files(Path(pages).read_bytes(), mode="r:", required=("release.json", "index.html", "flutter_bootstrap.js", "main.dart.js"))
    if json.loads(web["release.json"]) != {"version": candidate["version"], "revision": revision}:
        raise ValueError("Pages version or revision differs from the candidate")
    if not re.search(r"<base\s+href=[\"']/timetable_next/[\"']\s*/?>", web["index.html"].decode()):
        raise ValueError("Pages base href must be /timetable_next/")
    destination = Path(destination)
    for name, content in web.items():
        path = destination / "web" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    print("Release rehearsal inputs verified:", json.dumps(candidate))


def release_guard(tag, revision, root=ROOT):
    package_version = version((root / "pubspec.yaml").read_text())
    if tag != f"v{package_version}":
        raise ValueError("Tag must equal v<pubspec.version>")
    if not re.search(r"^##\s+" + re.escape(package_version) + r"(?:\s|$)", (root / "CHANGELOG.md").read_text(), re.M):
        raise ValueError("Version is missing from CHANGELOG")
    if run("git", "rev-parse", f"refs/tags/{tag}^{{commit}}", cwd=root) != revision:
        raise ValueError("Tag commit differs from workflow revision")
    subprocess.run(["git", "merge-base", "--is-ancestor", revision, "origin/main"], cwd=root, check=True)
    return package_version


def remote_archive(archive, package_version):
    url = f"https://pub.dev/api/packages/timetable_next/versions/{package_version}"
    try:
        published = read_json(url)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            error.close()
            return None
        raise
    with urllib.request.urlopen(published["archive_url"], timeout=30) as response:
        remote = archive_files(response.read())
    # Re-created gzip headers may differ; existing publication must have identical files.
    if remote != archive_files(Path(archive).read_bytes()):
        raise ValueError("Published version exists with different package contents")
    return published


def pages_needed(current, candidate):
    if not current:
        return True
    order = compare_versions(candidate["version"], current["version"])
    if order == 0 and current["revision"] != candidate["revision"]:
        raise ValueError("Demo version already belongs to another commit")
    return order >= 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("impact", "gate", "coverage", "manifest", "verify-archive", "consumer", "release-guard", "remote-check", "wait-published", "stamp-web", "pages-needed", "check-deployed", "release-notes", "release-rehearsal"))
    parser.add_argument("args", nargs="*")
    options = parser.parse_args()
    args = options.args
    command = options.command
    revision = os.environ.get("GITHUB_SHA") or run("git", "rev-parse", "HEAD")
    if command == "impact":
        if os.environ.get("FULL") == "true":
            selected = impact(["lib/"])
        else:
            base = args[0]
            if not re.fullmatch(r"[0-9a-f]{40}", base):
                raise ValueError("Invalid PR base revision")
            paths = run("git", "diff", "--name-only", "--no-renames", base, revision).splitlines()
            selected = impact(paths)
        platforms = [dict(platform=p, runner="macos-26" if p == "ios" else "ubuntu-24.04")
                     for p in ("android", "ios", "web") if selected[p]]
        output(package=selected["package"], platforms=platforms)
    elif command == "gate":
        require_jobs(json.loads(os.environ["CHECK_RESULTS"]), json.loads(os.environ["REQUIRED_JOBS"]))
    elif command == "coverage":
        coverage(args[0])
    elif command == "manifest":
        metadata = manifest(args[0], revision)
        Path(args[1]).write_text(json.dumps(metadata, indent=2) + "\n")
        output(sha256=metadata["sha256"], version=metadata["version"])
    elif command == "verify-archive":
        verify_archive(args[0], args[1], revision)
    elif command == "release-rehearsal":
        release_rehearsal(*args, revision)
    elif command == "consumer":
        verify_archive(args[0], args[1], revision)
        with tempfile.TemporaryDirectory(prefix="timetable-consumer-") as temporary:
            directory = Path(temporary)
            package = directory / "package"
            with tarfile.open(args[0], "r:gz") as archive:
                archive.extractall(package, filter="data")
            consumer = directory / "consumer"
            (consumer / "test").mkdir(parents=True)
            (consumer / "pubspec.yaml").write_text('name: timetable_consumer\npublish_to: none\nenvironment:\n  sdk: ">=3.10.0 <4.0.0"\ndependencies:\n  flutter:\n    sdk: flutter\n  dart_date: ^1.5.3\n  timetable_next:\n    path: ../package\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n')
            (consumer / "test/consumer_test.dart").write_bytes((ROOT / "tool/consumer_test.dart").read_bytes())
            for cmd in (("flutter", "pub", "get"), ("flutter", "analyze", "--fatal-infos"), ("flutter", "test", "--no-pub")):
                subprocess.run(cmd, cwd=consumer, check=True)
    elif command == "release-guard":
        if os.environ.get("GITHUB_REPOSITORY") != REPOSITORY:
            raise ValueError("Release is only allowed from the canonical repository")
        output(version=release_guard(os.environ["GITHUB_REF_NAME"], revision))
    elif command in ("remote-check", "wait-published"):
        metadata = verify_archive(args[0], args[1], revision)
        if command == "remote-check":
            try:
                read_json("https://pub.dev/api/packages/timetable_next")
            except urllib.error.HTTPError as error:
                if error.code == 404:
                    raise ValueError("First publication must be performed manually using the verified candidate") from error
                raise
            output(exists=remote_archive(args[0], metadata["version"]) is not None)
        else:
            deadline = time.monotonic() + 120
            while remote_archive(args[0], metadata["version"]) is None:
                if time.monotonic() >= deadline:
                    raise ValueError("Published version did not become visible within 120 seconds")
                time.sleep(5)
    elif command == "stamp-web":
        data = {"revision": revision, "version": version((ROOT / "pubspec.yaml").read_text())}
        (Path(args[0]) / "release.json").write_text(json.dumps(data) + "\n")
    elif command == "pages-needed":
        try:
            current = read_json("https://masterhiei.github.io/timetable_next/release.json")
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            current = None
        output(deploy=pages_needed(current, {"version": version((ROOT / "pubspec.yaml").read_text()), "revision": revision}))
    elif command == "check-deployed":
        url = args[0]
        expected = {"revision": revision, "version": version((ROOT / "pubspec.yaml").read_text())}
        deadline = time.monotonic() + 120
        while True:
            try:
                current = read_json(url + "release.json?revision=" + revision)
            except urllib.error.HTTPError as error:
                if error.code != 404:
                    raise
                error.close()
                current = None
            if current == expected:
                break
            if time.monotonic() >= deadline:
                raise ValueError("Deployed Demo does not match the published revision")
            time.sleep(5)
        with urllib.request.urlopen(url, timeout=30) as response:
            print(f"Demo accessible: HTTP {response.status}; {expected}")
    elif command == "release-notes":
        if len(args) > 1:
            package = archive_files(Path(args[1]).read_bytes())
            text = package["CHANGELOG.md"].decode()
            package_version = version(package["pubspec.yaml"].decode())
        else:
            text = (ROOT / "CHANGELOG.md").read_text()
            package_version = version((ROOT / "pubspec.yaml").read_text())
        Path(args[0]).write_text(release_notes(text, package_version))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, tarfile.TarError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
