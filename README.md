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

Add `timetable_next` to your dependencies. The examples below use these imports:

```dart
import 'package:flutter/material.dart';
import 'package:timetable_next/timetable_next.dart';
```

### 0. General Information

All supplied `DateTime`s must have `isUtc` set to `true`. Timetable displays their date and time fields without converting time zones. Convert your data to the intended display fields before passing it to Timetable.

Some date/time-related parameters also have special suffixes:

- `date`: A `DateTime` with a time of zero.
- `month`: A `DateTime` with a time of zero and a day of one.
- `timeOfDay`: A `Duration` from zero to 24 hours, inclusive.
- `dayOfWeek`: An `int` between one and seven ([`DateTime.monday`](https://api.flutter.dev/flutter/dart-core/DateTime/monday-constant.html) through [`DateTime.sunday`](https://api.flutter.dev/flutter/dart-core/DateTime/sunday-constant.html)).

Timetable currently offers localizations for Chinese (Simplified and Traditional), English, French, German, Hungarian, Italian, Japanese, Portuguese, and Spanish.
Even if you're just supporting English in your app, you have to add Timetable's localization delegate to your `MaterialApp`/`CupertinoApp`/`WidgetsApp`:

```dart
MaterialApp(
  localizationsDelegates: [
    const TimetableLocalizationsDelegate(),
    // Other delegates, e.g., `GlobalMaterialLocalizations.delegate`
  ],
  // ...
);
```

> To contribute a localization, follow the steps in [`TimetableLocalizationsDelegate`].

Configure `supportedLocales` and Flutter's localization delegates when localizing the surrounding application.

### 1. Define your [`Event`]s

Events are provided as instances of [`Event`].
To get you started, there's the subclass [`BasicEvent`], which you can instantiate directly.
If you want to be more specific, you can also implement your own class extending [`Event`].

> ⚠️ Most of Timetable's classes accept a type-parameter `E extends Event`.
> Please set it to your chosen [`Event`]-subclass (e.g., [`BasicEvent`]) to avoid runtime exceptions.

In addition, you also need a `Widget` to display your events.
When using [`BasicEvent`], this can simply be [`BasicEventWidget`].

Events use start-inclusive, end-exclusive spans; zero-duration events are treated as points. Events lasting at least 24 hours are classified as all-day events.

### 2. Create a [`DateController`] (optional)

Similar to a [`ScrollController`] or a [`TabController`], a [`DateController`] is responsible for interacting with Timetable's widgets and managing their state.
As the name suggests, you can use a [`DateController`] to access the currently visible dates, and also animate or jump to different days.
And by supplying a [`VisibleDateRange`], you can also customize how many days are visible at once and whether they, e.g., snap to weeks.

```dart
final myDateController = DateController(
  // All parameters are optional and displayed with their default value.
  initialDate: DateTimeTimetable.today(),
  visibleRange: VisibleDateRange.week(startOfWeek: DateTime.monday),
);
```

> Don't forget to [`dispose`][`DateController.dispose`] your controller, e.g., in [`State.dispose`]!

Here are some of the available [`VisibleDateRange`]s:

- [`VisibleDateRange.days`]: displays `visibleDayCount` consecutive days, snapping to every `swipeRange` days (aligned to `alignmentDate`) in the range from `minDate` to `maxDate`
- [`VisibleDateRange.week`]: displays and snaps to whole weeks with a customizable `startOfWeek` in the range from `minDate` to `maxDate`
- [`VisibleDateRange.weekAligned`]: displays `visibleDayCount` consecutive days while snapping to whole weeks with a customizable `firstDay` in the range from `minDate` to `maxDate` – can be used, e.g., to display a five-day workweek

### 3. Create a [`TimeController`] (optional)

Similar to the [`DateController`] above, a [`TimeController`] is also responsible for interacting with Timetable's widgets and managing their state.
More specifically, it controls the visible time range and zoom factor in a [`MultiDateTimetable`] or [`RecurringMultiDateTimetable`].
You can also programmatically change those and, e.g., animate out to reveal the full day.

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

> Don't forget to [`dispose`][`TimeController.dispose`] your controller, e.g., in [`State.dispose`]!

### 4. Create your Timetable widget

The configuration for Timetable's widgets is provided via inherited widgets.
You can use a [`TimetableConfig<E>`] to provide all at once:

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

`TimetableConfig` supplies default controllers when none are provided or inherited. Dispose of controllers you create; Timetable manages its own default controllers.

An event provider receives a visible date interval and must return only intersecting events. `eventProviderFromFixedList(events)` filters a fixed list for you.

And you're done 🎉

## Theming

Timetable already supports light and dark themes out of the box, adapting to the ambient `ThemeData`.
You can, however, customize the styles of almost all components by providing a custom [`TimetableThemeData`].

To apply your own theme, specify it in the [`TimetableConfig<E>`] (or directly in a [`TimetableTheme`]). Use a `BuildContext` below your application's `MaterialApp` or `Theme`:

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

> [`TimetableThemeData`] and component styles provide constructors for different use cases:
>
> - The default constructor takes a `BuildContext` and sometimes a day or month, using information from the ambient theme and locale to generate default values.
>   You can still override all options via optional, named parameters.
> - The named `raw` constructor accepts explicit style values instead of deriving them from the context.

## Advanced Features

### Drag and Drop

<img src="https://raw.githubusercontent.com/JonasWanke/timetable/23b4d1b622a8f3b39f3038e218cb780c66f30bd5/doc/demo-dragAndDrop.webp" width="400px" alt="Drag and Drop demo" />

You can easily make events inside the content area of [`MultiDateTimetable`] or [`RecurringMultiDateTimetable`] draggable by wrapping them in a [`PartDayDraggableEvent`]. Here, `event` is a `BasicEvent`:

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

Timetable doesn't automatically show a moving feedback widget at the current pointer position.
Instead, you can customize this and, e.g., snap event starts to multiples of 15 minutes.
Have a look at the included example app where we implemented exactly that by displaying the drag feedback as a time overlay.

For widgets dragged into a timetable from outside, give the [`MultiDateContent`] a `geometryKey` (or set `MultiDateTimetable.contentGeometryKey`) and pass it to [`PartDayDraggableEvent.forGeometryKeys`].
A `geometryKey` is a [`GlobalKey`]`<`[`MultiDateContentGeometry`]`>` with which the current drag offset can be converted to a [`DateTime`].

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

You could even offer to drag the event into one of multiple timetables:
Give each timetable its own `geometryKey` and pass all of them to [`PartDayDraggableEvent.forGeometryKeys`].
In the callbacks, you receive the `geometryKey` of the timetable that the event is currently being dragged over.
See [`PartDayDraggableEvent.geometryKeys`] for the exact behavior.

### Time Overlays

<img src="doc/screenshot-timeOverlays.webp" width="400px" alt="Time overlays" />

In addition to displaying events, [`MultiDateTimetable`] and [`RecurringMultiDateTimetable`] can display overlays for time ranges on every day.
In the screenshot above, a light gray overlay is displayed on weekdays before 8 a.m. and after 8 p.m., and over the full day for weekends.
Time overlays are provided similarly to events: Just add a `timeOverlayProvider` to your [`TimetableConfig<E>`] (or use a [`DefaultTimeOverlayProvider`] directly).

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

The provider receives a `BuildContext` and a date, and returns a list of [`TimeOverlay`] for that date.
The example above therefore draws a light gray background before 8 a.m. and after 8 p.m. on every day.

## Migrating from timetable

Replace the `timetable` dependency with `timetable_next` and update imports to `package:timetable_next/timetable_next.dart`. Public types and constructors retain their existing names. `package:timetable_next/timetable.dart` remains available as a compatibility entry.

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
[`ScrollController`]: https://api.flutter.dev/flutter/widgets/ScrollController-class.html
[`State.dispose`]: https://api.flutter.dev/flutter/widgets/State/dispose.html
[`TabController`]: https://api.flutter.dev/flutter/material/TabController-class.html

<!-- timetable -->

[`BasicEvent`]: lib/src/event/basic.dart
[`BasicEventWidget`]: lib/src/event/basic.dart
[`CompactMonthTimetable`]: lib/src/layouts/compact_month.dart
[`DateController`]: lib/src/date/controller.dart
[`DateController.dispose`]: lib/src/date/controller.dart
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
[`TimeController.dispose`]: lib/src/time/controller.dart
[`TimeOverlay`]: lib/src/time/overlay.dart
[`TimetableConfig<E>`]: lib/src/config.dart
[`TimetableLocalizationsDelegate`]: lib/src/localization.dart
[`TimetableTheme`]: lib/src/theme.dart
[`TimetableThemeData`]: lib/src/theme.dart
[`VisibleDateRange`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.days`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.week`]: lib/src/date/visible_date_range.dart
[`VisibleDateRange.weekAligned`]: lib/src/date/visible_date_range.dart
