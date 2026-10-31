import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  test(
    'date values retain their visible dates and immutable copy semantics',
    () {
      final range = VisibleDateRange.days(
        3,
        alignmentDate: DateTime.utc(1970),
        minDate: DateTime.utc(1969, 12, 30),
        maxDate: DateTime.utc(1970, 1, 4),
      );
      final value = DatePageValue(range, -0.5);
      expect(value.copyWith(), value);
      expect(value.copyWith().hashCode, value.hashCode);
      expect(value.visibleDayCount, 3);
      expect(value.firstVisibleDate, DateTime.utc(1969, 12, 31));
      expect(value.lastVisibleDate, DateTime.utc(1970, 1, 3));
      final activity = DrivenDateScrollActivity(value);
      final active = DatePageValueWithScrollActivity(range, 0, activity);
      expect(active.copyWithActivity(activity: activity), active);
      expect(
        active.copyWithActivity(activity: activity).hashCode,
        active.hashCode,
      );
      final fixed = VisibleDateRange.fixed(DateTime.utc(2024), 2);
      expect(() => fixed.applyBoundaryConditions(0), throwsStateError);
    },
  );

  testWidgets(
    'date dragging snaps and respects limits as the visible range changes',
    (tester) async {
      final day = DateTime.utc(2024, 2, 26);
      final controller = DateController(
        initialDate: day,
        visibleRange: VisibleDateRange.days(
          1,
          alignmentDate: day,
          minDate: day,
          maxDate: day.add(const Duration(days: 2)),
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: DatePageView(
                controller: controller,
                builder: (_, date) => Text('${date.day}'),
              ),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(DatePageView), const Offset(-220, 0));
      await tester.pumpAndSettle();
      expect(controller.date.value, DateTime.utc(2024, 2, 27));
      await tester.fling(
        find.byType(DatePageView),
        const Offset(-300, 0),
        2000,
      );
      await tester.pumpAndSettle();
      expect(controller.date.value, DateTime.utc(2024, 2, 28));
      controller.visibleRange = VisibleDateRange.fixed(day, 2);
      await tester.pumpAndSettle();
      expect(controller.date.value, day);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  test('time controller limits and direct jumps preserve bounds', () {
    final bounded = TimeController(
      minDuration: const Duration(hours: 1),
      maxDuration: const Duration(hours: 4),
      maxRange: TimeRange(const Duration(hours: 6), const Duration(hours: 18)),
    );
    expect(
      bounded.value,
      TimeRange(const Duration(hours: 10), const Duration(hours: 14)),
    );
    expect(
      () => bounded.value = TimeRange(Duration.zero, const Duration(hours: 4)),
      throwsAssertionError,
    );
    bounded.jumpTo(
      TimeRange(const Duration(hours: 8), const Duration(hours: 12)),
    );
    expect(bounded.value.startTime, const Duration(hours: 8));
    final registration = bounded.registerClient(200);
    registration.notifyHeightChanged(200);
    registration.unregister();
    bounded.dispose();
  });

  testWidgets('full-day animation reaches its target and completes', (
    tester,
  ) async {
    final full = TimeController(
      initialRange: TimeRange(
        const Duration(hours: 8),
        const Duration(hours: 12),
      ),
    );
    var done = false;
    unawaited(
      full.animateToShowFullDay(vsync: tester).then((_) => done = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    expect(done, isTrue);
    expect(full.value, TimeRange.fullDay);
    full.dispose();
  });

  test('jumpToToday reveals today in the aligned week', () {
    final before = DateTimeTimetable.today();
    final date = DateController(
      initialDate: before.subtract(const Duration(days: 14)),
    );
    addTearDown(date.dispose);
    expect(date.visibleDates.value.includes(before), isFalse);

    date.jumpToToday();

    final after = DateTimeTimetable.today();
    expect(date.date.value.weekday, DateTime.monday);
    expect(
      date.visibleDates.value.includes(before) ||
          date.visibleDates.value.includes(after),
      isTrue,
    );
  });

  testWidgets(
    'animateToToday reveals today and completes in the aligned week',
    (tester) async {
      final before = DateTimeTimetable.today();
      final date = DateController(
        initialDate: before.subtract(const Duration(days: 14)),
      );
      addTearDown(date.dispose);
      expect(date.visibleDates.value.includes(before), isFalse);
      var dateDone = false;
      unawaited(
        date.animateToToday(vsync: tester).then((_) => dateDone = true),
      );
      await tester.pump();
      expect(dateDone, isFalse);
      await tester.pump(const Duration(milliseconds: 201));
      expect(dateDone, isTrue);
      final after = DateTimeTimetable.today();
      expect(date.date.value.weekday, DateTime.monday);
      expect(
        date.visibleDates.value.includes(before) ||
            date.visibleDates.value.includes(after),
        isTrue,
      );
    },
  );
}
