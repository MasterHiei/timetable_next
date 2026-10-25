# Independent maintenance

Continue timetable alpha.15 (`23b4d1b`) as `timetable-next`, preserving upstream history, authorship and Apache-2.0 licensing. The independent package has its own review and release process while retaining the original public types and time model.

Project/repository names use `timetable-next`; Dart uses `timetable_next`. `timetable_next.dart` is the primary entry and `timetable.dart` remains a compatibility re-export. Example platform identifiers use `dev.liu.timetablenext.example`.

Retain public dependency types such as `dart_date.Interval`. Dependency and SDK changes are validated against the supported endpoints before release.
