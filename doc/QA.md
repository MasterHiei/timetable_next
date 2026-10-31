# Quality checks

## Boundaries

This is a Flutter widget library. Tests cover its date/event semantics, controllers, layout and interaction. The example supplies Android/iOS/Web host applications. Persistence, synchronization, time-zone conversion and recurrence rules belong to the host application.

Flutter 3.38.1 is the minimum package endpoint. CI resolves the current stable version once per run. Both SDKs validate package contracts; only stable builds and exercises the example platforms. This does not certify signing, app-store distribution, other host configurations or real-device performance.

## Local development

Use the existing development SDK and tools. Start with checks affected by the change. SDK and platform matrices run in CI; local development does not require installing or switching environments.

Format changed Dart files with `dart format`. After test changes, run the complete local package checks:

```sh
flutter pub get
flutter analyze --fatal-infos
flutter test --coverage
python3 tool/ci.py coverage coverage/lcov.info
```

For helper or workflow changes, also run the script tests with the existing Python environment, if available:

```sh
python3 -m unittest discover -s tool -p 'test_*.py'
```

Bypass proxies for localhost test sockets in the test process if they interfere with Flutter's VM service.

After these checks pass, rerun only checks affected by further changes or failures. Other SDKs, platform builds, browser/device integration and release rehearsal are CI responsibilities.

## CI selection

| Change or event | Checks |
|---|---|
| Every PR | Stable formatting and helper checks; both SDKs analyze and run all unit/widget tests; stable coverage |
| Library, dependency declarations, distribution configuration or CI/helpers | Minimum-SDK dependency downgrade checks and stable candidate-archive consumer |
| Shared library, example Dart code, shared integration fixture or CI/helpers | Stable Android/iOS/Web builds and interactions |
| Platform-only host changes | That stable platform's build and interaction |
| Ordinary tests or documentation | Basic package checks |
| Main, manual or release tag | All checks |
| Unknown paths | All checks; classification failure fails CI |

`ci.yml` owns these checks and is reusable by `release.yml`. The single required result is `CI / required`. Its gate checks expected jobs: failure, cancellation or an unexpected skip cannot pass. Workflows have no top-level PR path filters.

Both SDK jobs analyze and test upgraded dependencies. Downgrade checks run last on the minimum SDK, without overriding Flutter's pinned dependencies. They validate the combination Pub resolves in that environment, not every permitted combination. The archive consumer runs on stable; minimum-SDK package compatibility is tested from source. Stable with downgraded dependencies and minimum-SDK archive consumption are outside this matrix.

Archive and platform jobs have independent checkouts. There are no scheduled runs; upstream changes are checked on the next PR, main push, manual run or release.

## Test design

- Use fixed UTC data and independent expected values. For Today navigation, take before/after date snapshots and check the visible range and alignment.
- Keep snapping ties, negative pages, all week starts, range limits, leap days and cross-year cases. Separate snapping from visible-day-count boundary tests.
- Cover event adjacency, overlap, midnight, zero duration, microseconds, clipping and identity.
- Check animation completion/interruption/replacement/reentry/disposal and listener/timer/view-registration cleanup.
- Exercise the three layouts with pairwise size/locale/theme/text-scale fixtures; keep narrow Chinese large-text cases and individual defect regressions.
- Assert rendered results and user-visible updates. Precise drag-coordinate arithmetic belongs in widget tests; platform tests exercise gestures and callbacks without repeating that arithmetic.
- Preserve public immutable copy/equality contracts. Assert retained and overridden fields without requiring a new instance. Exercise diagnostic regressions without depending on incidental text. Avoid self-comparisons and tests of Flutter's own behavior to increase coverage.

Production `lib/` line coverage must be >=95% before rounding. The checker merges duplicate records and rejects empty, incomplete or missing-module reports. No production exclusions or coverage-ignore annotations are permitted. Coverage is a guard, not proof of behavior.

## Platform and artifact checks

CI uses `ubuntu-24.04` for Android/Web and `macos-26` for iOS. Android selects JDK 17, API 35/x86_64 for interaction. iOS records the runner's default Xcode and selects an available iPhone simulator; the example retains SwiftPM and UIScene. Chrome and ChromeDriver are installed as a matching pair.

Each selected platform builds its release example and runs the shared interaction fixture. Native commands retain Pub so Flutter regenerates the plugin registrant for the build mode. Do not use `--no-pub` for native builds or device tests.

Web additionally runs the JavaScript-sensitive date/event contract tests. It then builds JavaScript Release **after** integration testing with `/timetable_next/` as base href and local engine resources. A separate smoke check serves that actual bundle at the subpath, finds the Today control, opens the Theme menu and checks browser errors. Screenshots are failure diagnostics, not acceptance thresholds.

The archive check runs publish dry-run, creates one candidate and records version, revision and SHA-256. An independent consumer on stable uses only extracted archive contents to verify public entries, `dart_date.Interval` and widget rendering. See [releasing](RELEASING.md) for distribution.

## Workflow maintenance

Keep Actions pinned to full commits with version comments. CI runs actionlint for workflow syntax and unit tests for project-owned selection, gate, coverage, version-ordering and artifact-identity logic.

PR updates cancel superseded PR runs. Releases queue without cancellation. Jobs have bounded timeouts. Product tests are not automatically retried; remote publication/deployment visibility uses bounded read polling.

Cache downloaded SDK/Pub/Gradle dependencies, not credentials or workspace state. Keep coverage, candidate and Pages artifacts for 14 days and upload browser diagnostics on failure. Report unexecuted checks as unverified.

## Official references

- [Flutter testing tradeoffs](https://docs.flutter.dev/testing/overview)
- [Dart dependency and downgrade testing](https://dart.dev/tools/pub/dependencies)
- [Flutter mode-specific plugin generation](https://github.com/flutter/flutter/blob/3.38.1/packages/flutter_tools/lib/src/runner/flutter_command.dart)
- [GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
