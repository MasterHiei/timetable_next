import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timetable_next/timetable_next.dart';
import 'package:timetable_next_example/qa_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final layout in FixtureLayout.values) {
    testWidgets('$layout renders and responds to gestures', (tester) async {
      Object? tapped;
      DateTime? dropped;
      var drops = 0;
      final key = GlobalKey<TimetableFixtureState>();
      await tester.pumpWidget(
        TimetableFixture(
          key: key,
          layout: layout,
          onTap: (id) => tapped = id,
          onDrag: (date) {
            dropped = date;
            drops++;
          },
        ),
      );
      await tester.pumpAndSettle();
      if (layout == FixtureLayout.month) {
        final months = find.byType(MonthWidget).hitTestable();
        expect(
          tester.widget<MonthWidget>(months.first).month,
          DateTime.utc(2024, 2),
        );
        final pager = find.byType(MonthPageView);
        await tester.drag(pager, Offset(-tester.getSize(pager).width, 0));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MonthWidget>(months.first).month,
          DateTime.utc(2024, 3),
        );
      } else {
        final single = find.byKey(const ValueKey('single'));
        expect(single, findsOneWidget);
        expect(find.byKey(const ValueKey('all-day')), findsOneWidget);
        final start = tester.getTopLeft(single) + const Offset(8, 8);
        await tester.tapAt(start);
        expect(tapped, 'single');
        final drag = await tester.startGesture(start);
        await tester.pump(kLongPressTimeout);
        await drag.moveBy(const Offset(0, 60));
        await tester.pump();
        await drag.up();
        await tester.pumpAndSettle();
        expect(drops, 1);
        expect(dropped, isNotNull);
        expect(dropped!.isUtc, isTrue);
        expect(
          dropped!.isAfter(fixtureDate.add(const Duration(hours: 9))),
          isTrue,
        );

        final zoom = find.byType(TimeZoom).last;
        final before = key.currentState!.time.value.duration;
        final center = tester.getCenter(zoom);
        final first = await tester.startGesture(
          center - const Offset(0, 40),
          pointer: 1,
        );
        final second = await tester.startGesture(
          center + const Offset(0, 40),
          pointer: 2,
        );
        await first.moveTo(center - const Offset(0, 80));
        await second.moveTo(center + const Offset(0, 80));
        await tester.pump();
        expect(key.currentState!.time.value.duration, lessThan(before));
        await second.up();
        await first.up();
        await tester.pumpAndSettle();

        if (layout == FixtureLayout.multi) {
          final pages = find.byType(DatePageView).last;
          await tester.drag(pages, Offset(-tester.getSize(pages).width, 0));
          await tester.pumpAndSettle();
          expect(single, findsNothing);
          final visibleDate = tester
              .widget<DateIndicator>(
                find.byType(DateIndicator).hitTestable().first,
              )
              .date;
          expect(visibleDate.isAfter(fixtureDate), isTrue);
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
