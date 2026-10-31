import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

Widget _app(
  Widget child,
  DateController date,
  TimeController time, {
  List<BasicEvent> events = const [],
  TimetableCallbacks? callbacks,
}) => MaterialApp(
  localizationsDelegates: const [TimetableLocalizationsDelegate()],
  home: Scaffold(
    body: TimetableConfig<BasicEvent>(
      dateController: date,
      timeController: time,
      eventProvider: eventProviderFromFixedList(events),
      callbacks: callbacks,
      eventBuilder: (_, event) => BasicEventWidget(event),
      allDayEventBuilder: (_, event, info) =>
          BasicAllDayEventWidget(event, info: info),
      child: child,
    ),
  ),
);

void main() {
  testWidgets(
    'all-day overflow, changing row limits and background taps retain dates',
    (tester) async {
      final day = DateTime.utc(2024, 2, 26);
      final date = DateController(
        initialDate: day,
        visibleRange: VisibleDateRange.days(3, alignmentDate: day),
      );
      final time = TimeController();
      final events = [
        for (var i = 0; i < 4; i++)
          BasicEvent(
            id: i,
            title: 'event $i',
            backgroundColor: Colors.blue,
            start: day,
            end: day.add(const Duration(days: 1)),
          ),
      ];
      DateTime? overflowDate;
      DateTime? backgroundDate;
      Widget view(int rows, {double height = 120}) => _app(
        SizedBox(
          width: 600,
          height: height,
          child: MultiDateEventHeader<BasicEvent>(
            style: MultiDateEventHeaderStyle.raw(maxEventRows: rows),
          ),
        ),
        date,
        time,
        events: events,
        callbacks: TimetableCallbacks(
          onMultiDateHeaderOverflowTap: (value) => overflowDate = value,
          onDateBackgroundTap: (value) => backgroundDate = value,
        ),
      );
      await tester.pumpWidget(view(1));
      await tester.pumpAndSettle();
      expect(find.text('+3'), findsOneWidget);
      await tester.tap(find.text('+3'));
      expect(overflowDate, day);
      await tester.tapAt(const Offset(300, 10));
      expect(backgroundDate, day.add(const Duration(days: 1)));
      await tester.pumpWidget(view(4));
      await tester.pumpAndSettle();
      expect(find.byType(MultiDateEventHeaderOverflow), findsNothing);
      for (var i = 0; i < 4; i++) {
        expect(find.text('event $i'), findsOneWidget);
      }
      await tester.pumpWidget(view(0));
      await tester.pumpAndSettle();
      expect(find.text('+4'), findsOneWidget);
      await tester.pumpWidget(view(1, height: 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MultiDateEventHeader<BasicEvent>)).height,
        0,
      );
      date.jumpTo(day.add(const Duration(days: 4)));
      await tester.pumpAndSettle();
      expect(find.byType(MultiDateEventHeaderOverflow), findsNothing);
      await tester.pumpWidget(const SizedBox());
      date.dispose();
      time.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
