import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/src/utils/constraints_passing_column.dart';

void main() {
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
