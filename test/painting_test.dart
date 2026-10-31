import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

void main() {
  test(
    'now shapes interpolate at both viewport edges and retain value semantics',
    () {
      final circle = CircleNowIndicatorShape(color: Colors.red, radius: 8);
      final triangle = TriangleNowIndicatorShape(color: Colors.green, size: 8);
      for (final shape in <NowIndicatorShape>[
        circle,
        triangle,
        const EmptyNowIndicatorShape(),
      ]) {
        expect(shape.copyWith(), shape);
        expect(shape.copyWith().hashCode, shape.hashCode);
        expect(
          shape.interpolateSizeBasedOnVisibility(
            8,
            const Size(100, 20),
            -25,
            25,
          ),
          4,
        );
        expect(
          shape.interpolateSizeBasedOnVisibility(
            8,
            const Size(100, 20),
            75,
            125,
          ),
          4,
        );
        expect(
          shape.interpolateSizeBasedOnVisibility(8, const Size(100, 20), 0, 50),
          8,
        );
      }
      expect(
        circle.copyWith(color: Colors.blue, radius: 3),
        CircleNowIndicatorShape(color: Colors.blue, radius: 3),
      );
      expect(
        triangle.copyWith(color: Colors.blue, size: 3),
        TriangleNowIndicatorShape(color: Colors.blue, size: 3),
      );
      expect(
        (Canvas canvas) =>
            circle.paint(canvas, const Size(100, 20), -25, 25, 10),
        paints..circle(x: 0, y: 10, radius: 4, color: Colors.red),
      );
      expect(
        (Canvas canvas) =>
            triangle.paint(canvas, const Size(100, 20), 0, 50, 10),
        paints..path(color: Colors.green),
      );
      expect(
        (Canvas canvas) => const EmptyNowIndicatorShape().paint(
          canvas,
          const Size(100, 20),
          0,
          50,
          10,
        ),
        paintsNothing,
      );
    },
  );
  test('all-day borders preserve clipping geometry through scaling', () {
    const info = AllDayEventLayoutInfo(hiddenStartDays: 0, hiddenEndDays: 0);
    const radii = AllDayEventBorderRadii(
      cornerRadius: BorderRadius.all(Radius.circular(4)),
      leftTipRadius: 4,
      rightTipRadius: 4,
    );
    const border = AllDayEventBorder(
      info: info,
      side: BorderSide(color: Colors.blue, width: 2),
      radii: radii,
    );
    expect(
      info.hashCode,
      const AllDayEventLayoutInfo(
        hiddenStartDays: 0,
        hiddenEndDays: 0,
      ).hashCode,
    );
    expect(
      border.hashCode,
      const AllDayEventBorder(
        info: info,
        side: BorderSide(color: Colors.blue, width: 2),
        radii: radii,
      ).hashCode,
    );
    expect(
      border,
      const AllDayEventBorder(
        info: info,
        side: BorderSide(color: Colors.blue, width: 2),
        radii: radii,
      ),
    );
    expect(border.dimensions, const EdgeInsets.all(2));
    expect(
      border.getOuterPath(const Rect.fromLTWH(0, 0, 100, 20)).getBounds(),
      const Rect.fromLTWH(0, 0, 100, 20),
    );
    expect(
      border.getInnerPath(const Rect.fromLTWH(0, 0, 100, 20)).getBounds(),
      const Rect.fromLTWH(2, 2, 96, 16),
    );
    final scaled = border.scale(0.5) as AllDayEventBorder;
    expect(scaled.side.width, 1);
    expect(scaled.radii.leftTipRadius, 2);
    expect(scaled.radii.cornerRadius.topLeft, const Radius.circular(2));
    for (final width in [1.0, 100.0]) {
      final clipped = radii.getPath(
        Size(width, 20),
        const AllDayEventLayoutInfo(hiddenStartDays: 2, hiddenEndDays: 2),
      );
      expect(clipped.contains(Offset(width / 2, 10)), isTrue);
    }
    final painter = AllDayEventBackgroundPainter(
      info: info,
      color: Colors.red,
      radii: radii,
    );
    expect(
      painter.shouldRepaint(
        AllDayEventBackgroundPainter(
          info: info,
          color: Colors.red,
          radii: radii,
        ),
      ),
      isFalse,
    );
    expect(
      painter.shouldRepaint(
        AllDayEventBackgroundPainter(
          info: info,
          color: Colors.green,
          radii: radii,
        ),
      ),
      isTrue,
    );
    expect(
      (Canvas canvas) => painter.paint(canvas, const Size(100, 20)),
      paints..path(color: Colors.red),
    );
    expect(
      (Canvas canvas) =>
          border.paint(canvas, const Rect.fromLTWH(0, 0, 100, 20)),
      paintsNothing,
    );
  });
}
