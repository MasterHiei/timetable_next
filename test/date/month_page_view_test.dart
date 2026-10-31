import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  testWidgets('month view switches ownership without disposing its caller', (
    tester,
  ) async {
    final caller = MonthPageController(initialMonth: DateTime.utc(2024, 2));
    Widget view(MonthPageController? controller) => Directionality(
      textDirection: TextDirection.ltr,
      child: MonthPageView(
        monthPageController: controller,
        builder: (_, month) => Text('${month.year}-${month.month}'),
      ),
    );
    await tester.pumpWidget(view(null));
    await tester.pumpWidget(view(caller));
    await tester.pumpAndSettle();
    expect(find.text('2024-2'), findsOneWidget);
    caller.jumpTo(DateTime.utc(2024, 3));
    await tester.pumpAndSettle();
    expect(find.text('2024-3'), findsOneWidget);
    await tester.pumpWidget(view(null));
    expect(caller.value, DateTime.utc(2024, 3));
    void listener() {}
    caller.addListener(listener);
    caller.removeListener(listener);
    await tester.pumpWidget(const SizedBox());
    caller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'month controller reports initial value and notifies its first transition',
    (tester) async {
      final controller = MonthPageController(
        initialMonth: DateTime.utc(2024, 2),
      );
      expect(controller.value, DateTime.utc(2024, 2));
      var changes = 0;
      controller.addListener(() => changes++);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MonthPageView(
            monthPageController: controller,
            builder: (_, month) => Text('${month.year}-${month.month}'),
          ),
        ),
      );
      controller.jumpTo(DateTime.utc(2024, 3));
      await tester.pumpAndSettle();
      expect(controller.value, DateTime.utc(2024, 3));
      expect(changes, 1);
      var completed = false;
      unawaited(
        controller
            .animateTo(DateTime.utc(2025, 1))
            .then((_) => completed = true),
      );
      await tester.pumpAndSettle();
      expect(controller.value, DateTime.utc(2025));
      expect(completed, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(controller.value, DateTime.utc(2025));
      controller.dispose();
    },
  );

  testWidgets(
    'month view rebinds replacement without disposing caller controllers',
    (tester) async {
      final first = MonthPageController(initialMonth: DateTime.utc(2024, 2));
      final second = MonthPageController(initialMonth: DateTime.utc(2024, 5));
      Widget view(MonthPageController controller) => Directionality(
        textDirection: TextDirection.ltr,
        child: MonthPageView(
          monthPageController: controller,
          builder: (_, month) => Text('${month.year}-${month.month}'),
        ),
      );
      await tester.pumpWidget(view(first));
      expect(find.text('2024-2'), findsOneWidget);
      await tester.pumpWidget(view(second));
      await tester.pumpAndSettle();
      expect(find.text('2024-5'), findsOneWidget);
      second.jumpTo(DateTime.utc(2024, 6));
      await tester.pumpAndSettle();
      expect(find.text('2024-6'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      second.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
