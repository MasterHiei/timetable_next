import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock
import urllib.error

import ci
import ios_test
import web_smoke


class ChecksTest(unittest.TestCase):
    def test_browser_cleanup_does_not_replace_the_application_failure(self):
        def driver(method, path, payload=None):
            if path == "/status":
                return {"ready": True}
            if path == "/session":
                return {"sessionId": "fixture"}
            if path.endswith("/url"):
                return None
            if path.endswith("/execute/sync"):
                raise ValueError("Application failed to render")
            raise OSError("Browser disconnected")
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(web_smoke, "request", side_effect=driver), mock.patch.object(web_smoke.sys, "stderr", io.StringIO()):
            with self.assertRaisesRegex(ValueError, "Application failed to render"):
                web_smoke.smoke("https://example.invalid/")

    def test_impact_selects_only_checks_affected_by_the_change(self):
        none = dict.fromkeys(("package", "android", "ios", "web"), False)
        cases = [
            (["README.md", "test/event_test.dart"], none),
            (["example/ios/Runner/Info.plist"], {**none, "ios": True}),
            (["example/android/settings.gradle", "example/web/index.html"], {**none, "android": True, "web": True}),
            (["example/lib/qa_fixture.dart"], {**none, "android": True, "ios": True, "web": True}),
        ]
        for paths, expected in cases:
            self.assertEqual(ci.impact(paths), expected)
        for paths in (["lib/removed.dart"], ["lib/old.dart", "lib/new.dart"], ["pubspec.yaml"], ["example/pubspec.lock"], [".pubignore"], [".github/workflows/ci.yml"], ["unknown/file"]):
            self.assertTrue(all(ci.impact(paths).values()), paths)

    def test_gate_rejects_missing_failed_cancelled_or_skipped_required_jobs(self):
        ci.require_jobs({"package": {"result": "success"}, "ios": {"result": "skipped"}}, {"package": True, "ios": False})
        for status in (None, "failure", "cancelled", "skipped"):
            with self.assertRaises(ValueError):
                ci.require_jobs({"package": {"result": status}}, {"package": True})
        with self.assertRaises(ValueError):
            ci.require_jobs({}, {"package": True})
        with self.assertRaises(ValueError):
            ci.require_jobs({"ios": {"result": "failure"}}, {"ios": False})

    def test_gate_requires_the_selected_rehearsal_after_platform_checks(self):
        required = dict.fromkeys(("resolve", "package", "archive", "consumer", "platforms", "rehearsal"), True)
        passed = {name: {"result": "success"} for name in required}
        ci.require_jobs(passed, required)
        for status in (None, "failure", "cancelled", "skipped"):
            with self.subTest(status=status), self.assertRaisesRegex(ValueError, "rehearsal"):
                ci.require_jobs({**passed, "rehearsal": {"result": status}}, required)
        with self.assertRaisesRegex(ValueError, "platforms"):
            ci.require_jobs({**passed, "platforms": {"result": "failure"}, "rehearsal": {"result": "skipped"}}, required)
        optional = {**required, "archive": False, "consumer": False, "platforms": False, "rehearsal": False}
        ci.require_jobs({name: {"result": "success" if expected else "skipped"} for name, expected in optional.items()}, optional)

    def test_semver_and_demo_ordering(self):
        versions = ["1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0", "1.0.1", "2.0.0"]
        for a, b in zip(versions, versions[1:]):
            self.assertLess(ci.compare_versions(a, b), 0)
            self.assertGreater(ci.compare_versions(b, a), 0)
        self.assertEqual(ci.compare_versions("1.0.0+abc", "1.0.0+def"), 0)
        with self.assertRaises(ValueError):
            ci.version("version: 01.0.0")
        candidate = {"version": "1.0.0", "revision": "new"}
        self.assertTrue(ci.pages_needed(None, candidate))
        self.assertFalse(ci.pages_needed({"version": "2.0.0", "revision": "old"}, candidate))
        self.assertTrue(ci.pages_needed(candidate, candidate))
        with self.assertRaises(ValueError):
            ci.pages_needed({**candidate, "revision": "other"}, candidate)

    def test_simulator_selection_uses_an_available_iphone(self):
        older = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
        newer = "com.apple.CoreSimulator.SimRuntime.iOS-27-2"
        phone = dict(name="iPhone 18 Pro", isAvailable=True, udid="fixture", state="Shutdown")
        self.assertEqual(ios_test.select_device({older: [phone], newer: [phone]}), (newer, phone))
        with self.assertRaises(ValueError):
            ios_test.select_device({newer: [{**phone, "isAvailable": False}]})

    def ios_devices(self, state="Shutdown"):
        return json.dumps({"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-26-5": [dict(name="iPhone 17", isAvailable=True, udid="fixture", state=state)]}})

    def test_ios_first_failure_survives_diagnostics_and_cleanup_failures(self):
        for stage in ("startup", "launch", "test"):
            with self.subTest(stage=stage), tempfile.TemporaryDirectory() as temporary:
                failure = subprocess.TimeoutExpired("flutter" if stage == "test" else stage, 1200)
                events = []
                process = mock.Mock(pid=123, stdout=io.StringIO("progress\n"))
                process.wait.side_effect = failure
                def run(command, **kwargs):
                    if "bootstatus" in command and stage == "startup":
                        raise failure
                    if "shutdown" in command:
                        events.append("shutdown")
                        raise subprocess.TimeoutExpired(command, 30)
                def diagnose(*args):
                    events.append("diagnostics")
                    raise OSError("diagnostics unavailable")
                def stop(*args):
                    events.append("terminate")
                    raise OSError("cleanup unavailable")
                with mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(ios_test.sys, "stdout", io.StringIO()) as console, mock.patch.object(ios_test.subprocess, "check_output", return_value=self.ios_devices()), mock.patch.object(ios_test.subprocess, "run", side_effect=run), mock.patch.object(ios_test.subprocess, "Popen", side_effect=failure if stage == "launch" else None, return_value=process) as popen, mock.patch.object(ios_test, "capture_diagnostics", side_effect=diagnose), mock.patch.object(ios_test, "stop_process", side_effect=stop):
                    with self.assertRaises(subprocess.TimeoutExpired) as caught:
                        ios_test.main()
                self.assertIs(caught.exception, failure)
                self.assertEqual(events, ["diagnostics", "terminate", "shutdown"] if stage == "test" else ["diagnostics", "shutdown"])
                self.assertEqual(popen.call_count, 0 if stage == "startup" else 1)
                self.assertIn("Could not shut down simulator", console.getvalue())
                if stage == "test":
                    process.wait.assert_called_once_with(timeout=1200)

    def test_ios_test_failure_is_not_retried_and_booted_device_is_preserved(self):
        for result in (0, 1):
            with self.subTest(result=result), tempfile.TemporaryDirectory() as temporary:
                process = mock.Mock(pid=123, stdout=io.StringIO("progress\n"))
                process.wait.return_value = result
                with mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(ios_test.sys, "stdout", io.StringIO()), mock.patch.object(ios_test.subprocess, "check_output", return_value=self.ios_devices("Booted")), mock.patch.object(ios_test.subprocess, "run") as run, mock.patch.object(ios_test.subprocess, "Popen", return_value=process) as popen, mock.patch.object(ios_test, "capture_diagnostics") as diagnose, mock.patch.object(ios_test, "stop_process"):
                    if result:
                        with self.assertRaises(subprocess.CalledProcessError) as caught:
                            ios_test.main()
                        self.assertEqual(caught.exception.returncode, result)
                    else:
                        ios_test.main()
                run.assert_called_once_with(["xcrun", "simctl", "bootstatus", "fixture", "-b"], check=True, timeout=300)
                self.assertEqual(popen.call_count, 1)
                self.assertEqual(popen.call_args.args[0], ["flutter", "test", "integration_test/app_test.dart", "-d", "fixture", "--verbose"])
                self.assertTrue(popen.call_args.kwargs["start_new_session"])
                self.assertEqual(diagnose.call_count, int(bool(result)))

    def test_ios_diagnostics_are_bounded_scoped_and_redacted(self):
        process = mock.Mock(pid=123)
        responses = [
            "1 0 123 00:01 S flutter\n2 0 999 00:01 S unrelated\n",
            self.ios_devices(),
            "456 0 dev.liu.timetablenext.example token=fixture-secret\n789 0 unrelated.app\n",
        ]
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(ios_test.subprocess, "run", side_effect=[subprocess.CompletedProcess([], 0, stdout=text) for text in responses]) as run:
            ios_test.capture_diagnostics("fixture", process)
            output = (Path(temporary) / "build/diagnostics/ios/failure.log").read_text()
        self.assertEqual(run.call_count, 3)
        self.assertTrue(all(0 < call.kwargs["timeout"] <= 10 for call in run.call_args_list))
        self.assertLessEqual(sum(call.kwargs["timeout"] for call in run.call_args_list), 30)
        self.assertIn("flutter", output)
        self.assertIn('"udid": "fixture"', output)
        self.assertIn("dev.liu.timetablenext.example", output)
        self.assertNotIn("unrelated", output)
        self.assertNotIn("fixture-secret", output)
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(ios_test.sys, "stdout", io.StringIO()), mock.patch.object(ios_test.subprocess, "run", side_effect=subprocess.TimeoutExpired("snapshot", 10)) as run:
            ios_test.capture_diagnostics("fixture", process)
            self.assertEqual(run.call_count, 3)
            self.assertEqual((Path(temporary) / "build/diagnostics/ios/failure.log").read_text().count("Could not capture"), 3)

    def test_ios_termination_targets_only_its_process_group_with_a_fixed_budget(self):
        process, reader = mock.Mock(pid=123), mock.Mock()
        process.wait.side_effect = subprocess.TimeoutExpired("flutter", 10)
        reader.is_alive.return_value = False
        with mock.patch.object(ios_test.os, "killpg") as kill, mock.patch.object(ios_test.time, "monotonic", side_effect=[0, 0, 10, 15]):
            ios_test.stop_process(process, reader)
        self.assertEqual(kill.call_args_list, [mock.call(123, signal.SIGTERM), mock.call(123, signal.SIGKILL)])
        self.assertEqual(process.wait.call_args_list, [mock.call(timeout=10), mock.call(timeout=5)])
        reader.join.assert_called_once_with(timeout=0)

    def test_ios_streams_large_real_process_output_without_exposing_credentials(self):
        credentials = ["http://127.0.0.1:1234/vm-secret=/", "ws://localhost:1234/dds-secret=/ws", "Authorization: Bearer bearer-secret", '"access_token": "json-secret"', "--vm-service-auth-code=code-secret", "password='password-secret'", "client_secret=client-secret"]
        real_popen = subprocess.Popen
        def launch(command, **kwargs):
            script = "import sys; sys.stdout.write(" + repr("\n".join(credentials) + "\n") + "); sys.stdout.write(('x' * 200 + '\\n') * 3000)"
            return real_popen([sys.executable, "-c", script], **kwargs)
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(ci, "ROOT", Path(temporary)), mock.patch.object(ios_test.sys, "stdout", io.StringIO()) as console, mock.patch.object(ios_test.subprocess, "check_output", return_value=self.ios_devices("Booted")), mock.patch.object(ios_test.subprocess, "run"), mock.patch.object(ios_test.subprocess, "Popen", side_effect=launch) as popen:
            (Path(temporary) / "example").mkdir()
            ios_test.main()
            output = (Path(temporary) / "build/diagnostics/ios/flutter-test.log").read_text()
        self.assertEqual(popen.call_count, 1)
        self.assertEqual(output.count("x" * 200), 3000)
        self.assertIn(output, console.getvalue())
        for secret in ("vm-secret", "dds-secret", "bearer-secret", "json-secret", "code-secret", "password-secret", "client-secret"):
            self.assertNotIn(secret, output)
            self.assertNotIn(secret, console.getvalue())

    @unittest.skipUnless(os.name == "posix", "iOS process groups require POSIX")
    def test_ios_termination_reaps_a_real_process(self):
        process = subprocess.Popen([sys.executable, "-c", "import time; print('ready', flush=True); time.sleep(60)"], stdout=subprocess.PIPE, text=True, start_new_session=True)
        try:
            self.assertEqual(process.stdout.readline(), "ready\n")
            ios_test.stop_process(process, None)
            self.assertEqual(process.returncode, -signal.SIGTERM)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
            process.stdout.close()

    def test_coverage_counts_unique_lines_and_requires_complete_production_report(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "lib").mkdir()
            (root / "lib/a.dart").write_text("\n".join(f"int a{i}() => {i};" for i in range(101)) + "\n")
            (root / "lib/entry.dart").write_text("export 'a.dart';\n")
            report = root / "lcov.info"
            lines = "\n".join(f"DA:{i},{int(i <= 95)}" for i in range(1, 101))
            report.write_text(f"SF:lib/a.dart\n{lines}\nend_of_record\n")
            self.assertEqual(ci.coverage(report, root)["hit"], 95)
            report.write_text(report.read_text() + f"SF:{root / 'lib/a.dart'}\nDA:100,1\nend_of_record\n")
            self.assertEqual(ci.coverage(report, root)["total"], 100)
            report.write_text(f"SF:lib/a.dart\n{lines}\nDA:101,0\nend_of_record\n")
            with self.assertRaises(ValueError):
                ci.coverage(report, root)
            for text in ("", "SF:lib/a.dart\nDA:1,1\n"):
                report.write_text(text)
                with self.assertRaises(ValueError):
                    ci.coverage(report, root)
            report.write_text("SF:lib/a.dart\nDA:1,1\nend_of_record\n")
            (root / "lib/missing.dart").write_text("int missing() => 2;\n")
            with self.assertRaisesRegex(ValueError, "missing"):
                ci.coverage(report, root)

    def make_archive(self, extra=None):
        stream = io.BytesIO()
        files = {p: b"fixture" for p in ("LICENSE", "README.md", "CHANGELOG.md", "lib/timetable.dart", "lib/timetable_next.dart")}
        files["pubspec.yaml"] = b"name: timetable_next\nversion: 1.0.0-beta.1\n"
        files.update(extra or {})
        with tarfile.open(fileobj=stream, mode="w:gz") as archive:
            for name, content in files.items():
                member = tarfile.TarInfo(name)
                member.size = len(content)
                archive.addfile(member, io.BytesIO(content))
        return stream.getvalue()

    def make_pages(self, extra=None):
        files = {
            "release.json": b'{"version":"1.0.0-beta.1","revision":"commit"}',
            "index.html": b'<html><head><base href="/timetable_next/"></head></html>',
            "flutter_bootstrap.js": b"bootstrap fixture",
            "main.dart.js": b"application fixture",
            "assets/nested.txt": b"nested fixture",
        }
        files.update(extra or {})
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            for name, content in files.items():
                if content is None:
                    continue
                member = tarfile.TarInfo("./" + name)
                member.size = len(content)
                archive.addfile(member, io.BytesIO(content))
        return stream.getvalue()

    def test_rehearsal_uses_downloaded_artifacts_and_candidate_release_notes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive, metadata, pages = (root / name for name in ("package.tar.gz", "manifest.json", "artifact.tar"))
            archive.write_bytes(self.make_archive({"CHANGELOG.md": b"## 1.0.0-beta.1 - 2026-01-01\n\nCalendar changes.\n\n## 0.9.0\n\nOlder notes.\n"}))
            candidate = ci.manifest(archive, "commit")
            metadata.write_text(json.dumps(candidate))
            pages.write_bytes(self.make_pages())
            destination = root / "rehearsal"
            args = ["ci.py", "release-rehearsal", str(archive), str(metadata), str(pages), str(destination)]
            with mock.patch.dict(ci.os.environ, GITHUB_SHA="commit", CANDIDATE_SHA256=candidate["sha256"]), mock.patch.object(ci.sys, "argv", args), mock.patch.object(ci, "read_json", side_effect=AssertionError("PR rehearsal must not query published contents")), mock.patch.object(ci.sys, "stdout", io.StringIO()):
                ci.main()
            self.assertFalse((destination / "release-notes.md").exists())
            web = ci.archive_files(pages.read_bytes(), mode="r:", required=())
            self.assertEqual({path.relative_to(destination / "web").as_posix(): path.read_bytes() for path in (destination / "web").rglob("*") if path.is_file()}, web)
            with mock.patch.object(ci.sys, "argv", ["ci.py", "release-notes", str(destination / "release-notes.md"), str(archive)]):
                ci.main()
            self.assertEqual((destination / "release-notes.md").read_text(), "Calendar changes.\n\n[pub.dev](https://pub.dev/packages/timetable_next/versions/1.0.0-beta.1) · [Demo](https://masterhiei.github.io/timetable_next/)\n")

    def test_rehearsal_rejects_candidate_and_pages_identity_mismatches(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive, metadata, pages = (root / name for name in ("package.tar.gz", "manifest.json", "artifact.tar"))
            archive.write_bytes(self.make_archive({"CHANGELOG.md": b"## 1.0.0-beta.1\n\nNotes.\n"}))
            candidate = ci.manifest(archive, "commit")
            pages.write_bytes(self.make_pages())
            for field, value in (("version", "2.0.0"), ("revision", "other"), ("sha256", "wrong")):
                metadata.write_text(json.dumps({**candidate, field: value}))
                with self.subTest(field=field), self.assertRaises(ValueError):
                    ci.release_rehearsal(archive, metadata, pages, root / "output", "commit")
            metadata.write_text(json.dumps(candidate))
            with mock.patch.dict(ci.os.environ, CANDIDATE_SHA256="wrong"), self.assertRaisesRegex(ValueError, "verified by this run"):
                ci.release_rehearsal(archive, metadata, pages, root / "output", "commit")
            for changes in (
                {"release.json": b'{"version":"2.0.0","revision":"commit"}'},
                {"release.json": b'{"version":"1.0.0-beta.1","revision":"other"}'},
                {"release.json": b"invalid json"},
                {"release.json": None}, {"index.html": None},
                {"flutter_bootstrap.js": None}, {"main.dart.js": None},
                {"index.html": b'<base href="/">'},
            ):
                pages.write_bytes(self.make_pages(changes))
                with self.subTest(changes=changes), self.assertRaises(ValueError):
                    ci.release_rehearsal(archive, metadata, pages, root / "output", "commit")
                self.assertFalse((root / "output").exists())
            pages.write_bytes(b"broken tar")
            with self.assertRaises(tarfile.ReadError):
                ci.release_rehearsal(archive, metadata, pages, root / "output", "commit")
            pages.write_bytes(self.make_pages())
            archive.write_bytes(b"broken gzip")
            with self.assertRaises(tarfile.ReadError):
                ci.release_rehearsal(archive, metadata, pages, root / "output", "commit")

    def test_release_notes_require_a_nonempty_matching_version_section(self):
        for text in ("## 2.0.0\n\nOther version.\n", "## 1.0.0-beta.1\n\n## 0.9.0\n\nOlder notes.\n"):
            with self.subTest(text=text), self.assertRaisesRegex(ValueError, "Missing release notes"):
                ci.release_notes(text, "1.0.0-beta.1")

    def test_pages_archives_keep_the_package_safety_and_compression_rules(self):
        for name in ("../outside", "/absolute"):
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode="w") as archive:
                member = tarfile.TarInfo(name)
                archive.addfile(member, io.BytesIO())
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "Unsafe"):
                ci.archive_files(stream.getvalue(), mode="r:", required=())
        for kind in (tarfile.SYMTYPE, tarfile.LNKTYPE, tarfile.FIFOTYPE):
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode="w") as archive:
                member = tarfile.TarInfo("entry")
                member.type = kind
                member.linkname = "outside"
                archive.addfile(member)
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                ci.archive_files(stream.getvalue(), mode="r:", required=())
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            for name in ("entry", "./entry"):
                archive.addfile(tarfile.TarInfo(name), io.BytesIO())
        with self.assertRaisesRegex(ValueError, "duplicate"):
            ci.archive_files(stream.getvalue(), mode="r:", required=())
        with self.assertRaises(tarfile.ReadError):
            ci.archive_files(self.make_pages())

    def test_candidate_identity_and_existing_publication(self):
        with tempfile.TemporaryDirectory() as temporary:
            archive, metadata = Path(temporary) / "package.tar.gz", Path(temporary) / "manifest.json"
            data = self.make_archive()
            archive.write_bytes(data)
            metadata.write_text(json.dumps(ci.manifest(archive, "commit")))
            ci.verify_archive(archive, metadata, "commit")
            with self.assertRaises(ValueError):
                ci.verify_archive(archive, metadata, "other")
            with mock.patch.dict(ci.os.environ, CANDIDATE_SHA256="different"):
                with self.assertRaises(ValueError):
                    ci.verify_archive(archive, metadata, "commit")
            response = mock.MagicMock()
            response.__enter__.return_value.read.return_value = data
            with mock.patch.object(ci, "read_json", side_effect=urllib.error.HTTPError("https://pub.dev/fixture", 404, "Not found", {}, None)):
                self.assertIsNone(ci.remote_archive(archive, "1.0.0-beta.1"))
            with mock.patch.object(ci, "read_json", return_value={"archive_url": "https://pub.dev/fixture"}), mock.patch.object(ci.urllib.request, "urlopen", return_value=response):
                self.assertIsNotNone(ci.remote_archive(archive, "1.0.0-beta.1"))
                archive.write_bytes(self.make_archive({"lib/extra.dart": b"changed"}))
                with self.assertRaises(ValueError):
                    ci.remote_archive(archive, "1.0.0-beta.1")
            with self.assertRaises(ValueError):
                ci.verify_archive(archive, metadata, "commit")

    def test_archive_contract_rejects_unsafe_paths_and_missing_entries(self):
        with self.assertRaises(ValueError):
            ci.archive_files(self.make_archive({"../outside": b"invalid"}))
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w:gz"):
            pass
        with self.assertRaisesRegex(ValueError, "missing"):
            ci.archive_files(stream.getvalue())

    def test_deployed_revision_wait_is_bounded(self):
        expected = {"revision": "fixture", "version": ci.version((ci.ROOT / "pubspec.yaml").read_text())}
        response = mock.MagicMock()
        response.__enter__.return_value.status = 200
        with mock.patch.dict(ci.os.environ, GITHUB_SHA="fixture"), mock.patch.object(ci.sys, "argv", ["ci.py", "check-deployed", "https://example.invalid/"]), mock.patch.object(ci.time, "sleep"), mock.patch.object(ci.urllib.request, "urlopen", return_value=response):
            with mock.patch.object(ci, "read_json", side_effect=[None, expected]):
                ci.main()
            with mock.patch.object(ci, "read_json", return_value=None), mock.patch.object(ci.time, "monotonic", side_effect=[0, 121]):
                with self.assertRaisesRegex(ValueError, "does not match"):
                    ci.main()

    def test_release_guard_checks_tag_changelog_and_main_ancestry(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return ci.run("git", *args, cwd=root)
            git("init", "--initial-branch=main")
            git("config", "user.email", "fixture@example.invalid")
            git("config", "user.name", "CI fixture")
            (root / "pubspec.yaml").write_text("version: 1.0.0-beta.1\n")
            (root / "CHANGELOG.md").write_text("## 1.0.0-beta.1\n\nInitial release.\n")
            git("add", ".")
            git("commit", "-m", "fixture")
            revision = git("rev-parse", "HEAD")
            git("update-ref", "refs/remotes/origin/main", revision)
            git("tag", "v1.0.0-beta.1")
            self.assertEqual(ci.release_guard("v1.0.0-beta.1", revision, root), "1.0.0-beta.1")
            with self.assertRaises(ValueError):
                ci.release_guard("v2.0.0", revision, root)
            (root / "CHANGELOG.md").write_text("## Other version\n")
            with self.assertRaises(ValueError):
                ci.release_guard("v1.0.0-beta.1", revision, root)
            (root / "CHANGELOG.md").write_text("## 1.0.0-beta.1\n")
            git("checkout", "--orphan", "unrelated")
            git("add", ".")
            git("commit", "-m", "unrelated")
            git("update-ref", "refs/remotes/origin/main", git("rev-parse", "HEAD"))
            with self.assertRaises(subprocess.CalledProcessError):
                ci.release_guard("v1.0.0-beta.1", revision, root)


if __name__ == "__main__":
    unittest.main()
