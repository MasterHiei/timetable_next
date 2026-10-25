# Dependency decisions

| Dependency | Rationale |
|---|---|
| `black_hole_flutter` 1.x | Retains the selected Flutter minimum; 2.x requires a newer SDK and a separate migration. |
| `dart_date` | `Interval` is part of the public API. |
| `flutter_layout_grid` >=2.0.5 within 2.x | Earlier releases use Flutter APIs removed from supported SDKs. |
| `collection`, `intl`, `meta` | Collection operations, localization and API annotations. |
| `flutter_test`, `flutter_lints` | SDK-aligned tests and static analysis. |

Date and range helpers use the Dart SDK and existing collection utilities. Deterministic tests cover snapping, boundaries and comparison semantics. Repaint scheduling uses a cancellable SDK timer.

The Android example uses JDK 17, Gradle 8.14.3, AGP 8.11.1 and Kotlin 2.2.20. Its Gradle distribution checksum is pinned. The iOS example uses Swift Package Manager; generated packages are not versioned.

Check both SDK endpoints and downgraded dependency resolution when changing constraints. Evaluate dependency use, compatibility and maintenance together; release age alone is not a vulnerability finding.
