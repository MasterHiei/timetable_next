// Changes from upstream: deterministic snapping and independent boundary fixtures.
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

double pageOf(DateTime date) =>
    date.difference(DateTime.utc(1970)).inMicroseconds /
    Duration.microsecondsPerDay;

void main() {
  final alignment = DateTime.utc(1970);
  const epsilon = 0.000001;

  for (final step in [1, 2, 7]) {
    test('day snapping: step=$step, negative pages and both sides of ties', () {
      final range = VisibleDateRange.days(
        3,
        swipeRange: step,
        alignmentDate: alignment,
      );
      final starts = [for (var i = -4; i <= 4; i++) (i * step).toDouble()];
      for (final base in [-2 * step, -step, 0, step, 2 * step]) {
        for (final offset in [
          0.0,
          step / 2 - epsilon,
          step / 2,
          step / 2 + epsilon,
          step - epsilon,
        ]) {
          final page = base + offset;
          final focus = starts.lastWhere((start) => start <= page);
          // Enumerating starts avoids duplicating production modulo arithmetic.
          final nearest = starts.reduce(
            (a, b) => (b - page).abs() <= (a - page).abs() ? b : a,
          );
          expect(
            range.getTargetPageForFocus(page),
            focus,
            reason: 'page=$page',
          );
          expect(
            range.getTargetPageForCurrent(page),
            nearest,
            reason: 'page=$page',
          );
          expect(range.getTargetPageForFocus(focus), focus);
          expect(range.getTargetPageForCurrent(nearest), nearest);
        }
      }
    });
  }

  for (final (count, min, max, expectedMin, expectedMax)
      in <(int, int?, int?, double?, double?)>[
        (3, null, null, null, null),
        (3, 0, null, 0, null),
        (3, null, 1, null, -1),
        (3, 0, 0, 0, 0),
        (3, 0, 1, 0, 0),
        (3, 0, 2, 0, 0),
        (3, 0, 3, 0, 1),
        (1, 0, 0, 0, 0),
        (7, 0, 6, 0, 0),
        (14, 0, 31, 0, 18),
      ]) {
    test('range limits: count=$count min=$min max=$max', () {
      final range =
          VisibleDateRange.days(
                count,
                alignmentDate: alignment,
                minDate: min == null
                    ? null
                    : alignment.add(Duration(days: min)),
                maxDate: max == null
                    ? null
                    : alignment.add(Duration(days: max)),
              )
              as DaysVisibleDateRange;
      expect(range.minPage, expectedMin);
      expect(range.maxPage, expectedMax);
      for (final page in [-40.0, 0.0, 40.0]) {
        final clamped = page - range.applyBoundaryConditions(page);
        final expected = expectedMin != null && page < expectedMin
            ? expectedMin
            : expectedMax != null && page > expectedMax
            ? expectedMax
            : page;
        expect(clamped, expected);
        expect(range.applyBoundaryConditions(clamped), 0);
      }
    });
  }

  for (var firstDay = 1; firstDay <= 7; firstDay++) {
    test('week alignment: first weekday=$firstDay', () {
      var start = DateTime.utc(2024, 2, 29);
      while (start.weekday != firstDay) {
        start = start.subtract(const Duration(days: 1));
      }
      final startPage = pageOf(start);
      final range = VisibleDateRange.week(startOfWeek: firstDay);
      for (final delta in [0.0, 3.5 - epsilon, 3.5, 3.5 + epsilon, 7.0]) {
        expect(
          range.getTargetPageForFocus(startPage + delta),
          startPage + (delta < 7 ? 0 : 7),
        );
        expect(
          range.getTargetPageForCurrent(startPage + delta),
          startPage + (delta < 3.5 ? 0 : 7),
        );
      }
    });
  }

  test('week alignment retains leap-day and cross-year display dates', () {
    final range = VisibleDateRange.week();
    for (final (date, monday) in [
      (DateTime.utc(1969, 12, 31), DateTime.utc(1969, 12, 29)),
      (DateTime.utc(1999, 12, 31), DateTime.utc(1999, 12, 27)),
      (DateTime.utc(2000, 2, 29), DateTime.utc(2000, 2, 28)),
      (DateTime.utc(2021, 1, 1), DateTime.utc(2020, 12, 28)),
      (DateTime.utc(2100, 3, 1), DateTime.utc(2100, 3, 1)),
    ]) {
      expect(range.getTargetPageForFocus(pageOf(date)), pageOf(monday));
    }
  });

  test('workweek and fixed range preserve their navigation contracts', () {
    final monday = DateTime.utc(2024, 2, 26);
    final workweek = VisibleDateRange.weekAligned(5);
    expect(workweek.visibleDayCount, 5);
    expect(workweek.getTargetPageForFocus(pageOf(monday) + 4), pageOf(monday));
    final fixed = VisibleDateRange.fixed(monday, 3);
    expect(fixed.canScroll, isFalse);
    expect(fixed.getTargetPageForFocus(100), pageOf(monday));
    expect(fixed.getTargetPageForCurrent(-100), pageOf(monday));
  });
}
