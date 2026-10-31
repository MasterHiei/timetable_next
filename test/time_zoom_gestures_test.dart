import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

Widget _view(TimeController controller, {double height = 400}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 300,
      height: height,
      child: DefaultTimeController(
        controller: controller,
        child: const TimeZoom(
          child: SizedBox(
            key: ValueKey('day'),
            child: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'touch drag and wheel scrolling update time while respecting bounds',
    (tester) async {
      final controller = TimeController(
        initialRange: TimeRange(
          const Duration(hours: 6),
          const Duration(hours: 18),
        ),
      );
      await tester.pumpWidget(_view(controller));
      await tester.pump();
      final center = tester.getCenter(find.byType(TimeZoom));
      await tester.timedDrag(
        find.byType(TimeZoom),
        const Offset(0, -100),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(controller.value.startTime, greaterThan(const Duration(hours: 6)));
      expect(controller.value.duration, const Duration(hours: 12));
      final before = controller.value.startTime;
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 20)),
      );
      await tester.pump();
      expect(controller.value.startTime, greaterThan(before));
      final scrollable = tester.state<ScrollableState>(
        find.byWidgetPredicate((widget) => widget is Scrollable),
      );
      scrollable.position.jumpTo(0);
      await tester.pump();
      expect(controller.value.startTime, Duration.zero);
      await tester.fling(find.byType(TimeZoom), const Offset(0, -250), 20000);
      await tester.pumpAndSettle();
      expect(controller.maxRange.contains(controller.value), isTrue);
      expect(controller.value.duration, const Duration(hours: 12));
      await tester.pumpWidget(const SizedBox());
      expect(controller.minClientHeight, isNull);
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('two-finger pinch retains focus and clamps collapsed spans', (
    tester,
  ) async {
    final controller = TimeController(
      initialRange: TimeRange(
        const Duration(hours: 6),
        const Duration(hours: 18),
      ),
      minDuration: const Duration(hours: 1),
    );
    await tester.pumpWidget(_view(controller));
    await tester.pump();
    final center = tester.getCenter(find.byType(TimeZoom));
    final first = await tester.startGesture(
      center - const Offset(0, 50),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(0, 50),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(10, 100));
    await second.moveTo(center + const Offset(10, 100));
    await tester.pump();
    expect(controller.value.duration, const Duration(hours: 6));
    expect(controller.value.startTime, lessThan(const Duration(hours: 12)));
    expect(controller.value.endTime, greaterThan(const Duration(hours: 12)));
    await first.moveTo(center);
    await second.moveTo(center);
    await tester.pump();
    expect(controller.value, TimeRange.fullDay);
    await second.cancel();
    await first.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a stationary pointer and changing viewport preserve controller state',
    (tester) async {
      final controller = TimeController(
        initialRange: TimeRange(
          const Duration(hours: 8),
          const Duration(hours: 12),
        ),
      );
      await tester.pumpWidget(_view(controller));
      await tester.pump();
      await tester.tap(find.byType(TimeZoom));
      await tester.pump();
      expect(controller.value.startTime, const Duration(hours: 8));
      final child = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('day')),
      );
      final overflow = child.parent! as RenderBox;
      expect(
        overflow
            .getDryLayout(
              const BoxConstraints.tightFor(width: 300, height: 400),
            )
            .height,
        2400,
      );
      await tester.pumpWidget(_view(controller, height: 300));
      await tester.pump();
      expect(controller.minClientHeight, 300);
      expect(controller.value.duration, const Duration(hours: 4));
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
