import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';
import 'package:timetable_next/src/utils/constraints_passing_column.dart';

void main() {
  testWidgets(
    'week label variants respond to width, typography and controller changes',
    (tester) async {
      final date = DateController(
        initialDate: DateTime.utc(2024, 2, 26),
        visibleRange: VisibleDateRange.days(1),
      );
      Week? tapped;
      Widget view(bool narrow) => MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: MediaQuery(
          data: MediaQueryData(boldText: narrow),
          child: Directionality(
            textDirection: narrow ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: DefaultDateController(
                controller: date,
                child: DefaultTimetableCallbacks(
                  callbacks: TimetableCallbacks(
                    onWeekTap: (value) => tapped = value,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 100,
                      child: WeekIndicator.forController(
                        null,
                        alwaysUseNarrowestVariant: narrow,
                        style: WeekIndicatorStyle.raw(
                          tooltip: 'week',
                          decoration: const BoxDecoration(),
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(inherit: !narrow, fontSize: 14),
                          labels: narrow
                              ? ['changed long label', '10']
                              : ['long week label', '9'],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(false));
      final text = find.descendant(
        of: find.byType(WeekIndicator),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildRenderObjectWidget && widget.child == null,
        ),
      );
      final render = tester.renderObject<RenderBox>(text);
      expect(render.getMinIntrinsicWidth(30), greaterThan(0));
      expect(
        render.getMaxIntrinsicWidth(30),
        greaterThan(render.getMinIntrinsicWidth(30)),
      );
      expect(render.getMinIntrinsicHeight(100), greaterThan(0));
      expect(
        render.getMaxIntrinsicHeight(100),
        greaterThanOrEqualTo(render.getMinIntrinsicHeight(100)),
      );
      await tester.tap(find.byType(WeekIndicator));
      expect(tapped, const Week(2024, 9));
      date.jumpTo(DateTime.utc(2024, 3, 4));
      await tester.pumpWidget(view(true));
      await tester.tap(find.byType(WeekIndicator));
      expect(tapped, const Week(2024, 10));
      expect(render.getMaxIntrinsicWidth(30), render.getMinIntrinsicWidth(30));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [TimetableLocalizationsDelegate()],
          home: Scaffold(body: WeekIndicator.forDate(DateTime.utc(2024, 3, 4))),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      date.dispose();
    },
  );

  testWidgets('compact month synchronizes programmatic navigation and swipes', (
    tester,
  ) async {
    final date = DateController(
      initialDate: DateTime.utc(2024, 2),
      visibleRange: VisibleDateRange.days(1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultDateController(
            controller: date,
            child: SingleChildScrollView(
              child: CompactMonthTimetable(
                monthBuilder: (_, month) => SizedBox(
                  height: 100,
                  child: Text('${month.year}-${month.month}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2024-2'), findsOneWidget);
    date.jumpTo(DateTime.utc(2024, 3, 4));
    await tester.pumpAndSettle();
    expect(find.text('2024-3'), findsOneWidget);
    await tester.drag(find.byType(MonthPageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(date.date.value, DateTime.utc(2024, 4));
    await tester.pumpWidget(const SizedBox());
    date.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'constraint-passing column reports intrinsic sizes and retains hit testing',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: ConstraintsPassingColumn(
                children: [
                  GestureDetector(
                    onTap: () => taps++,
                    child: const SizedBox(
                      width: 100,
                      height: 20,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 50, height: 30),
                ],
              ),
            ),
          ),
        ),
      );
      final render = tester.renderObject<RenderBox>(
        find.byType(ConstraintsPassingColumn),
      );
      expect(render.size, const Size(200, 100));
      expect(render.getMinIntrinsicWidth(100), 100);
      expect(render.getMaxIntrinsicWidth(100), 100);
      expect(render.getMinIntrinsicHeight(200), 50);
      expect(render.getMaxIntrinsicHeight(200), 50);
      await tester.tap(find.byType(GestureDetector));
      expect(taps, 1);
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: ConstraintsPassingColumn(children: []),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ConstraintsPassingColumn)),
        const Size(200, 100),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
