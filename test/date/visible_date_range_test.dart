// Changes from upstream: replaced generated properties with deterministic snapping and boundary cases.
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

double pageOf(DateTime date) =>
    date.difference(DateTime.utc(1970)).inMicroseconds /
    Duration.microsecondsPerDay;

void main() {
  final alignment = DateTime.utc(1970);
  const epsilon = 0.000001;
  // Enumerate legal starts instead of copying the production modulo formula.
  double reference(double page, int step, {required bool nearest}) {
    final candidates = [for (var i = -40; i <= 40; i++) (i * step).toDouble()];
    if (!nearest) return candidates.lastWhere((start) => start <= page);
    return candidates.reduce(
      (a, b) => (b - page).abs() <= (a - page).abs() ? b : a,
    );
  }

  group('days: original focus/current/limits properties and boundaries', () {
    for (final count in [1, 3, 5, 7, 14]) {
      for (final step in [1, 2, 7]) {
        final range = VisibleDateRange.days(
          count,
          swipeRange: step,
          alignmentDate: alignment,
        );
        for (var integer = -14; integer <= 14; integer++) {
          for (final offset in [0.0, .5 - epsilon, .5, .5 + epsilon]) {
            final page = integer + offset;
            test('count=$count step=$step page=$page', () {
              final focus = range.getTargetPageForFocus(page);
              final current = range.getTargetPageForCurrent(page);
              expect(focus, reference(page, step, nearest: false));
              expect(current, reference(page, step, nearest: true));
              expect(range.getTargetPageForFocus(focus), focus);
              expect(range.getTargetPageForCurrent(current), current);
              expect(
                range.getTargetPageForCurrent(page + .01),
                greaterThanOrEqualTo(current),
              );
            });
          }
        }
      }
      for (final span in [0, 1, 6, 7, 31]) {
        final end = alignment.add(Duration(days: span));
        for (final bounds in <(DateTime?, DateTime?)>[
          (null, null),
          (alignment, null),
          (null, end),
          (alignment, end),
        ]) {
          test('limits count=$count span=$span bounds=$bounds', () {
            final range = DaysVisibleDateRange(
              count,
              alignmentDate: alignment,
              minDate: bounds.$1,
              maxDate: bounds.$2,
            );
            expect(range.minPage, bounds.$1 == null ? null : 0);
            final expectedMax = bounds.$2 == null
                ? null
                : (span - count + 1 < 0 && bounds.$1 != null
                      ? 0
                      : span - count + 1);
            expect(range.maxPage, expectedMax);
            for (final page in [-40.0, 0.0, 40.0]) {
              final clamped = page - range.applyBoundaryConditions(page);
              if (range.minPage != null) {
                expect(clamped, greaterThanOrEqualTo(range.minPage!));
              }
              if (range.maxPage != null) {
                expect(clamped, lessThanOrEqualTo(range.maxPage!));
              }
              expect(range.applyBoundaryConditions(clamped), 0);
            }
          });
        }
      }
    }
    test('negative half-day chooses the later day', () {
      expect(VisibleDateRange.days(1).getTargetPageForCurrent(-.5), 0);
    });
  });
  group('week: original focus/current properties, all seven week starts', () {
    for (var firstDay = 1; firstDay <= 7; firstDay++) {
      for (final anchor in [
        DateTime.utc(1969, 12, 31),
        DateTime.utc(1999, 12, 31),
        DateTime.utc(2000, 2, 28),
        DateTime.utc(2024, 2, 29),
        DateTime.utc(2100, 2, 28),
      ]) {
        var start = anchor;
        while (start.weekday != firstDay) {
          start = start.subtract(const Duration(days: 1));
        }
        final startPage = pageOf(start);
        final range = VisibleDateRange.week(startOfWeek: firstDay);
        for (final delta in [
          0.0,
          1.0,
          3.5 - epsilon,
          3.5,
          3.5 + epsilon,
          6.9,
          7.0,
        ]) {
          test('first=$firstDay anchor=$anchor delta=$delta', () {
            final page = startPage + delta;
            expect(
              range.getTargetPageForFocus(page),
              startPage + (delta < 7 ? 0 : 7),
            );
            expect(
              range.getTargetPageForCurrent(page),
              startPage + (delta < 3.5 ? 0 : 7),
            );
            expect(
              range.getTargetPageForCurrent(page + 7),
              range.getTargetPageForCurrent(page) + 7,
            );
          });
        }
      }
    }
    test('five-day workweek and fixed range', () {
      final monday = DateTime.utc(2026, 10, 19);
      final workweek = VisibleDateRange.weekAligned(5);
      expect(workweek.visibleDayCount, 5);
      expect(
        workweek.getTargetPageForFocus(pageOf(monday) + 4),
        pageOf(monday),
      );
      final fixed = VisibleDateRange.fixed(monday, 3);
      expect(fixed.canScroll, isFalse);
      expect(fixed.getTargetPageForCurrent(-100), pageOf(monday));
    });
  });
}
