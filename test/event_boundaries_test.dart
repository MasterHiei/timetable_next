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

  group('time overlays exclude spans outside the display day', () {
    for (final (name, start, end) in <(String, DateTime, DateTime)>[
      ('point', DateTime.utc(2024, 3, 1, 12), DateTime.utc(2024, 3, 1, 12)),
      ('before', DateTime.utc(2024, 2, 29, 21), DateTime.utc(2024, 2, 29, 22)),
      ('after', DateTime.utc(2024, 3, 2, 1), DateTime.utc(2024, 3, 2, 2)),
      (
        'ends at day start',
        DateTime.utc(2024, 2, 29, 23),
        DateTime.utc(2024, 3),
      ),
      (
        'starts at next day',
        DateTime.utc(2024, 3, 2),
        DateTime.utc(2024, 3, 2, 1),
      ),
    ]) {
      test(name, () {
        expect(
          TestEvent(
            start,
            end,
          ).toTimeOverlay(date: midnight, widget: const SizedBox()),
          isNull,
        );
      });
    }
  });

  group('time overlays clip positive spans at microsecond precision', () {
    for (final (name, start, end, expectedStart, expectedEnd)
        in <(String, DateTime, DateTime, Duration, Duration)>[
          (
            'enters the day',
            DateTime.utc(2024, 2, 29, 23),
            DateTime.utc(2024, 3, 1, 9),
            Duration.zero,
            const Duration(hours: 9),
          ),
          (
            'leaves the day',
            DateTime.utc(2024, 3, 1, 20),
            DateTime.utc(2024, 3, 2, 1),
            const Duration(hours: 20),
            const Duration(days: 1),
          ),
          (
            'covers the day',
            DateTime.utc(2024, 2, 29, 23),
            DateTime.utc(2024, 3, 2, 1),
            Duration.zero,
            const Duration(days: 1),
          ),
          (
            'last microsecond',
            DateTime.utc(2024, 3, 1, 23, 59, 59, 999, 999),
            DateTime.utc(2024, 3, 2),
            const Duration(
              hours: 23,
              minutes: 59,
              seconds: 59,
              milliseconds: 999,
              microseconds: 999,
            ),
            const Duration(days: 1),
          ),
        ]) {
      test(name, () {
        final event = TestEvent(start, end);
        final overlay = event.toTimeOverlay(
          date: midnight,
          widget: const SizedBox(),
        )!;
        expect(overlay.start, expectedStart);
        expect(overlay.end, expectedEnd);
        if (name == 'last microsecond') {
          expect(
            event.toTimeOverlay(
              date: DateTime.utc(2024, 3, 2),
              widget: const SizedBox(),
            ),
            isNull,
          );
        }
      });
    }
  });

  test('time overlays retain the widget and requested paint order', () {
    final event = TestEvent(
      DateTime.utc(2024, 3, 1, 9),
      DateTime.utc(2024, 3, 1, 10),
    );
    final child = SizedBox(key: UniqueKey());
    final overlay = event.toTimeOverlay(date: midnight, widget: child)!;
    expect(overlay.position, TimeOverlayPosition.inFrontOfEvents);
    expect(overlay.widget, same(child));
    final behind = event.toTimeOverlay(
      date: midnight,
      widget: child,
      position: .behindEvents,
    )!;
    expect(behind.position, TimeOverlayPosition.behindEvents);
    expect(behind.widget, same(child));
  });
}
