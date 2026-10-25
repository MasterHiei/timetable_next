# Testing and release checks

## Package checks

```sh
flutter pub get
flutter analyze --fatal-infos
flutter test --coverage
```

Run on Flutter 3.38.1 and current stable. In a separate checkout, repeat analysis and tests after `flutter pub downgrade` to validate dependency lower bounds.

## Behavioral coverage

| Area | Required checks |
|---|---|
| Dates | Negative/positive pages, exact ties, all weekdays, one-sided/two-sided limits, leap days and cross-year ranges |
| Events | Intersection rules, adjacency, containment, midnight, zero duration, microseconds and the 24-hour all-day boundary |
| Controllers | Futures during/completing/interrupted animations, reentry, disposal, shared-view limits and replacement controllers |
| Views | Three layouts, empty/overlapping/all-day events, navigation, zoom, tap and drag coordinates |
| Configuration | English/Simplified Chinese, light/dark themes, text scales 1/2, sizes 320×640 and 800×600 |

Use fixed UTC fixtures and independent expected values. Advance animation tests with virtual time. Check resource cleanup and framework exceptions as well as visible state. Coverage helps locate omissions; it is not a substitute for behavior checks.

## Platforms

From `example`, on both SDK endpoints:

```sh
flutter build apk
flutter build ios --no-codesign
flutter build web
```

The example targets Android, iOS and ordinary JavaScript Web. iOS uses Swift Package Manager. Use an Xcode version compatible with the selected Flutter SDK.

Run `flutter test integration_test/app_test.dart -d <device-id>` on Android and iOS. On Chrome, start a matching ChromeDriver and run:

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server --browser-name=chrome --driver-port=4444 --headless
```

## Release acceptance

Require package checks, six platform builds, three-platform interaction checks, `flutter pub publish --dry-run`, and a consumer using only the intended package contents. Preserve licensing, source attribution and migration information.

Attach revision, SDK/dependency versions, target, command and result to CI or release artifacts. Treat environment-blocked and unexecuted checks as incomplete. Do not hide failures with retries, skipped assertions or arbitrary timeouts. Signing and real-device performance require separate verification.
