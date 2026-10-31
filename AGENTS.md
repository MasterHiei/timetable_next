# timetable_next

Read [CONTEXT.md](CONTEXT.md) for code ownership and [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

Preserve the public types, constructors and time semantics. `lib/timetable_next.dart` owns public exports; `lib/timetable.dart` is a compatibility re-export. `dart_date.Interval` appears in public signatures and cannot be replaced as an internal cleanup.

Keep value objects and caller-owned data immutable. Controllers own mutable interaction state, animations and view registrations; old work must not dispose or overwrite its replacement. Explain non-obvious behavioral constraints at their owning code. Preserve licensing, attribution and source notices required by LICENSE.

## Verification

Follow [doc/QA.md](doc/QA.md) for local checks and CI coverage. Use the existing development environment locally; CI owns the SDK and platform matrices. Format changed Dart files and use fixed UTC fixtures with independent expected values. Do not weaken assertions, skip critical tests or retry away product failures.

Keep machine paths, task progress, raw logs and generated artifacts out of tracked files. Review the diff for scope drift and accidental files before reporting results. Distinguish failed checks from checks that could not run.

## Review rules

- Preserve compatible public entries and types.
- Check animation completion, interruption, replacement and disposal.
- Check timer/listener/registration cleanup and detached-view updates.
- Support compatibility and release claims with the required checks.
