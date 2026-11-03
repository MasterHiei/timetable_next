# timetable_next

<!-- Changes from upstream: updated package usage, examples, compatibility and source attribution. -->

📅 Customizable, animated calendar widget including day, week, and month views.

---

An independently maintained continuation of [JonasWanke/timetable](https://github.com/JonasWanke/timetable).

Explore the [web demo](https://masterhiei.github.io/timetable_next/) to try the calendar layouts and interactions.

---

| Navigation | Animation |
| :---: | :---: |
| ![navigation](https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-navigation.webp) | ![animation](https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-animation.webp) |

| Callbacks | Changing the [`VisibleDateRange`] |
| :---: | :---: |
| ![callbacks](https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-callbacks.webp) | ![visibleDateRange](https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-visibleDateRange.webp) |

- [timetable\_next](#timetable_next)
  - [Available Layouts](#available-layouts)
    - [`MultiDateTimetable`](#multidatetimetable)
    - [`RecurringMultiDateTimetable`](#recurringmultidatetimetable)
    - [`CompactMonthTimetable`](#compactmonthtimetable)
  - [Getting started](#getting-started)
    - [0. General Information](#0-general-information)
    - [1. Define your `Event`s](#1-define-your-events)
    - [2. Create a `DateController` (optional)](#2-create-a-datecontroller-optional)
    - [3. Create a `TimeController` (optional)](#3-create-a-timecontroller-optional)
    - [4. Create your Timetable widget](#4-create-your-timetable-widget)
  - [Theming](#theming)
  - [Advanced Features](#advanced-features)
    - [Drag and Drop](#drag-and-drop)
    - [Time Overlays](#time-overlays)
  - [Migrating from timetable](#migrating-from-timetable)
  - [Example and contributing](#example-and-contributing)
  - [License](#license)

## Available Layouts

### [`MultiDateTimetable`]

A Timetable widget that displays multiple consecutive days.

| Light Mode | Dark Mode |
| :---: | :---: |
| ![MultiDateTimetable-light](doc/screenshot-MultiDateTimetable-light.webp) | ![MultiDateTimetable-dark](doc/screenshot-MultiDateTimetable-dark.webp) |

### [`RecurringMultiDateTimetable`]

A Timetable widget that displays multiple consecutive days without their dates and without a week indicator. Recurrence rules and event expansion remain the responsibility of your application.

| Light Mode | Dark Mode |
| :---: | :---: |
| ![RecurringMultiDateTimetable-light](doc/screenshot-RecurringMultiDateTimetable-light.webp) | ![RecurringMultiDateTimetable-dark](doc/screenshot-RecurringMultiDateTimetable-dark.webp) |

### [`CompactMonthTimetable`]

A Timetable widget that displays [`MonthWidget`]s in a page view.

| Light Mode | Dark Mode |
| :---: | :---: |
| ![CompactMonthTimetable-light](doc/screenshot-CompactMonthTimetable-light.webp) | ![CompactMonthTimetable-dark](doc/screenshot-CompactMonthTimetable-dark.webp) |

## Getting started

Requires Flutter 3.47.0 and Dart 3.13.0 or later. Add `timetable_next` and `material_ui: ^1.8.0` to your dependencies. The examples below use these imports:

```dart
import 'package:material_ui/material_ui.dart';
import 'package:timetable_next/timetable_next.dart';
```

### 0. General Information

All supplied `DateTime`s must have `isUtc` set to `true`. Timetable displays their date and time fields without converting time zones. Convert your data to the intended display fields before passing it to Timetable.

Some date/time-related parameters also have special suffixes:

- `date`: A `DateTime` with a time of zero.
- `month`: A `DateTime` with a time of zero and a day of one.
- `timeOfDay`: A `Duration` from zero to 24 hours, inclusive.
- `dayOfWeek`: An `int` between one and seven ([`DateTime.monday`](https://api.flutter.dev/flutter/dart-core/DateTime/monday-constant.html) through [`DateTime.sunday`](https://api.flutter.dev/flutter/dart-core/DateTime/sunday-constant.html)).

Timetable provides localizations for Chinese (Simplified and Traditional), English, French, German, Hungarian, Italian, Japanese, Portuguese, and Spanish.
Add Timetable's localization delegate to your application's `localizationsDelegates`, including for English-only applications. For a Material application:

```dart
MaterialApp(
  localizationsDelegates: const [
    TimetableLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ],
  // ...
);
```

> To contribute a localization, follow the steps in [`TimetableLocalizationsDelegate`].

Set `supportedLocales` to the languages your application supports.

### 1. Define your [`Event`]s

To get you started, [`BasicEvent`] provides an ID, title and background color. You can also extend [`Event`] for your own data model.

Use the same `E extends Event` type for your timetable, providers and builders. The examples below use [`BasicEvent`].

Supply an event builder to display your events. [`BasicEventWidget`] displays a [`BasicEvent`].

Events use start-inclusive, end-exclusive spans; zero-duration events are treated as points. By default, events lasting at least 24 hours are classified as all-day events.

### 2. Create a [`DateController`] (optional)

A [`DateController`] exposes the visible dates and supports animated or immediate navigation. Configure [`VisibleDateRange`] to choose the visible day count and snapping behavior.

```dart
final myDateController = DateController(
  // All parameters are optional and displayed with their default value.
  initialDate: DateTimeTimetable.today(),
  visibleRange: VisibleDateRange.week(startOfWeek: DateTime.monday),
);
```

Here are some of the available [`VisibleDateRange`] configurations:

- [`VisibleDateRange.days`]: displays `visibleDayCount` consecutive days, snapping to every `swipeRange` days (aligned to `alignmentDate`) in the range from `minDate` to `maxDate`
- [`VisibleDateRange.week`]: displays and snaps to whole weeks with a customizable `startOfWeek` in the range from `minDate` to `maxDate`
- [`VisibleDateRange.weekAligned`]: displays `visibleDayCount` consecutive days while snapping to whole weeks with a customizable `firstDay` in the range from `minDate` to `maxDate` – can be used, e.g., to display a five-day workweek

### 3. Create a [`TimeController`] (optional)

A [`TimeController`] controls the visible time range and zoom limits in a [`MultiDateTimetable`] or [`RecurringMultiDateTimetable`]. Use it to change the visible range programmatically.

```dart
final myTimeController = TimeController(
  // All parameters are optional. By default, the whole day is revealed
  // initially and you can zoom in to view just a single minute.
  minDuration: const Duration(minutes: 15), // The closest you can zoom in.
  maxDuration: const Duration(hours: 23), // The farthest you can zoom out.
  initialRange: TimeRange(const Duration(hours: 9), const Duration(hours: 17)),
  maxRange: TimeRange(Duration.zero, const Duration(hours: 24)),
);
```

### 4. Create your Timetable widget

[`TimetableConfig<E>`] provides controllers, event builders, callbacks and styles to descendant widgets through inherited widgets:

```dart
final timetable = TimetableConfig<BasicEvent>(
  // Optional controllers created above:
  dateController: myDateController,
  timeController: myTimeController,
  // Supply a builder unless one is inherited from the widget tree.
  eventBuilder: (context, event) => BasicEventWidget(event),
  child: MultiDateTimetable<BasicEvent>(),
  // Optional; events is a List<BasicEvent> supplied by your application.
  eventProvider: eventProviderFromFixedList(events),
  allDayEventBuilder: (context, event, info) =>
      BasicAllDayEventWidget(event, info: info),
  allDayOverflowBuilder: (context, date, overflowedEvents) =>
      MultiDateEventHeaderOverflow(
        date,
        overflowCount: overflowedEvents.length,
      ),
  callbacks: const TimetableCallbacks(
    // onWeekTap, onDateTap, onDateBackgroundTap, onDateTimeBackgroundTap, and
    // onMultiDateHeaderOverflowTap
  ),
  theme: TimetableThemeData(
    context,
    // startOfWeek: DateTime.monday,
    // See the "Theming" section below for more options.
  ),
);
```

`TimetableConfig` supplies and manages default controllers when none are provided or inherited. Don't forget to dispose of controllers you create in [`State.dispose`].

An event provider receives a visible date interval and must return only intersecting events. `eventProviderFromFixedList(events)` filters a fixed list for you.

And you're done 🎉

## Theming

Timetable derives default component styles from the ambient `ThemeData`, including light and dark themes. Provide a [`TimetableThemeData`] to customize component styles.

Pass your theme to [`TimetableConfig<E>`] or [`TimetableTheme`]. Use a `BuildContext` below your application's `MaterialApp` or `Theme`:

```dart
TimetableConfig<BasicEvent>(
  theme: TimetableThemeData(
    context,
    startOfWeek: DateTime.monday,
    dateDividersStyle: DateDividersStyle(
      context,
      color: Colors.blue.withValues(alpha: .3),
      width: 2,
    ),
    dateHeaderStyleProvider: (date) =>
        DateHeaderStyle(context, date, tooltip: 'My custom tooltip'),
    nowIndicatorStyle: NowIndicatorStyle(
      context,
      lineColor: Colors.green,
      shape: TriangleNowIndicatorShape(color: Colors.green),
    ),
  ),
  eventProvider: eventProviderFromFixedList(events),
  eventBuilder: (context, event) => BasicEventWidget(event),
  child: MultiDateTimetable<BasicEvent>(),
)
```

[`TimetableThemeData`] and component styles provide two constructor forms:

- The default constructor derives values from the `BuildContext` and any date or time arguments. Named parameters override individual values.
- The `raw` constructor accepts explicit style values.

## Advanced Features

### Drag and Drop

<img src="https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-dragAndDrop.webp" width="400px" alt="Drag and Drop demo" />

Wrap an event widget in [`PartDayDraggableEvent`] to enable dragging within [`MultiDateTimetable`] or [`RecurringMultiDateTimetable`]. Here, `event` is a `BasicEvent`:

```dart
PartDayDraggableEvent(
  // The user started dragging this event.
  onDragStart: () {},
  // The event was dragged to the given [DateTime].
  onDragUpdate: (dateTime) {},
  // The drag ended at this DateTime, or null if no position was resolved.
  onDragEnd: (dateTime) {},
  child: BasicEventWidget(event),
  // By default, the child is displayed with a reduced opacity when it's
  // dragged. But, of course, you can customize this:
  childWhileDragging: const SizedBox.shrink(),
)
```

The application is responsible for drag feedback. Have a look at the example app, which displays feedback as a time overlay and snaps it to 15-minute intervals.

For widgets dragged into a timetable from outside, give the [`MultiDateContent`] a `geometryKey` (or set `MultiDateTimetable.contentGeometryKey`) and pass it to [`PartDayDraggableEvent.forGeometryKeys`].
A `geometryKey` is a [`GlobalKey`]`<`[`MultiDateContentGeometry`]`>` whose state maps global pointer offsets to [`DateTime`] values.

```dart
final geometryKey = GlobalKey<MultiDateContentGeometry>();

final timetable = MultiDateTimetable<BasicEvent>(contentGeometryKey: geometryKey);
// Or `MultiDateContent(geometryKey: geometryKey)` if you build your timetable
// from the provided, modular widgets.

final draggableEvent = PartDayDraggableEvent.forGeometryKeys(
  {geometryKey},
  child: BasicEventWidget(event),
  // `childWhileDragging` and the callbacks are available here as well.
);

// After layout, convert a global pointer offset to a DateTime:
final dateTime = geometryKey.currentState!.resolveOffset(globalOffset);
```

To drag between timetables, give each timetable a `geometryKey` and pass the keys to [`PartDayDraggableEvent.forGeometryKeys`]. The callbacks identify the timetable under the pointer. See [`PartDayDraggableEvent.geometryKeys`] for key selection behavior.

### Time Overlays

<img src="doc/screenshot-timeOverlays.webp" width="400px" alt="Time overlays" />

[`MultiDateTimetable`] and [`RecurringMultiDateTimetable`] can display overlays for time ranges independently of events. Set `timeOverlayProvider` on [`TimetableConfig<E>`], or provide a [`DefaultTimeOverlayProvider`] directly. The provider receives a `BuildContext` and a date, and returns a list of [`TimeOverlay`].

```dart
TimetableConfig<BasicEvent>(
  timeOverlayProvider: (context, date) => <TimeOverlay>[
    TimeOverlay(
      start: Duration.zero,
      end: const Duration(hours: 8),
      widget: const ColoredBox(color: Colors.black12),
      position: TimeOverlayPosition.behindEvents, // Or inFrontOfEvents.
    ),
    TimeOverlay(
      start: const Duration(hours: 20),
      end: const Duration(hours: 24),
      widget: const ColoredBox(color: Colors.black12),
    ),
  ],
  eventProvider: eventProviderFromFixedList(events),
  eventBuilder: (context, event) => BasicEventWidget(event),
  child: MultiDateTimetable<BasicEvent>(),
)
```

This example shades the time before 8 a.m. and after 8 p.m. on every day.

## Migrating from timetable

Replace the `timetable` dependency with `timetable_next` and update imports to `package:timetable_next/timetable_next.dart`. Public types and constructors retain their existing names. `package:timetable_next/timetable.dart` remains available as a compatibility entry.

Material hosts must migrate their widgets, themes and localization delegates together to `material_ui`. Follow the [official migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

See the [changelog](CHANGELOG.md) for fixes and compatibility changes.

## Example and contributing

The [example app](example/) targets Android, iOS, and Web. Its iOS project uses Swift Package Manager.

```sh
cd example
flutter pub get
flutter run
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and [QA](doc/QA.md) for verification requirements.

## License

[Apache-2.0](LICENSE). Original authorship and source history are retained; see the [independent-maintenance decision](doc/adr/0001-independent-maintenance.md) for the upstream baseline.

<!-- Flutter -->

[`DateTime`]: https://api.flutter.dev/flutter/dart-core/DateTime-class.html
[`Duration`]: https://api.flutter.dev/flutter/dart-core/Duration-class.html
[`GlobalKey`]: https://api.flutter.dev/flutter/widgets/GlobalKey-class.html
[`State.dispose`]: https://api.flutter.dev/flutter/widgets/State/dispose.html

<!-- timetable -->

[`BasicEvent`]: lib/src/event/basic.dart
[`BasicEventWidget`]: lib/src/event/basic.dart
[`CompactMonthTimetable`]: lib/src/layouts/compact_month.dart
[`DateController`]: lib/src/date/controller.dart
[`DefaultTimeOverlayProvider`]: lib/src/time/overlay.dart
[`Event`]: lib/src/event/event.dart
[`MonthWidget`]: lib/src/components/month_widget.dart
[`MultiDateContent`]: lib/src/components/multi_date_content.dart
[`MultiDateContentGeometry`]: lib/src/components/multi_date_content.dart
[`MultiDateTimetable`]: lib/src/layouts/multi_date.dart
[`PartDayDraggableEvent`]: lib/src/components/multi_date_content.dart
[`PartDayDraggableEvent.forGeometryKeys`]: lib/src/components/multi_date_content.dart
[`PartDayDraggableEvent.geometryKeys`]: lib/src/components/multi_date_content.dart
[`RecurringMultiDateTimetable`]: lib/src/layouts/recurring_multi_date.dart
[`TimeController`]: lib/src/time/controller.dart
[`TimeOverlay`]: lib/src/time/overlay.dart
[`TimetableConfig<E>`]: lib/src/config.dart
[`TimetableLocalizationsDelegate`]: lib/src/localization.dart
[`TimetableTheme`]: lib/src/theme.dart
[`TimetableThemeData`]: lib/src/theme.dart
[`VisibleDateRange`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.days`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.week`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.weekAligned`]: lib/src/date/visible_date_range.dart
