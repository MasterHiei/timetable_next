import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';
import 'package:timetable_next/src/utils.dart';

void main() {
  test('ISO weeks retain their week-based year across calendar boundaries', () {
    for (final (date, expected) in [
      (DateTime.utc(2015, 12, 31), const Week(2015, 53)),
      (DateTime.utc(2016, 1, 1), const Week(2015, 53)),
      (DateTime.utc(2018, 12, 31), const Week(2019, 1)),
      (DateTime.utc(2021, 1, 3), const Week(2020, 53)),
      (DateTime.utc(2024, 2, 29), const Week(2024, 9)),
    ]) {
      expect(date.week, expected);
      expect(date.week.getDayOfWeek(date.weekday), date);
      expect(date.week.hashCode, expected.hashCode);
    }
    expect(const Week(2024, 9).toString(), '2024-W09');
    expect(const Week(2020, 53).toString(), '2020-W53');
    expect(const Week(2023, 52).compareTo(const Week(2024, 1)), lessThan(0));
    expect(const Week(2024, 2).compareTo(const Week(2024, 1)), greaterThan(0));
    expect(DateTime.utc(1900, 3, 1).dayOfYear, 60);
    expect(DateTime.utc(2000, 3, 1).dayOfYear, 61);
    expect(DateTime.utc(2024, 12, 31).dayOfYear, 366);
  });

  test('date copies preserve display fields without converting time zones', () {
    final local = DateTime(2024, 2, 29, 12, 34, 56, 789, 123);
    final utc = local.copyWith(isUtc: true);
    expect(utc, DateTime.utc(2024, 2, 29, 12, 34, 56, 789, 123));
    expect(
      utc.copyWith(
        year: 2020,
        month: 3,
        day: 2,
        hour: 1,
        minute: 2,
        second: 3,
        millisecond: 4,
      ),
      DateTime.utc(2020, 3, 2, 1, 2, 3, 4, 123),
    );
    expect(utc.copyWith(isUtc: false).isUtc, isFalse);
    expect(utc.atStartOfDay, DateTime.utc(2024, 2, 29));
    expect(utc.atEndOfDay, DateTime.utc(2024, 2, 29, 23, 59, 59, 999, 999));
    expect(utc.firstDayOfMonth, DateTime.utc(2024, 2));
    expect(utc.lastDayOfMonth.day, 29);
    expect(DateTime.utc(1900, 2).daysInMonth, 28);
    expect(
      utc.timeOfDay,
      const Duration(
        hours: 12,
        minutes: 34,
        seconds: 56,
        milliseconds: 789,
        microseconds: 123,
      ),
    );
    expect(
      utc.roundTimeToMultipleOf(const Duration(minutes: 15)),
      DateTime.utc(2024, 2, 29, 12, 30),
    );
    expect(DateTimeTimetable.month(2024, 2), DateTime.utc(2024, 2));
    expect(
      DateTimeTimetable.dateTimeFromPage(-0.5),
      DateTime.utc(1969, 12, 31, 12),
    );
    expect(DateTimeTimetable.dateFromPage(-1), DateTime.utc(1969, 12, 31));
    expect(
      DateTime.utc(2024, 2, 29).nextOrSame(DateTime.monday),
      DateTime.utc(2024, 3, 4),
    );
    expect(
      DateTime.utc(2024, 2, 29).previousOrSame(DateTime.monday),
      DateTime.utc(2024, 2, 26),
    );
  });

  test('invalid display values produce actionable diagnostics', () {
    final local = DateTime(2024, 2, 1);
    final midday = DateTime.utc(2024, 2, 1, 12);
    final invalid = <bool Function()>[
      local.debugCheckIsValidTimetableDateTime,
      midday.debugCheckIsValidTimetableDate,
      DateTime.utc(2024, 2, 2).debugCheckIsValidTimetableMonth,
      const Duration(seconds: -1).debugCheckIsValidTimetableTimeOfDay,
      0.debugCheckIsValidTimetableDayOfWeek,
      13.debugCheckIsValidTimetableMonth,
      Interval(local, local).debugCheckIsValidTimetableInterval,
      Interval(midday, midday).debugCheckIsValidTimetableDateInterval,
    ];
    for (final check in invalid) {
      expect(check, throwsA(isA<FlutterError>()));
    }
    final DateTime? absentDate = null;
    final Duration? absentDuration = null;
    final int? absentInt = null;
    final Interval? absentInterval = null;
    expect(absentDate.debugCheckIsValidTimetableDateTime(), isTrue);
    expect(absentDate.debugCheckIsValidTimetableDate(), isTrue);
    expect(absentDate.debugCheckIsValidTimetableMonth(), isTrue);
    expect(absentDuration.debugCheckIsValidTimetableTimeOfDay(), isTrue);
    expect(absentInt.debugCheckIsValidTimetableDayOfWeek(), isTrue);
    expect(absentInt.debugCheckIsValidTimetableMonth(), isTrue);
    expect(absentInterval.debugCheckIsValidTimetableInterval(), isTrue);
    expect(absentInterval.debugCheckIsValidTimetableDateInterval(), isTrue);
    expect(
      Interval(
        DateTime.utc(2024),
        DateTime.utc(2024, 1, 1, 23, 59, 59, 999, 999),
      ).debugCheckIsValidTimetableDateInterval(),
      isTrue,
    );
  });

  test(
    'time ranges shift at day limits and retain odd microsecond durations',
    () {
      final early = TimeRange.centeredAround(
        Duration.zero,
        const Duration(hours: 2),
      );
      final late = TimeRange.centeredAround(
        const Duration(days: 1),
        const Duration(hours: 2),
      );
      expect(early.startTime, Duration.zero);
      expect(early.endTime, const Duration(hours: 2));
      expect(late.startTime, const Duration(hours: 22));
      expect(late.endTime, const Duration(days: 1));
      final odd = TimeRange.centeredAround(
        const Duration(hours: 12),
        const Duration(microseconds: 3),
      );
      expect(odd.duration, const Duration(microseconds: 3));
      expect(odd.centerTime, const Duration(hours: 12, microseconds: 1));
      expect(TimeRange.fullDay.contains(odd), isTrue);
      expect(early.contains(late), isFalse);
      expect(
        TimeRange.lerp(early, late, 0.5),
        TimeRange(const Duration(hours: 11), const Duration(hours: 13)),
      );
      expect(
        early.hashCode,
        TimeRange.fromStartAndDuration(
          Duration.zero,
          const Duration(hours: 2),
        ).hashCode,
      );
      expect(
        () => TimeRange.centeredAround(
          Duration.zero,
          const Duration(hours: 2),
          canShiftIfDoesntFit: false,
        ),
        throwsAssertionError,
      );
      expect(
        () => TimeRange(const Duration(hours: 4), const Duration(hours: 3)),
        throwsAssertionError,
      );
    },
  );
}
