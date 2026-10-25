// Changes from upstream: updated imports and duration values, removing obsolete example fragments.
import 'dart:math';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:timetable_next/timetable_next.dart';

final positioningDemoEvents = <BasicEvent>[
  _DemoEvent(0, 0, const Duration(hours: 10), const Duration(hours: 11)),
  _DemoEvent(0, 1, const Duration(hours: 11), const Duration(hours: 12)),
  _DemoEvent(0, 2, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(1, 0, const Duration(hours: 10), const Duration(hours: 12)),
  _DemoEvent(1, 1, const Duration(hours: 10), const Duration(hours: 12)),
  _DemoEvent(1, 2, const Duration(hours: 14), const Duration(hours: 16)),
  _DemoEvent(
    1,
    3,
    const Duration(hours: 14, minutes: 15),
    const Duration(hours: 16),
  ),
  _DemoEvent(2, 0, const Duration(hours: 10), const Duration(hours: 20)),
  _DemoEvent(2, 1, const Duration(hours: 10), const Duration(hours: 12)),
  _DemoEvent(2, 2, const Duration(hours: 13), const Duration(hours: 15)),
  _DemoEvent(3, 0, const Duration(hours: 10), const Duration(hours: 20)),
  _DemoEvent(3, 1, const Duration(hours: 12), const Duration(hours: 14)),
  _DemoEvent(3, 2, const Duration(hours: 12), const Duration(hours: 15)),
  _DemoEvent(4, 0, const Duration(hours: 10), const Duration(hours: 13)),
  _DemoEvent(
    4,
    1,
    const Duration(hours: 10, minutes: 15),
    const Duration(hours: 13),
  ),
  _DemoEvent(
    4,
    2,
    const Duration(hours: 10, minutes: 30),
    const Duration(hours: 13),
  ),
  _DemoEvent(
    4,
    3,
    const Duration(hours: 10, minutes: 45),
    const Duration(hours: 13),
  ),
  _DemoEvent(4, 4, const Duration(hours: 11), const Duration(hours: 13)),
  _DemoEvent(
    5,
    0,
    const Duration(hours: 10, minutes: 30),
    const Duration(hours: 13, minutes: 30),
  ),
  _DemoEvent(
    5,
    1,
    const Duration(hours: 10, minutes: 30),
    const Duration(hours: 13, minutes: 30),
  ),
  _DemoEvent(
    5,
    2,
    const Duration(hours: 10, minutes: 30),
    const Duration(hours: 12, minutes: 30),
  ),
  _DemoEvent(
    5,
    3,
    const Duration(hours: 8, minutes: 30),
    const Duration(hours: 18),
  ),
  _DemoEvent(
    5,
    4,
    const Duration(hours: 15, minutes: 30),
    const Duration(hours: 16),
  ),
  _DemoEvent(5, 5, const Duration(hours: 11), const Duration(hours: 12)),
  _DemoEvent(5, 6, const Duration(hours: 1), const Duration(hours: 2)),
  _DemoEvent(
    6,
    0,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 15, minutes: 30),
  ),
  _DemoEvent(6, 1, const Duration(hours: 11), const Duration(hours: 13)),
  _DemoEvent(
    6,
    2,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 11, minutes: 30),
  ),
  _DemoEvent(
    6,
    3,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 10, minutes: 30),
  ),
  _DemoEvent(6, 4, const Duration(hours: 10), const Duration(hours: 11)),
  _DemoEvent(6, 5, const Duration(hours: 10), const Duration(hours: 11)),
  _DemoEvent(
    6,
    6,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 10, minutes: 30),
  ),
  _DemoEvent(
    6,
    7,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 10, minutes: 30),
  ),
  _DemoEvent(
    6,
    8,
    const Duration(hours: 9, minutes: 30),
    const Duration(hours: 10, minutes: 30),
  ),
  _DemoEvent(
    6,
    9,
    const Duration(hours: 10, minutes: 30),
    const Duration(hours: 12, minutes: 30),
  ),
  _DemoEvent(6, 10, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(6, 11, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(6, 12, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(6, 13, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(
    6,
    14,
    const Duration(hours: 6, minutes: 30),
    const Duration(hours: 8),
  ),
  _DemoEvent(
    7,
    0,
    const Duration(hours: 2, minutes: 30),
    const Duration(hours: 4, minutes: 30),
  ),
  _DemoEvent(
    7,
    1,
    const Duration(hours: 2, minutes: 30),
    const Duration(hours: 3, minutes: 30),
  ),
  _DemoEvent(7, 2, const Duration(hours: 3), const Duration(hours: 4)),
  _DemoEvent(
    8,
    0,
    const Duration(hours: 20),
    const Duration(hours: 4),
    endDateOffset: 1,
  ),
  _DemoEvent(9, 1, const Duration(hours: 12), const Duration(hours: 16)),
  _DemoEvent(9, 2, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(9, 3, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(9, 4, const Duration(hours: 12), const Duration(hours: 13)),
  _DemoEvent(9, 5, const Duration(hours: 15), const Duration(hours: 16)),
  _DemoEvent.allDay(0, 0, 1),
  _DemoEvent.allDay(1, 1, 1),
  _DemoEvent.allDay(2, 0, 2),
  _DemoEvent.allDay(3, 2, 2),
  _DemoEvent.allDay(4, 2, 2),
  _DemoEvent.allDay(5, 1, 2),
  _DemoEvent.allDay(6, 3, 2),
  _DemoEvent.allDay(7, 4, 4),
  _DemoEvent.allDay(8, -1, 4),
  _DemoEvent.allDay(9, -1, 2),
  _DemoEvent.allDay(10, 1, 3),
  _DemoEvent.allDay(11, -2, 2),
  _DemoEvent.allDay(12, -3, 2),
];

class _DemoEvent extends BasicEvent {
  _DemoEvent(
    int demoId,
    int eventId,
    Duration start,
    Duration end, {
    int endDateOffset = 0,
  }) : super(
         id: '$demoId-$eventId',
         title: '$demoId-$eventId',
         backgroundColor: _getColor('$demoId-$eventId'),
         start: DateTimeTimetable.today()
             .add(Duration(days: demoId))
             .add(start),
         end: DateTimeTimetable.today()
             .add(Duration(days: demoId + endDateOffset))
             .add(end),
       );

  _DemoEvent.allDay(int id, int startOffset, int length)
    : super(
        id: 'a-$id',
        title: 'a-$id',
        backgroundColor: _getColor('a-$id'),
        start: DateTimeTimetable.today().add(Duration(days: startOffset)),
        end: DateTimeTimetable.today().add(
          Duration(days: startOffset + length),
        ),
      );

  static Color _getColor(String id) {
    return Random(
      id.hashCode,
    ).nextColorHsv(saturation: 0.6, value: 0.8, alpha: 1).toColor();
  }
}

List<TimeOverlay> positioningDemoOverlayProvider(
  BuildContext context,
  DateTime date,
) {
  assert(date.debugCheckIsValidTimetableDate());

  final widget = ColoredBox(
    color: context.theme.brightness.contrastColor.withValues(alpha: 0.1),
  );

  if (DateTime.monday <= date.weekday && date.weekday <= DateTime.friday) {
    return [
      TimeOverlay(
        start: Duration.zero,
        end: const Duration(hours: 8),
        widget: widget,
      ),
      TimeOverlay(
        start: const Duration(hours: 20),
        end: const Duration(days: 1),
        widget: widget,
      ),
    ];
  } else {
    return [
      TimeOverlay(
        start: Duration.zero,
        end: const Duration(days: 1),
        widget: widget,
      ),
    ];
  }
}
