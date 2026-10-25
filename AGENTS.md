# timetable-next

Read [CONTEXT.md](CONTEXT.md) for code ownership and [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

Preserve the public types, constructors and time semantics. `lib/timetable_next.dart` owns public exports; `lib/timetable.dart` is a compatibility re-export. `dart_date.Interval` appears in public signatures and cannot be replaced as an internal cleanup.

Keep value objects and caller-owned data immutable. Controllers own mutable interaction state, animations and view registrations; old work must not dispose or overwrite its replacement. Explain non-obvious behavioral constraints at their owning code. Preserve licensing, attribution and source notices required by LICENSE.

## Verification

```sh
flutter pub get
flutter analyze --fatal-infos
flutter test
```

Format changed Dart files. For dependency or platform changes, run the corresponding checks in [doc/QA.md](doc/QA.md), including the minimum SDK. Use fixed UTC fixtures and independent expected values. Do not weaken assertions, skip critical tests or retry away product failures.

Keep machine paths, task progress, raw logs and generated artifacts out of tracked files. Review the diff for scope drift and accidental files before reporting results. Distinguish failed checks from checks that could not run.

## Review rules

- Preserve compatible public entries and types.
- Check animation completion, interruption, replacement and disposal.
- Check timer/listener/registration cleanup and detached-view updates.
- Support compatibility and release claims with the required checks.
