# Changelog

<!-- Changes from upstream: replaced mixed upstream notes with independent release notes and a history link. -->

## 1.0.0-beta.3 - 2026-11-03

### Breaking changes

- Require Flutter 3.47.0 and Dart 3.13.0 or later.
- Migrate Material widgets and themes to `material_ui`. Update application imports to `package:material_ui/material_ui.dart`.
- Use `GlobalMaterialLocalizations.delegates` from `material_ui` alongside `TimetableLocalizationsDelegate` for localization.

### Changed

- Upgrade `black_hole_flutter` to 2.x for standalone Material support.

## 1.0.0-beta.2 - 2026-11-01

Maintenance prerelease with no changes to calendar behavior or public APIs.

### Fixed

- Fix an iOS CI startup race that could leave integration tests waiting for the VM Service.
- Preserve the original iOS test failure when simulator cleanup also fails.

## 1.0.0-beta.1 - 2026-10-31

First independent release based on timetable 1.0.0-alpha.15.

### Changed

- Replace the `timetable` dependency with `timetable_next` and import `package:timetable_next/timetable_next.dart`. The `package:timetable_next/timetable.dart` entry remains available for compatibility.
- Require Flutter 3.38.1 and Dart 3.10.0 or later.

### Fixed

- Complete `DateController` and `TimeController` animation futures when animations finish, are interrupted or their controllers are disposed.
- Notify `DateController` listeners when scroll activity changes, even when the visible page stays the same.
- Update zoom limits when views detach or change `TimeController`.
- Preserve microseconds in event queries and date copies, including events immediately before midnight.
- Keep event end times exclusive when creating time overlays and return no overlay for zero-duration events.
- Initialize `CompactMonthTimetable` from the month selected by its `DateController`.
- Keep `MonthPageController.value` available without an attached view and notify listeners on the first month change.
- Display the new controller's month when `MonthPageView` changes controllers, without disposing caller-owned controllers.
- Honor parent constraints in calendar columns, time labels and compact month views, including zero-height all-day headers.
- Cancel current-time repaint timers and detach unused controller listeners when views are removed.

Earlier releases belong to the original [timetable changelog](https://github.com/JonasWanke/timetable/blob/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/CHANGELOG.md).
