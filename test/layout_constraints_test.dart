import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/src/utils/size_reporting_widget.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  testWidgets('measured height respects a bounded parent', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: ImmediateSizedBox(
              heightGetter: () => 200,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ImmediateSizedBox)),
      const Size(200, 100),
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, minWidth, maxWidth, childWidth, expectedWidth) in [
    ('tight', 30.0, 30.0, 29.9, 30.0),
    ('tight empty', 30.0, 30.0, null, 30.0),
    ('positive minimum', 30.0, 60.0, 10.0, 30.0),
    ('natural width', 0.0, 60.0, 10.0, 10.0),
    ('loose empty', 0.0, 60.0, null, 0.0),
    ('maximum', 0.0, 60.0, 80.0, 60.0),
    ('unbounded width', 0.0, double.infinity, 10.0, 10.0),
  ]) {
    testWidgets('time indicators respect $name width constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                maxWidth: maxWidth,
                minHeight: 100,
                maxHeight: 100,
              ),
              child: TimeIndicators(
                children: [
                  if (childWidth != null)
                    TimeIndicatorsChild(
                      time: const Duration(hours: 12),
                      child: SizedBox(width: childWidth, height: 10),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TimeIndicators)),
        Size(expectedWidth, 100),
      );
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('time indicator offsets and hits follow $direction', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Center(
              child: SizedBox(
                width: 30,
                height: 100,
                child: TimeIndicators(
                  children: [
                    for (final (hour, y) in [(0, 1.0), (12, 0.0), (24, -1.0)])
                      TimeIndicatorsChild(
                        time: Duration(hours: hour),
                        alignment: AlignmentDirectional(1, y),
                        child: GestureDetector(
                          key: ValueKey(hour),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                          child: const SizedBox(width: 10, height: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final origin = tester.getTopLeft(find.byType(TimeIndicators));
      final x = direction == TextDirection.ltr ? 20.0 : 0.0;
      for (final (hour, y) in [(0, 0.0), (12, 45.0), (24, 90.0)]) {
        expect(
          tester.getTopLeft(find.byKey(ValueKey(hour))) - origin,
          Offset(x, y),
        );
      }
      await tester.tapAt(origin + Offset(x + 5, 50));
      expect(taps, 1);
      await tester.tapAt(origin + Offset(x == 0 ? 25 : 5, 50));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fixed time column respects its width through time zoom', (
    tester,
  ) async {
    final time = TimeController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      time.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 46,
            height: 100,
            child: DefaultTimeController(
              controller: time,
              child: TimeZoom(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TimeIndicators.hours(
                    firstHour: 0,
                    lastHour: 24,
                    alignFirstAndLastLabelsInside: true,
                    styleProvider: (_) => const TimeIndicatorStyle.raw(
                      textStyle: TextStyle(fontSize: 10),
                      label: '00',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TimeZoom)), const Size(46, 100));
    expect(tester.getSize(find.byType(TimeIndicators)), const Size(30, 100));
    expect(find.byType(TimeIndicator), findsNWidgets(25));

    final range = TimeRange(
      const Duration(hours: 6),
      const Duration(hours: 18),
    );
    time.value = range;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(time.value, range);
    expect(tester.getSize(find.byType(TimeZoom)), const Size(46, 100));
    expect(tester.getSize(find.byType(TimeIndicators)), const Size(30, 200));
  });
}
