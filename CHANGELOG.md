# Changelog

<!-- Changes from upstream: replaced mixed upstream notes with independent release notes and a history link. -->

## 1.0.0-beta.1 - 2026-10-31

First independent release based on timetable 1.0.0-alpha.15.

### Changed

- Replace the `timetable` dependency with `timetable_next` and import `package:timetable_next/timetable_next.dart`. The `package:timetable_next/timetable.dart` entry remains available for compatibility.
- Require Flutter 3.38.1 and Dart 3.10.0 or later.

### Fixed

- Ensure `DateController` and `TimeController` animation futures wait for completion and also complete when animations are interrupted or controllers are disposed.
- Notify `DateController` listeners when scroll activity changes, even if the visible page is unchanged.
- Recalculate zoom limits when views detach or switch to a different `TimeController`.
- Preserve microsecond precision when querying events and copying dates, including events just before midnight.
- Preserve exclusive end times when converting events to time overlays, and return no overlay for zero-duration events.
- Open `CompactMonthTimetable` at the month selected by its `DateController`.
- Keep `MonthPageController.value` readable when no view is attached, and notify listeners on the first month change. Replacing a `MonthPageView` controller displays the new controller's month without disposing caller-owned controllers.
- Respect parent size constraints in calendar columns, time labels and compact month views, including all-day headers constrained to zero height.
- Stop current-time repaint timers and remove unused controller listeners when views detach.

Earlier releases belong to the original [timetable changelog](https://github.com/JonasWanke/timetable/blob/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/CHANGELOG.md).
