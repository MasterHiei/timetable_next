import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest import mock

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
