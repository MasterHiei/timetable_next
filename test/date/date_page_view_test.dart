import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  testWidgets('position diagnostics are safe before pixels are initialized', (
    tester,
  ) async {
    final date = DateController(initialDate: DateTime.utc(2024, 2, 26));
    final owner = MultiDateScrollController(date);
    final initialValue = date.value;
    var notifications = 0;
    date.addListener(() => notifications++);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      owner.dispose();
      date.dispose();
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Scrollable(
          controller: owner,
          axisDirection: AxisDirection.right,
          viewportBuilder: (context, position) {
            expect(owner.hasClients, isTrue);
            expect(position.hasPixels, isFalse);
            expect(position.toString, returnsNormally);
            expect(position.hasPixels, isFalse);
            expect(date.value, initialValue);
            expect(notifications, 0);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final shrinkWrap in [false, true]) {
    testWidgets(
      'rebuild diagnostics allow date paging, shrinkWrap=$shrinkWrap',
      (tester) async {
        final initialDate = DateTime.utc(2024, 2, 26);
        final date = DateController(
          initialDate: initialDate,
          visibleRange: VisibleDateRange.days(1, alignmentDate: initialDate),
        );
        final oldFlag = debugPrintRebuildDirtyWidgets;
        final oldPrint = debugPrint;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          date.dispose();
        });
        debugPrintRebuildDirtyWidgets = true;
        debugPrint = (String? message, {int? wrapWidth}) {};

        try {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 350,
                  height: 100,
                  child: DatePageView(
                    controller: date,
                    shrinkWrapInCrossAxis: shrinkWrap,
                    builder: (context, value) => SizedBox(
                      height: 40,
                      child: Text(value.toIso8601String()),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('2024-02-26T00:00:00.000Z'), findsOneWidget);
          final scrollable = tester.state<ScrollableState>(
            find.byType(Scrollable),
          );
          expect(scrollable.position.hasPixels, isTrue);
          expect(scrollable.position.toString, returnsNormally);

          date.jumpTo(DateTime.utc(2024, 2, 27));
          await tester.pumpAndSettle();
          expect(find.text('2024-02-27T00:00:00.000Z'), findsOneWidget);
          expect(date.date.value, DateTime.utc(2024, 2, 27));
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          expect(tester.takeException(), isNull);
        } finally {
          debugPrintRebuildDirtyWidgets = oldFlag;
          debugPrint = oldPrint;
        }
      },
    );
  }
}
