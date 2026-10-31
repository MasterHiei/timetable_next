import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  testWidgets('style copies are immutable values and overrides reach widgets', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final date = DateTime.utc(2024, 2, 26);
    const text = TextStyle(fontSize: 17, color: Colors.purple);
    const padding = EdgeInsets.all(3);
    const decoration = BoxDecoration(color: Colors.green);
    final dateStyle = DateIndicatorStyle(context, date);
    final weekday = WeekdayIndicatorStyle(context, date);
    final time = TimeIndicatorStyle(context, const Duration(hours: 9));
    final month = MonthIndicatorStyle(context, DateTime.utc(2024, 2));
    final week = WeekIndicatorStyle(context, const Week(2024, 9));
    final header = DateHeaderStyle(context, date);
    final events = DateEventsStyle(context, date);
    final monthWidget = MonthWidgetStyle(context, DateTime.utc(2024, 2));
    final dateDividers = DateDividersStyle(context);
    final hourDividers = HourDividersStyle(context);
    final eventHeader = MultiDateEventHeaderStyle(context);
    final layout = MultiDateTimetableStyle(context);
    final now = NowIndicatorStyle(context);
    final basicEvent = BasicEvent(
      id: 1,
      title: 'value',
      backgroundColor: Colors.blue,
      start: date,
      end: date.add(const Duration(days: 1)),
    );
    final basic = BasicAllDayEventWidgetStyle(context, basicEvent);
    final changedDate = dateStyle.copyWith(
      decoration: decoration,
      padding: padding,
      textStyle: text,
      label: 'custom date',
    );
    final changedWeekday = weekday.copyWith(
      decoration: decoration,
      padding: padding,
      textStyle: text,
      label: 'custom weekday',
    );
    final changedTime = time.copyWith(textStyle: text, label: 'custom time');
    final changedMonth = month.copyWith(textStyle: text, label: 'custom month');
    final changedWeek = week.copyWith(
      tooltip: 'custom week',
      decoration: decoration,
      padding: padding,
      textStyle: text,
      labels: ['wide label', 'W9'],
    );
    for (final (original, copied, changed) in <(Object, Object, Object)>[
      (dateStyle, dateStyle.copyWith(), changedDate),
      (weekday, weekday.copyWith(), changedWeekday),
      (time, time.copyWith(), changedTime),
      (month, month.copyWith(), changedMonth),
      (week, week.copyWith(), changedWeek),
      (
        header,
        header.copyWith(),
        header.copyWith(
          tooltip: 'other',
          padding: padding,
          showWeekdayIndicator: !header.showWeekdayIndicator,
          indicatorSpacing: 8,
          showDateIndicator: !header.showDateIndicator,
        ),
      ),
      (
        events,
        events.copyWith(),
        events.copyWith(
          minEventDuration: const Duration(minutes: 17),
          minEventHeight: 29,
          padding: padding,
          enableStacking: !events.enableStacking,
          minEventDeltaForStacking: const Duration(minutes: 2),
          stackedEventSpacing: 7,
        ),
      ),
      (
        monthWidget,
        monthWidget.copyWith(),
        monthWidget.copyWith(
          startOfWeek: DateTime.sunday,
          weeksDecoration: decoration,
          weeksPadding: padding,
          removeIndividualWeekDecorations:
              !monthWidget.removeIndividualWeekDecorations,
          datePadding: padding,
          showDatesFromOtherMonths: !monthWidget.showDatesFromOtherMonths,
          showDatesFromOtherMonthsAsDisabled:
              !monthWidget.showDatesFromOtherMonthsAsDisabled,
        ),
      ),
      (
        dateDividers,
        dateDividers.copyWith(),
        dateDividers.copyWith(color: Colors.green, width: 3),
      ),
      (
        hourDividers,
        hourDividers.copyWith(),
        hourDividers.copyWith(color: Colors.green, width: 3),
      ),
      (
        eventHeader,
        eventHeader.copyWith(),
        eventHeader.copyWith(
          eventHeight: 30,
          maxEventRows: 4,
          padding: padding,
        ),
      ),
      (layout, layout.copyWith(), layout.copyWith(maxHeaderFraction: 0.4)),
      (
        now,
        now.copyWith(),
        now.copyWith(
          shape: const EmptyNowIndicatorShape(),
          lineColor: Colors.green,
          lineWidth: 3,
        ),
      ),
      (
        basic,
        basic.copyWith(),
        basic.copyWith(
          margin: padding,
          radii: const AllDayEventBorderRadii(
            cornerRadius: BorderRadius.zero,
            leftTipRadius: 2,
            rightTipRadius: 2,
          ),
          padding: padding,
          textStyle: text,
        ),
      ),
    ]) {
      expect(copied, original);
      expect(copied.hashCode, original.hashCode);
      expect(changed, isNot(original));
    }
    expect(changedDate.padding, padding);
    expect(changedWeek.labels, ['wide label', 'W9']);
    final eventCopy = basicEvent.copyWith();
    expect(identical(eventCopy, basicEvent), isFalse);
    expect(
      (
        eventCopy.id,
        eventCopy.title,
        eventCopy.backgroundColor,
        eventCopy.start,
        eventCopy.end,
      ),
      (1, 'value', Colors.blue, date, date.add(const Duration(days: 1))),
    );
    expect(
      basicEvent
          .copyWith(
            id: 2,
            title: 'other',
            backgroundColor: Colors.red,
            start: date.add(const Duration(hours: 1)),
            end: date.add(const Duration(days: 2)),
          )
          .title,
      'other',
    );

    final theme = TimetableThemeData(context);
    expect(theme.copyWith(), theme);
    expect(theme.copyWith().hashCode, theme.hashCode);
    final custom = theme.copyWith(
      startOfWeek: DateTime.sunday,
      dateDividersStyle: dateDividers,
      dateEventsStyleProvider: (_) => events,
      dateHeaderStyleProvider: (_) => header,
      dateIndicatorStyleProvider: (_) => changedDate,
      hourDividersStyle: hourDividers,
      monthIndicatorStyleProvider: (_) => changedMonth,
      monthWidgetStyleProvider: (_) => monthWidget,
      multiDateEventHeaderStyle: eventHeader,
      multiDateTimetableStyle: layout,
      nowIndicatorStyle: now,
      timeIndicatorStyleProvider: (_) => changedTime,
      weekdayIndicatorStyleProvider: (_) => changedWeekday,
      weekIndicatorStyleProvider: (_) => changedWeek,
    );
    expect(custom, isNot(theme));
    expect(custom.startOfWeek, DateTime.sunday);
    expect(theme.startOfWeek, DateTime.monday);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimetableTheme(
            data: custom,
            child: Column(
              children: [
                DateIndicator(date),
                WeekdayIndicator(date),
                TimeIndicator(time: const Duration(hours: 9)),
                MonthIndicator(DateTime.utc(2024, 2)),
              ],
            ),
          ),
        ),
      ),
    );
    for (final label in [
      'custom date',
      'custom weekday',
      'custom time',
      'custom month',
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style, text);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'month controller binding follows replacement and month changes',
    (tester) async {
      final first = DateController(initialDate: DateTime.utc(2024, 2, 26));
      final second = DateController(initialDate: DateTime.utc(2024, 4));
      Widget build(DateController controller) => MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: Scaffold(body: MonthIndicator.forController(controller)),
      );
      await tester.pumpWidget(build(first));
      expect(find.text('February'), findsOneWidget);
      first.jumpTo(DateTime.utc(2024, 3, 4));
      await tester.pump();
      expect(find.text('March'), findsOneWidget);
      await tester.pumpWidget(build(second));
      expect(find.text('April'), findsOneWidget);
      first.jumpTo(DateTime.utc(2024, 5, 6));
      await tester.pump();
      expect(find.text('April'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      second.dispose();
    },
  );

  testWidgets('24-hour labels and style overrides preserve explicit input', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    const time = Duration(hours: 13, minutes: 5, seconds: 6);
    expect(TimeIndicator.formatHour(time), '1 PM');
    expect(TimeIndicator.formatHourMinute(time), '1:05 PM');
    expect(TimeIndicator.formatHourMinuteSecond(time), '1:05:06 PM');
    expect(TimeIndicator.formatHour24(time), '13');
    expect(TimeIndicator.formatHour24Minute(time), '13:05');
    expect(TimeIndicator.formatHour24MinuteSecond(time), '13:05:06');
    expect(
      TimeIndicatorStyle(context, time, alwaysUse24HourFormat: true).label,
      '13',
    );
    expect(
      TimeIndicatorStyle(
        context,
        time,
        label: 'explicit',
        textStyle: const TextStyle(),
      ).label,
      'explicit',
    );
  });
}
