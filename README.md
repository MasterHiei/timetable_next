# timetable-next

<!-- Changes from upstream: updated package usage, examples, compatibility and source attribution. -->

Customizable Flutter calendar widgets with day, week, and month views. Inspired by [timetable](https://github.com/JonasWanke/timetable).

Requires Flutter 3.38.1 and Dart 3.10.0 or later.

![Week view](doc/screenshot-MultiDateTimetable-light.webp)

## Getting started

Add `timetable_next` to your dependencies and import the main entry:

```dart
import 'package:flutter/material.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  final date = DateTimeTimetable.today();
  final events = [
    BasicEvent(
      id: 'meeting',
      title: 'Team meeting',
      backgroundColor: Colors.blue,
      start: date.add(const Duration(hours: 9)),
      end: date.add(const Duration(hours: 10)),
    ),
  ];

  runApp(
    MaterialApp(
      localizationsDelegates: const [TimetableLocalizationsDelegate()],
      home: Scaffold(
        body: TimetableConfig<BasicEvent>(
          eventProvider: eventProviderFromFixedList(events),
          eventBuilder: (context, event) => BasicEventWidget(event),
          child: MultiDateTimetable<BasicEvent>(),
        ),
      ),
    ),
  );
}
```

`TimetableConfig` creates default date and time controllers. Supply your own controllers for navigation or zoom control, and dispose them with their owning widget.

## Layouts and customization

| Widget | Use |
|---|---|
| `MultiDateTimetable` | Consecutive days with timed and all-day events |
| `RecurringMultiDateTimetable` | A date-independent display, such as a weekly schedule |
| `CompactMonthTimetable` | Paged months with date selection |

Use `VisibleDateRange` to choose day/week ranges, `TimetableThemeData` for styling, and `TimetableCallbacks` for interactions. Draggable events and time overlays are available through the [API reference](https://pub.dev/documentation/timetable_next/latest/timetable_next/).

## Dates and localization

Pass UTC-marked `DateTime` values containing the fields you want displayed. The package does not convert time zones. Positive event spans are start-inclusive/end-exclusive; zero-duration events are points. All-day classification uses a duration of at least 24 hours.

Keep `TimetableLocalizationsDelegate` in your application's localization delegates. Supported locales are German, English, Spanish, French, Hungarian, Italian, Japanese, Portuguese, Simplified Chinese and Traditional Chinese. Add Flutter's localization delegates when localizing the surrounding app.

The recurring layout hides concrete dates; recurrence expansion belongs to the host application. A compact month can require a vertical scroll host at large text scales.

## Example and development

```sh
cd example
flutter run
```

The example targets Android, iOS and Web. Its iOS project uses Swift Package Manager.

See [contributing](CONTRIBUTING.md), [testing](doc/QA.md) and the [changelog](CHANGELOG.md). Existing `timetable.dart` imports remain available as a compatibility entry.

## License

[Apache-2.0](LICENSE). Source history and attribution are documented in the [maintenance decision](doc/adr/0001-independent-maintenance.md).
