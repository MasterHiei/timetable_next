# Changelog

<!-- Changes from upstream: replaced mixed upstream notes with independent release notes and a history link. -->

## 1.0.0-beta.1 — Unreleased

First independent release based on timetable 1.0.0-alpha.15.

### Changed

- Use the `timetable_next` package and `timetable_next.dart` entry. The `timetable.dart` entry remains available for compatibility.
- Require Flutter 3.38.1 and Dart 3.10.0 or later.

### Fixed

- Complete animation futures on completion or interruption, and release animation resources safely.
- Notify date activity changes even when the visible page is unchanged.
- Recalculate zoom limits when views detach or replace their controllers.
- Preserve submillisecond event boundaries and midnight tails; date copies retain microseconds.
- Start compact months at the supplied controller's date and respect bounded layout constraints.
- Cancel current-time repaint timers when their view detaches.
- Release mapped-listenable subscriptions when the last view detaches.

Earlier releases belong to the original [timetable changelog](https://github.com/JonasWanke/timetable/blob/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/CHANGELOG.md).
