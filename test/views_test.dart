import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

// Shared with browser integration; the nested example is not a root dependency.
// ignore: avoid_relative_lib_imports
import '../example/lib/qa_fixture.dart';

void main() {
  for (final layout in FixtureLayout.values) {
    for (final size in [const Size(320, 640), const Size(800, 600)]) {
      for (final locale in [const Locale('en'), const Locale('zh', 'CN')]) {
        for (final brightness in Brightness.values) {
          for (final scale in [1.0, 2.0]) {
            testWidgets('$layout $size $locale $brightness scale=$scale', (
              tester,
            ) async {
              await tester.binding.setSurfaceSize(size);
              await tester.pumpWidget(
                TimetableFixture(
                  layout: layout,
                  locale: locale,
                  brightness: brightness,
                  scale: scale,
                ),
              );
              await tester.pump();
              await tester.pump();
              await tester.pump();
              expect(tester.takeException(), isNull);
              if (layout == FixtureLayout.month) {
                expect(
                  tester
                      .widget<MonthWidget>(find.byType(MonthWidget).first)
                      .month,
                  DateTime.utc(2024, 2),
                );
              }
              if (layout != FixtureLayout.month) {
                expect(find.byKey(const ValueKey('all-day')), findsOneWidget);
                expect(find.byKey(const ValueKey('single')), findsOneWidget);
              }
              await tester.pumpWidget(const SizedBox());
              await tester.pump();
              await tester.pump();
              await tester.pump();
              expect(tester.takeException(), isNull);
              await tester.binding.setSurfaceSize(null);
            });
          }
        }
      }
    }
    testWidgets('$layout empty view', (tester) async {
      await tester.pumpWidget(TimetableFixture(layout: layout, empty: true));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('single')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('event taps, drag coordinates, navigation and time zoom', (
    tester,
  ) async {
    Object? tapped;
    DateTime? dropped;
    final key = GlobalKey<TimetableFixtureState>();
    await tester.pumpWidget(
      TimetableFixture(
        key: key,
        onTap: (id) => tapped = id,
        onDrag: (date) => dropped = date,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final single = find.byKey(const ValueKey('single'));
    final viewportHeight = tester
        .getSize(
          find.ancestor(of: single, matching: find.byType(TimeZoom)).first,
        )
        .height;
    final expectedDrop = fixtureDate.add(
      Duration(
        hours: 9,
        microseconds:
            (60 / viewportHeight * const Duration(hours: 10).inMicroseconds)
                .round(),
      ),
    );
    final start = tester.getTopLeft(single) + const Offset(8, 8);
    await tester.tapAt(start);
    expect(tapped, 'single');
    final drag = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(0, 60));
    await tester.pump();
    await drag.up();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(dropped, isNotNull);
    expect(dropped!.isUtc, isTrue);
    expect(
      dropped!.difference(expectedDrop).inMicroseconds.abs(),
      lessThanOrEqualTo(2000),
      reason:
          'Only millisecond geometry quantization is allowed; expected=$expectedDrop actual=$dropped',
    );
    final beforeZoom = tester.getTopLeft(single).dy;
    key.currentState!.time.jumpToShowFullDay();
    await tester.pump();
    expect(key.currentState!.time.value.duration, const Duration(days: 1));
    expect(tester.getTopLeft(single).dy, greaterThan(beforeZoom));
    key.currentState!.date.jumpTo(fixtureDate.add(const Duration(days: 3)));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(
      key.currentState!.date.date.value,
      fixtureDate.add(const Duration(days: 3)),
    );
    key.currentState!.time.jumpToShowFullDay();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(key.currentState!.time.value.duration, const Duration(days: 1));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets('today indicator releases scheduled work on unmount', (
    tester,
  ) async {
    await tester.pumpWidget(
      TimetableFixture(initialDate: DateTimeTimetable.today()),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
