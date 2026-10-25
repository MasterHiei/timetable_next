import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:timetable_next/timetable_next.dart'
    show TimeZoom, DefaultTimeController;
import 'package:timetable_next/src/date/controller.dart';
import 'package:timetable_next/src/time/controller.dart';
import 'package:timetable_next/src/time/time_range.dart';

void main() {
  test('unregistering smallest client updates visible-duration limit', () {
    final controller = TimeController(minDayHeight: 1000);
    addTearDown(controller.dispose);
    final small = controller.registerClient(250);
    final large = controller.registerClient(500);
    expect(controller.actualMaxDuration, const Duration(hours: 6));

    small.unregister();
    expect(controller.minClientHeight, 500);
    expect(controller.actualMaxDuration, const Duration(hours: 12));
    large.unregister();
  });

  test('date activity changes at the same page are stored and notified', () {
    final controller = DateController(initialDate: DateTime.utc(2026, 10, 24));
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final target = DatePageValue(
      controller.visibleRange,
      controller.value.page + 7,
    );

    controller.value = controller.value.copyWithActivity(
      activity: DrivenDateScrollActivity(target),
    );

    expect(controller.value.activity, isA<DrivenDateScrollActivity>());
    expect(notifications, 1);
  });

  testWidgets('time animation future waits for the animation endpoint', (
    tester,
  ) async {
    final controller = TimeController(
      initialRange: TimeRange(
        const Duration(hours: 8),
        const Duration(hours: 16),
      ),
    );

    var completed = false;
    controller
        .animateTo(
          TimeRange.fullDay,
          vsync: tester,
          duration: const Duration(seconds: 1),
        )
        .then((_) => completed = true);

    await tester.pump();
    expect(controller.value, isNot(TimeRange.fullDay));
    expect(
      completed,
      isFalse,
      reason: 'The returned future must wait for the target range.',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.value, TimeRange.fullDay);
    await tester.pump(
      const Duration(microseconds: 1),
    ); // Simulation completes after its terminal time.
    expect(completed, isTrue);
    controller.dispose();
  });
  testWidgets('date and time interruption and disposal complete futures', (
    tester,
  ) async {
    final time = TimeController(
      initialRange: TimeRange(
        const Duration(hours: 8),
        const Duration(hours: 16),
      ),
    );
    final date = DateController(initialDate: DateTime.utc(2024));
    var timeDone = false;
    var dateDone = false;
    time
        .animateTo(TimeRange.fullDay, vsync: tester)
        .then((_) => timeDone = true);
    date
        .animateTo(DateTime.utc(2024, 2), vsync: tester)
        .then((_) => dateDone = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    time.cancelAnimation();
    date.cancelAnimation();
    await tester.pump();
    expect(timeDone, isTrue);
    expect(dateDone, isTrue);
    expect(date.value.activity, isA<IdleDateScrollActivity>());
    timeDone = false;
    dateDone = false;
    time
        .animateTo(TimeRange.fullDay, vsync: tester)
        .then((_) => timeDone = true);
    date
        .animateTo(DateTime.utc(2024, 3), vsync: tester)
        .then((_) => dateDone = true);
    await tester.pump();
    time.dispose();
    date.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(timeDone, isTrue);
    expect(dateDone, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('replacing a time controller at equal height rebinds clients', (
    tester,
  ) async {
    final first = TimeController(minDayHeight: 1000);
    final second = TimeController(minDayHeight: 1000);
    Widget view(TimeController controller, double height) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          height: height,
          child: DefaultTimeController(
            controller: controller,
            child: const TimeZoom(child: SizedBox()),
          ),
        ),
      ),
    );
    await tester.pumpWidget(view(first, 250));
    await tester.pump();
    expect(first.minClientHeight, 250);
    await tester.pumpWidget(view(second, 250));
    await tester.pump();
    expect(first.minClientHeight, isNull);
    expect(second.minClientHeight, 250);
    await tester.pumpWidget(view(second, 500));
    await tester.pump();
    expect(second.minClientHeight, 500);
    await tester.pumpWidget(const SizedBox());
    expect(second.minClientHeight, isNull);
    expect(second.actualMaxDuration, const Duration(days: 1));
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacement animations complete both old and new futures', (
    tester,
  ) async {
    final controller = TimeController(
      initialRange: TimeRange(Duration.zero, const Duration(hours: 1)),
    );
    var firstDone = false;
    var secondDone = false;
    controller
        .animateTo(TimeRange.fullDay, vsync: tester)
        .then((_) => firstDone = true);
    await tester.pump();
    controller
        .animateTo(
          TimeRange(const Duration(hours: 8), const Duration(hours: 16)),
          vsync: tester,
        )
        .then((_) => secondDone = true);
    await tester.pump();
    expect(firstDone, isTrue);
    expect(secondDone, isFalse);
    await tester.pump(const Duration(milliseconds: 201));
    expect(secondDone, isTrue);
    expect(controller.value.startTime, const Duration(hours: 8));
    controller.dispose();
  });
  testWidgets('idle-listener reentry owns the replacement date animation', (
    tester,
  ) async {
    final controller = DateController(initialDate: DateTime.utc(2024));
    controller.animateTo(
      DateTime.utc(2024, 1, 8),
      vsync: tester,
      duration: const Duration(seconds: 1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    var reentered = false;
    var replacementDone = false;
    controller.addListener(() {
      if (!reentered && controller.value.activity is IdleDateScrollActivity) {
        reentered = true;
        controller
            .animateTo(
              DateTime.utc(2024, 3),
              vsync: tester,
              duration: const Duration(seconds: 2),
            )
            .then((_) => replacementDone = true);
      }
    });
    controller.animateTo(DateTime.utc(2024, 2), vsync: tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    controller.cancelAnimation();
    await tester.pump();
    expect(reentered, isTrue);
    expect(replacementDone, isTrue);
    controller.dispose();
  });
  testWidgets('date disposal does not notify listeners into new animations', (
    tester,
  ) async {
    final controller = DateController(initialDate: DateTime.utc(2024));
    controller.animateTo(DateTime.utc(2024, 2), vsync: tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    var notified = false;
    controller.addListener(() {
      notified = true;
      controller.animateTo(DateTime.utc(2024, 3), vsync: tester);
    });
    controller.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(notified, isFalse);
    expect(controller.isDisposed, isTrue);
  });
}
