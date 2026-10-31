# Contributing

Report bugs with the package/Flutter version, platform, reproduction, and expected versus actual behavior. Discuss significant API changes before implementation.

## Workflow

`main` is the integration branch. Create a short-lived `feature/<name>` or `fix/<name>` branch and open a pull request. Keep commits focused; describe observable changes and relevant checks.

Preserve public types and documented semantics. Behavioral fixes should include a regression test. Keep implementation changes separate from unrelated formatting or cleanup.

## Checks

Follow [Quality checks](doc/QA.md) for local commands, test design and the CI matrix. Use the existing development SDK and tools locally; CI covers the supported SDK endpoints and selected example platforms.

Await asynchronous work when its completion is required. Use `unawaited` from `dart:async` for intentional concurrency, including animations advanced by widget-test pumps; do not change their ordering just to satisfy a lint. Explain necessary diagnostic suppressions immediately above the ignore. Remove obsolete suppressions when reviewing SDK upgrades, checking both supported SDK endpoints before removal.

Keep example lockfiles and Gradle wrapper sources versioned. Do not commit generated output, machine configuration, credentials or raw verification logs. Root `.gitignore` owns shared exclusions; keep the shared `.pubignore` rules aligned.

Contributions use Apache-2.0. Preserve the licensing, attribution and source notices required by [LICENSE](LICENSE). Explain non-obvious behavioral changes at their owning code rather than adding development-progress comments.

For AI-assisted work, read [AGENTS.md](AGENTS.md). Human and generated changes follow the same review standards.
