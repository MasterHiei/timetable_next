# Dependency decisions

| Dependency | Rationale |
|---|---|
| `black_hole_flutter` ^1.2.0 | Root and example share the same minimum; 2.x requires Flutter >=3.47/Dart >=3.13 and a Material migration, outside the retained support window. |
| `dart_date` | `Interval` is part of the public API. |
| `flutter_layout_grid` >=2.0.5 within 2.x | Earlier releases use Flutter APIs removed from supported SDKs. |
| `collection`, `intl`, `meta` | Collection operations, localization and API annotations. |
| `flutter_test`, `flutter_lints` | SDK-aligned tests and static analysis. |

Date and range helpers use the Dart SDK and existing collection utilities. Deterministic tests cover snapping, boundaries and comparison semantics. Repaint scheduling uses a cancellable SDK timer.

The Android example uses JDK 17, Gradle 8.14.6, AGP 8.11.1 and Kotlin 2.2.21. The Wrapper is generated with Gradle 8.14.6 and pins the official distribution checksum. CI validates this combination against the run's stable Flutter SDK. The iOS example uses Swift Package Manager; generated packages are not versioned. Platform builds use stable Flutter in CI; the minimum SDK is checked at the package boundary.

Flutter 3.38.1 is the first supported endpoint because Flutter 3.38.0 shipped Dart 3.10 beta, which does not satisfy Dart >=3.10.0 stable. SDK-pinned packages may resolve differently across SDKs; do not force newer versions with overrides. Updating resolved versions does not require raising otherwise valid library lower bounds.

When changing constraints, CI analyzes and tests both SDK endpoints with upgraded dependencies and checks downgraded dependencies on the minimum SDK. These checks cover the combinations Pub resolves for those environments. See [Quality checks](QA.md) for the verification matrix. Evaluate dependency use, compatibility and maintenance together; release age alone is not a vulnerability finding.
