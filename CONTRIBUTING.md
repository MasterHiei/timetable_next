# Contributing

Report bugs with the package/Flutter version, platform, reproduction, and expected versus actual behavior. Discuss significant API changes before implementation.

## Workflow

`main` is the integration branch. Create a short-lived `feature/<name>` or `fix/<name>` branch and open a pull request. Keep commits focused; describe observable changes and relevant checks. Release publication is manual.

Preserve public types and documented semantics. Behavioral fixes should include a regression test. Keep implementation changes separate from unrelated formatting or cleanup.

## Checks

```sh
flutter pub get
flutter analyze --fatal-infos
flutter test
```

Format changed Dart files. Dependency and platform changes require the corresponding [QA checks](doc/QA.md). The iOS example uses Swift Package Manager with the project setting in `example/pubspec.yaml`.

Keep example lockfiles and Gradle wrapper sources versioned. Do not commit generated output, machine configuration, credentials or raw verification logs. Root `.gitignore` owns shared exclusions; keep the shared `.pubignore` rules aligned.

Contributions use Apache-2.0. Preserve the licensing, attribution and source notices required by [LICENSE](LICENSE). Explain non-obvious behavioral changes at their owning code rather than adding development-progress comments.

For AI-assisted work, read [AGENTS.md](AGENTS.md). Human and generated changes follow the same review standards.
