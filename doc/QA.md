# Quality checks

## Boundaries

This is a Flutter widget library. Tests cover its date/event semantics, controllers, layout and interaction. The example supplies Android/iOS/Web host applications. Persistence, synchronization, time-zone conversion and recurrence rules belong to the host application.

Flutter 3.38.1 is the minimum package endpoint. CI resolves the current stable version once per run. Both SDKs validate package contracts; only stable builds and exercises the example platforms. This does not certify signing, app-store distribution, other host configurations or real-device performance.

## Local development

Use the existing development SDK and tools. Do not install or switch SDKs, JDKs, browsers or simulator runtimes to reproduce the CI matrix locally.

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool example/lib example/integration_test example/test_driver
flutter analyze --fatal-infos
flutter test --coverage
python3 tool/ci.py coverage coverage/lcov.info
python3 -m unittest discover -s tool -p 'test_*.py'
```

Run the script tests when the existing Python environment is available; otherwise leave them to CI. Proxy settings that intercept localhost test sockets should be bypassed for that process. Never change product behavior to mask an environment failure.

After these checks pass, rerun only checks affected by further changes or failures. Other SDKs, platform builds, browser/device integration and release rehearsal are CI responsibilities.

## CI selection

| Change or event | Checks |
|---|---|
| Every PR | Stable formatting and helper checks; both SDKs analyze and run all unit/widget tests; stable coverage |
| Library, dependency declarations, distribution configuration or CI/helpers | Also test downgraded dependencies and the candidate archive with both consumers |
| Shared library, example Dart code, shared integration fixture or CI/helpers | Stable Android/iOS/Web builds and interactions |
| Platform-only host changes | That stable platform's build and interaction |
| Ordinary tests or documentation | Basic package checks |
| Main, weekly, manual or release tag | All checks |
| Unknown paths | All checks; classification failure fails CI |

`ci.yml` owns these checks and is reusable by `release.yml`. The single required result is `CI / required`. Its gate checks expected jobs: failure, cancellation or an unexpected skip cannot pass. Workflows have no top-level PR path filters.

Downgrade checks run last in each SDK job; archive and platform jobs have independent checkouts. They prove the lowest dependency combination produced by Pub, not every permitted combination. Do not override Flutter's pinned dependencies. Pub output records actual dependency resolutions.

## Test design

- Use fixed UTC data and independent expected values. Test current-date entrypoints through invariants.
- Keep snapping ties, negative pages, all week starts, range limits, leap days and cross-year cases. Separate snapping from visible-day-count boundary tests.
- Cover event adjacency, overlap, midnight, zero duration, microseconds, clipping and identity.
- Check animation completion/interruption/replacement/reentry/disposal and listener/timer/view-registration cleanup.
- Exercise the three layouts with pairwise size/locale/theme/text-scale fixtures; keep narrow Chinese large-text cases and individual defect regressions.
- Assert rendered results and user-visible updates. Precise drag-coordinate arithmetic belongs in widget tests; platform tests exercise gestures and callbacks without repeating that arithmetic.
- Preserve public immutable copy/equality contracts. Do not add self-comparisons, incidental diagnostic-string assertions or tests of Flutter's own behavior to increase coverage.

Production `lib/` line coverage must be >=95% before rounding. The checker merges duplicate records and rejects empty, incomplete or missing-module reports. No production exclusions or coverage-ignore annotations are permitted. Coverage is a guard, not proof of behavior.

## Platform and artifact checks

CI uses `ubuntu-24.04` for Android/Web and `macos-26` for iOS. Android selects JDK 17, API 35/x86_64 for interaction. iOS records the runner's default Xcode and selects an available iPhone simulator; the example retains SwiftPM and UIScene. Chrome and ChromeDriver are installed as a matching pair.

Each selected platform builds its release example and runs the shared interaction fixture. Native commands retain Pub so Flutter regenerates the plugin registrant for the build mode. Do not use `--no-pub` for native builds or device tests.

Web additionally runs the JavaScript-sensitive date/event contract tests. It then builds JavaScript Release **after** integration testing with `/timetable_next/` as base href and local engine resources. A separate smoke check serves that actual bundle at the subpath, finds the Today control, opens the Theme menu and checks browser errors. Screenshots are failure diagnostics, not acceptance thresholds.

The archive check runs publish dry-run, creates one candidate and records version, revision and SHA-256. Both independent consumers use only extracted archive contents to verify public entries, `dart_date.Interval` and widget rendering. See [releasing](RELEASING.md) for distribution.

## Workflow maintenance

Keep Actions pinned to full commits with version comments; update them deliberately. Use actionlint for workflow syntax and unit tests for project-owned selection, gate, coverage, version-ordering and artifact-identity logic. Actionlint 1.7.12 predates GitHub's `concurrency.queue`; only that exact unknown-key diagnostic is excluded.

PR updates cancel superseded PR runs. Releases queue without cancellation. Package jobs time out after 15 minutes, platforms after 30, simulator startup after five and publication/deployment after ten. Do not automatically retry product tests. Only remote publication/deployment visibility uses bounded read polling.

Cache downloaded SDK/Pub/Gradle dependencies, not credentials, `.dart_tool`, workspaces or simulator state. Keep coverage, candidate and Pages artifacts for 14 days; upload browser diagnostics on failure. Use standard job logs/results instead of custom success-evidence bundles. Report unexecuted checks as unverified.

## Official references

- [Flutter testing tradeoffs](https://docs.flutter.dev/testing/overview)
- [Dart dependency and downgrade testing](https://dart.dev/tools/pub/dependencies)
- [Flutter mode-specific plugin generation](https://github.com/flutter/flutter/blob/3.38.1/packages/flutter_tools/lib/src/runner/flutter_command.dart)
- [GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
