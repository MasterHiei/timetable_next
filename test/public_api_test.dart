import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable.dart' as original;
import 'package:timetable_next/timetable_next.dart' as canonical;

void main() {
  test('both entries expose the same public types', () {
    expect(canonical.DateController, original.DateController);
    expect(canonical.TimeController, original.TimeController);
    expect(canonical.BasicEvent, original.BasicEvent);
    final controller = canonical.DateController(
      initialDate: DateTime.utc(2024),
    );
    expect(controller, isA<original.DateController>());
    controller.dispose();
  });
}
