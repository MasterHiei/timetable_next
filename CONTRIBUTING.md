# Contributing

Report bugs with the package/Flutter version, platform, reproduction, and expected versus actual behavior. Discuss significant API changes before implementation.

## Workflow

`main` is the integration branch. Create a short-lived `feature/<name>` or `fix/<name>` branch and open a pull request. Keep commits focused; describe observable changes and relevant checks. After the first manual publication, a maintainer's protected version tag authorizes automatic publication following full acceptance. See [releasing](doc/RELEASING.md).

Preserve public types and documented semantics. Behavioral fixes should include a regression test. Keep implementation changes separate from unrelated formatting or cleanup.

## Checks

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool example/lib example/integration_test example/test_driver
flutter analyze --fatal-infos
flutter test --coverage
python3 tool/ci.py coverage coverage/lcov.info
python3 -m unittest discover -s tool -p 'test_*.py'
```

Use the existing development SDK and tools locally. To apply formatting, run `dart format lib test tool example/lib example/integration_test example/test_driver`. CI checks stable formatting, the minimum SDK and the selected example platforms; do not install or switch local environments to reproduce that matrix. See [QA boundaries](doc/QA.md).

Await asynchronous work when its completion is required. Use `unawaited` from `dart:async` for intentional concurrency, including animations advanced by widget-test pumps; do not change their ordering just to satisfy a lint. Explain necessary diagnostic suppressions immediately above the ignore. Remove obsolete suppressions when reviewing SDK upgrades, checking both supported SDK endpoints before removal.

Keep example lockfiles and Gradle wrapper sources versioned. Do not commit generated output, machine configuration, credentials or raw verification logs. Root `.gitignore` owns shared exclusions; keep the shared `.pubignore` rules aligned.

Contributions use Apache-2.0. Preserve the licensing, attribution and source notices required by [LICENSE](LICENSE). Explain non-obvious behavioral changes at their owning code rather than adding development-progress comments.

For AI-assisted work, read [AGENTS.md](AGENTS.md). Human and generated changes follow the same review standards.
