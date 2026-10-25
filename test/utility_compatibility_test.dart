import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/src/utils.dart';

void main() {
  test('inclusive ranges retain both directions and singletons', () {
    expect(1.rangeTo(3), [1, 2, 3]);
    expect(3.rangeTo(1), [3, 2, 1]);
    expect(2.rangeTo(2), [2]);
  });
  test('coercion preserves integers, NaN and comparable values', () {
    expect(2.coerceAtLeast(3), 3);
    expect(2.coerceAtMost(1), 1);
    expect(double.nan.coerceAtLeast(0).isNaN, isTrue);
    expect(double.nan.coerceAtMost(0).isNaN, isTrue);
    final day = DateTime.utc(2024);
    expect(
      day.coerceAtLeast(day.add(const Duration(days: 1))),
      day.add(const Duration(days: 1)),
    );
    expect(
      const Duration(
        hours: 1,
      ).coerceIn(Duration.zero, const Duration(minutes: 30)),
      const Duration(minutes: 30),
    );
    expect(
      () => const Duration(
        hours: 1,
      ).coerceIn(const Duration(hours: 2), Duration.zero),
      throwsArgumentError,
    );
  });
  test('collection minimum preserves empty and first-tie results', () {
    expect(minBy(<(String, int)>[], (entry) => entry.$2), isNull);
    expect(minBy([('first', 1), ('second', 1)], (entry) => entry.$2), (
      'first',
      1,
    ));
  });
}
