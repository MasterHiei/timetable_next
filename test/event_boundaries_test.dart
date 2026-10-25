import 'package:dart_date/dart_date.dart' show Interval;
import 'package:flutter/widgets.dart' hide Interval;
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

class TestEvent extends Event {
  const TestEvent(DateTime start, DateTime end) : super(start: start, end: end);
}

void main() {
  final midnight = DateTime.utc(2024, 3);
  test('positive events are half-open, zero-duration events are points', () {
    for (final duration in [
      const Duration(microseconds: 1),
      const Duration(microseconds: 500),
      const Duration(milliseconds: 1),
      const Duration(hours: 1),
    ]) {
      final event = TestEvent(midnight, midnight.add(duration));
      final provider = eventProviderFromFixedList([event]);
      for (final point in [
        midnight.subtract(const Duration(microseconds: 1)),
        midnight,
        event.end.subtract(const Duration(microseconds: 1)),
        event.end,
      ]) {
        expect(
          provider(Interval(point, point)).contains(event),
          !point.isBefore(midnight) && point.isBefore(event.end),
          reason: 'duration=$duration point=$point',
        );
      }
    }
    final point = TestEvent(midnight, midnight);
    expect(eventProviderFromFixedList([point])(Interval(midnight, midnight)), [
      point,
    ]);
  });
  test('midnight tail and cross-midnight intervals retain every instant', () {
    final tail = midnight.subtract(const Duration(microseconds: 1));
    final event = TestEvent(
      tail,
      midnight.add(const Duration(microseconds: 1)),
    );
    final previousDay = DateTime.utc(2024, 2, 29);
    expect(previousDay.fullDayInterval.includes(tail), isTrue);
    expect(event.interval.dateInterval.includes(midnight), isTrue);
    expect(eventProviderFromFixedList([event])(previousDay.fullDayInterval), [
      event,
    ]);
    expect(tail.atStartOfDay, previousDay);
    expect(tail.copyWith(hour: 12).microsecond, 999);
    expect(
      event.toTimeOverlay(date: previousDay, widget: const SizedBox())!.end,
      const Duration(days: 1),
    );
  });
  test('all-day classification retains the 24-hour duration threshold', () {
    for (final delta in [-1, 0, 1]) {
      final duration = const Duration(days: 1) + Duration(microseconds: delta);
      expect(TestEvent(midnight, midnight.add(duration)).isAllDay, delta >= 0);
    }
  });
  test('provider merging preserves identity and filters outside the range', () {
    final a = TestEvent(midnight, midnight.add(const Duration(hours: 1)));
    final b = TestEvent(
      midnight.add(const Duration(days: 2)),
      midnight.add(const Duration(days: 3)),
    );
    final provider = mergeEventProviders([
      eventProviderFromFixedList([a]),
      eventProviderFromFixedList([b]),
    ]);
    expect(provider(midnight.fullDayInterval), [a]);
    expect(
      provider(
        Interval(
          midnight.subtract(const Duration(days: 2)),
          midnight.subtract(const Duration(days: 1)),
        ),
      ),
      isEmpty,
    );
  });
}
