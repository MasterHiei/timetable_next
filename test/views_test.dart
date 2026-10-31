import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

// Shared with example integration; VM tests can resolve this repository path.
// ignore: avoid_relative_lib_imports
import '../example/lib/qa_fixture.dart';

void main() {
  // Eight pairwise cases cover all pairs of size, locale, theme and text scale.
  const configurations = [
    (Size(320, 640), Locale('en'), Brightness.light, 1.0),
    (Size(320, 640), Locale('en'), Brightness.dark, 2.0),
    (Size(320, 640), Locale('zh', 'CN'), Brightness.light, 2.0),
    (Size(320, 640), Locale('zh', 'CN'), Brightness.dark, 1.0),
    (Size(800, 600), Locale('en'), Brightness.light, 2.0),
    (Size(800, 600), Locale('en'), Brightness.dark, 1.0),
    (Size(800, 600), Locale('zh', 'CN'), Brightness.light, 1.0),
    (Size(800, 600), Locale('zh', 'CN'), Brightness.dark, 2.0),
  ];
  for (final layout in FixtureLayout.values) {
    for (final (size, locale, brightness, scale) in configurations) {
      testWidgets('$layout $size $locale $brightness scale=$scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          TimetableFixture(
            layout: layout,
            locale: locale,
            brightness: brightness,
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (layout == FixtureLayout.month) {
          expect(
            tester.widget<MonthWidget>(find.byType(MonthWidget).first).month,
            DateTime.utc(2024, 2),
          );
        } else {
          expect(find.byKey(const ValueKey('all-day')), findsOneWidget);
          expect(find.byKey(const ValueKey('single')), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('$layout empty view', (tester) async {
      await tester.pumpWidget(TimetableFixture(layout: layout, empty: true));
      await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(
      key.currentState!.date.date.value,
      fixtureDate.add(const Duration(days: 3)),
    );
    expect(find.byKey(const ValueKey('single')), findsNothing);
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
