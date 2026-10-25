import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/src/utils/size_reporting_widget.dart';

void main() {
  testWidgets('measured height respects a bounded parent', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: ImmediateSizedBox(
              heightGetter: () => 200,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ImmediateSizedBox)),
      const Size(200, 100),
    );
    expect(tester.takeException(), isNull);
  });
}
