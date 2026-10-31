import 'package:dart_date/dart_date.dart' show Interval;
import 'package:flutter/material.dart' hide Interval;
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable.dart' as compatibility;
import 'package:timetable_next/timetable_next.dart';

void main() {
  testWidgets('published contents retain public entries and render events', (
    tester,
  ) async {
    final date = DateTime.utc(2024, 2, 26);
    final controller = DateController(initialDate: date);
    final time = TimeController();
    final event = BasicEvent(
      id: 'consumer',
      title: 'Published package',
      backgroundColor: Colors.blue,
      start: date.add(const Duration(hours: 9)),
      end: date.add(const Duration(hours: 10)),
    );
    final provider = eventProviderFromFixedList([event]);
    expect(provider(Interval(date, date.add(const Duration(days: 1)))), [
      event,
    ]);
    expect(controller, isA<compatibility.DateController>());
    expect(event, isA<compatibility.BasicEvent>());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: Scaffold(
          body: TimetableConfig<BasicEvent>(
            dateController: controller,
            timeController: time,
            eventProvider: provider,
            eventBuilder: (context, value) => BasicEventWidget(value),
            allDayEventBuilder: (context, value, info) =>
                BasicAllDayEventWidget(value, info: info),
            child: MultiDateTimetable<BasicEvent>(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Published package'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    time.dispose();
    expect(tester.takeException(), isNull);
  });
}
