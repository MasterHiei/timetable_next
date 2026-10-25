import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timetable_next/timetable_next.dart';

enum FixtureLayout { multi, recurring, month }

final fixtureDate = DateTime.utc(2024, 2, 26);

class TimetableFixture extends StatefulWidget {
  const TimetableFixture({
    super.key,
    this.layout = FixtureLayout.multi,
    this.locale = const Locale('en'),
    this.brightness = Brightness.light,
    this.scale = 1,
    this.empty = false,
    this.initialDate,
    this.onTap,
    this.onDrag,
  });
  final DateTime? initialDate;
  final FixtureLayout layout;
  final Locale locale;
  final Brightness brightness;
  final double scale;
  final bool empty;
  final ValueChanged<Object>? onTap;
  final ValueChanged<DateTime?>? onDrag;
  @override
  State<TimetableFixture> createState() => TimetableFixtureState();
}

class TimetableFixtureState extends State<TimetableFixture> {
  late final baseDate = widget.initialDate ?? fixtureDate;
  late final date = DateController(
    initialDate: baseDate,
    visibleRange: widget.layout == FixtureLayout.recurring
        ? VisibleDateRange.fixed(baseDate, 3)
        : VisibleDateRange.days(3),
  );
  final time = TimeController(
    initialRange: TimeRange(
      const Duration(hours: 8),
      const Duration(hours: 18),
    ),
  );
  late final events = [
    _event('single', 9, 10),
    _event('overlap', 9, 11, minute: 30),
    BasicEvent(
      id: 'cross',
      title: 'cross',
      backgroundColor: Colors.green,
      start: baseDate.subtract(const Duration(hours: 1)),
      end: baseDate.add(const Duration(hours: 9)),
    ),
    BasicEvent(
      id: 'all-day',
      title: 'all-day',
      backgroundColor: Colors.orange,
      start: baseDate,
      end: baseDate.add(const Duration(days: 1)),
    ),
  ];
  BasicEvent _event(String id, int start, int end, {int minute = 0}) =>
      BasicEvent(
        id: id,
        title: id,
        backgroundColor: Colors.blue,
        start: baseDate.add(Duration(hours: start, minutes: minute)),
        end: baseDate.add(Duration(hours: end, minutes: minute)),
      );
  @override
  void dispose() {
    date.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: widget.locale,
    localizationsDelegates: const [
      TimetableLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: const [Locale('en'), Locale('zh', 'CN')],
    theme: ThemeData(brightness: widget.brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.scale)),
      child: child!,
    ),
    home: Scaffold(
      body: TimetableConfig<BasicEvent>(
        dateController: date,
        timeController: time,
        eventProvider: eventProviderFromFixedList(widget.empty ? [] : events),
        eventBuilder: (context, event) => PartDayDraggableEvent(
          onDragEnd: widget.onDrag,
          child: GestureDetector(
            key: ValueKey(event.id.toString()),
            onTap: () => widget.onTap?.call(event.id),
            child: BasicEventWidget(event),
          ),
        ),
        allDayEventBuilder: (context, event, info) => GestureDetector(
          key: ValueKey(event.id.toString()),
          onTap: () => widget.onTap?.call(event.id),
          child: BasicAllDayEventWidget(event, info: info),
        ),
        child: switch (widget.layout) {
          FixtureLayout.multi => MultiDateTimetable<BasicEvent>(),
          FixtureLayout.recurring => RecurringMultiDateTimetable<BasicEvent>(),
          FixtureLayout.month => SingleChildScrollView(
            child: CompactMonthTimetable(),
          ),
        },
      ),
    ),
  );
}
