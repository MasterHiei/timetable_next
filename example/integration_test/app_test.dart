import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timetable_next/timetable_next.dart';
import 'package:timetable_next_example/qa_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final layout in FixtureLayout.values) {
    testWidgets('$layout launches, renders and navigates', (tester) async {
      Object? tapped;
      DateTime? dropped;
      final key = GlobalKey<TimetableFixtureState>();
      await tester.pumpWidget(
        TimetableFixture(
          key: key,
          layout: layout,
          onTap: (id) => tapped = id,
          onDrag: (date) => dropped = date,
        ),
      );
      await tester.pumpAndSettle();
      if (layout != FixtureLayout.month) {
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
          reason: 'expected=$expectedDrop actual=$dropped',
        );
        final beforeZoom = tester.getTopLeft(single).dy;
        key.currentState!.time.jumpToShowFullDay();
        await tester.pumpAndSettle();
        expect(key.currentState!.time.value.duration, const Duration(days: 1));
        expect(tester.getTopLeft(single).dy, greaterThan(beforeZoom));
      }
      if (layout != FixtureLayout.recurring) {
        key.currentState!.date.jumpTo(fixtureDate.add(const Duration(days: 7)));
        await tester.pumpAndSettle();
        expect(
          key.currentState!.date.date.value,
          fixtureDate.add(const Duration(days: 7)),
        );
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
