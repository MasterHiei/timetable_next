import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/timetable_next.dart';

Widget _app(
  Widget child,
  DateController date,
  TimeController time, {
  List<BasicEvent> events = const [],
  TimetableCallbacks? callbacks,
}) => MaterialApp(
  localizationsDelegates: const [TimetableLocalizationsDelegate()],
  home: Scaffold(
    body: TimetableConfig<BasicEvent>(
      dateController: date,
      timeController: time,
      eventProvider: eventProviderFromFixedList(events),
      callbacks: callbacks,
      eventBuilder: (_, event) => BasicEventWidget(event),
      allDayEventBuilder: (_, event, info) =>
          BasicAllDayEventWidget(event, info: info),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('non-stacking events expand into unused adjacent columns', (
    tester,
  ) async {
    final day = DateTime.utc(2024, 2, 26);
    BasicEvent event(String id, int start, int end, {int minute = 0}) =>
        BasicEvent(
          id: id,
          title: id,
          backgroundColor: Colors.blue,
          start: day.add(Duration(hours: start, minutes: minute)),
          end: day.add(Duration(hours: end)),
        );
    final events = [
      event('long', 8, 12),
      event('left', 9, 10),
      event('right', 9, 10, minute: 15),
      event('expanded', 11, 12),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 480,
              child: DateEvents<BasicEvent>(
                date: day,
                events: events,
                style: const DateEventsStyle.raw(
                  minEventDuration: Duration.zero,
                  minEventHeight: 0,
                  padding: EdgeInsets.zero,
                  enableStacking: false,
                  minEventDeltaForStacking: Duration.zero,
                  stackedEventSpacing: 0,
                ),
                eventBuilder: (_, event) =>
                    SizedBox(key: ValueKey(event.id.toString())),
              ),
            ),
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(DateEvents<BasicEvent>));
    for (final (id, expected) in [
      ('long', const Rect.fromLTWH(0, 160, 100, 80)),
      ('left', const Rect.fromLTWH(100, 180, 100, 20)),
      ('right', const Rect.fromLTWH(200, 185, 100, 15)),
      ('expanded', const Rect.fromLTWH(100, 220, 200, 20)),
    ]) {
      expect(
        tester.getRect(find.byKey(ValueKey(id))).shift(-origin),
        rectMoreOrLessEquals(expected),
      );
    }
    expect(events.map((event) => event.id), [
      'long',
      'left',
      'right',
      'expanded',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'minimal configuration composes overlays and maps background taps',
    (tester) async {
      final day = DateTime.utc(2024, 2, 26);
      String? overlayTapped;
      final behind = GestureDetector(
        key: const ValueKey('behind'),
        onTap: () => overlayTapped = 'behind',
        child: const ColoredBox(color: Colors.red),
      );
      final front = GestureDetector(
        key: const ValueKey('front'),
        onTap: () => overlayTapped = 'front',
        child: const ColoredBox(color: Colors.green),
      );
      final provider = mergeTimeOverlayProviders([
        (_, date) => [
          TimeOverlay(
            start: const Duration(hours: 9),
            end: const Duration(hours: 10),
            widget: behind,
          ),
        ],
        (_, date) => [
          TimeOverlay(
            start: const Duration(hours: 9, minutes: 30),
            end: const Duration(hours: 10, minutes: 30),
            widget: front,
            position: TimeOverlayPosition.inFrontOfEvents,
          ),
        ],
      ]);
      DateTime? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimetableConfig<BasicEvent>(
              eventBuilder: (_, _) => const SizedBox(),
              child: Builder(
                builder: (context) {
                  expect(DefaultDateController.of(context), isNotNull);
                  expect(DefaultTimeController.of(context), isNotNull);
                  final events = DefaultEventProvider.of<BasicEvent>(context)!(
                    day.fullDayInterval,
                  );
                  expect(events, isEmpty);
                  final overlays = provider(context, day);
                  expect(overlays.map((overlay) => overlay.widget), [
                    behind,
                    front,
                  ]);
                  return Center(
                    child: SizedBox(
                      width: 300,
                      height: 480,
                      child: DateContent<BasicEvent>(
                        date: day,
                        events: events,
                        overlays: overlays,
                        onBackgroundTap: (value) => tapped = value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(DateContent<BasicEvent>));
      expect(
        tester.getRect(find.byKey(const ValueKey('behind'))).shift(-origin),
        rectMoreOrLessEquals(const Rect.fromLTWH(0, 180, 300, 20)),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('front'))).shift(-origin),
        rectMoreOrLessEquals(const Rect.fromLTWH(0, 190, 300, 20)),
      );
      await tester.tapAt(origin + const Offset(150, 195));
      expect(overlayTapped, 'front');
      expect(tapped, isNull);
      await tester.tapAt(origin + const Offset(150, 300));
      expect(tapped, DateTime.utc(2024, 2, 26, 15));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit drag geometries resolve the target viewport and fallback',
    (tester) async {
      final day = DateTime.utc(2024, 2, 26);
      final date = DateController(
        initialDate: day,
        visibleRange: VisibleDateRange.fixed(day, 1),
      );
      final time = TimeController();
      final left = GlobalKey<MultiDateContentGeometry>();
      final right = GlobalKey<MultiDateContentGeometry>();
      GlobalKey<MultiDateContentGeometry>? target;
      DateTime? dropped;
      var updates = 0;
      var starts = 0;
      final source = PartDayDraggableEvent.forGeometryKeys(
        {left, right},
        onDragStart: () => starts++,
        onDragUpdate: (key, value) {
          target = key;
          updates++;
        },
        onDragEnd: (key, value) {
          target = key;
          dropped = value;
        },
        child: const SizedBox(
          key: ValueKey('source'),
          width: 100,
          height: 40,
          child: ColoredBox(color: Colors.red),
        ),
      );
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              source,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: MultiDateContent<BasicEvent>(geometryKey: left),
                    ),
                    Expanded(
                      child: MultiDateContent<BasicEvent>(geometryKey: right),
                    ),
                  ],
                ),
              ),
            ],
          ),
          date,
          time,
        ),
      );
      await tester.pumpAndSettle();
      final box = right.currentContext!.findRenderObject()! as RenderBox;
      final destination = box.localToGlobal(box.size.center(Offset.zero));
      expect(right.currentState!.contains(destination), isTrue);
      expect(left.currentState!.contains(destination), isFalse);
      expect(
        right.currentState!.resolveOffset(destination),
        day.add(const Duration(hours: 12)),
      );
      final sourceStart =
          tester.getTopLeft(find.byKey(const ValueKey('source'))) +
          const Offset(8, 8);
      final drag = await tester.startGesture(sourceStart);
      await tester.pump(kLongPressTimeout);
      await drag.moveTo(destination);
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(updates, greaterThan(0));
      expect(target, right);
      final expected = day.add(
        Duration(
          microseconds:
              ((0.5 - 8 / box.size.height) *
                      const Duration(days: 1).inMicroseconds)
                  .round(),
        ),
      );
      expect(
        dropped!.difference(expected).inMicroseconds.abs(),
        lessThanOrEqualTo(2000),
      );
      final fallback = await tester.startGesture(sourceStart);
      await tester.pump(kLongPressTimeout);
      await fallback.moveTo(const Offset(10, 10));
      await tester.pump();
      await fallback.up();
      await tester.pumpAndSettle();
      expect(target, left);
      await tester.pumpWidget(const SizedBox());
      date.dispose();
      time.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all-day overflow, changing row limits and background taps retain dates',
    (tester) async {
      final day = DateTime.utc(2024, 2, 26);
      final date = DateController(
        initialDate: day,
        visibleRange: VisibleDateRange.days(3, alignmentDate: day),
      );
      final time = TimeController();
      final events = [
        for (var i = 0; i < 4; i++)
          BasicEvent(
            id: i,
            title: 'event $i',
            backgroundColor: Colors.blue,
            start: day,
            end: day.add(const Duration(days: 1)),
          ),
      ];
      DateTime? overflowDate;
      DateTime? backgroundDate;
      Widget view(int rows, {double height = 120}) => _app(
        SizedBox(
          width: 600,
          height: height,
          child: MultiDateEventHeader<BasicEvent>(
            style: MultiDateEventHeaderStyle.raw(maxEventRows: rows),
          ),
        ),
        date,
        time,
        events: events,
        callbacks: TimetableCallbacks(
          onMultiDateHeaderOverflowTap: (value) => overflowDate = value,
          onDateBackgroundTap: (value) => backgroundDate = value,
        ),
      );
      await tester.pumpWidget(view(1));
      await tester.pumpAndSettle();
      expect(find.text('+3'), findsOneWidget);
      await tester.tap(find.text('+3'));
      expect(overflowDate, day);
      await tester.tapAt(const Offset(300, 10));
      expect(backgroundDate, day.add(const Duration(days: 1)));
      await tester.pumpWidget(view(4));
      await tester.pumpAndSettle();
      expect(find.byType(MultiDateEventHeaderOverflow), findsNothing);
      for (var i = 0; i < 4; i++) {
        expect(find.text('event $i'), findsOneWidget);
      }
      await tester.pumpWidget(view(0));
      await tester.pumpAndSettle();
      expect(find.text('+4'), findsOneWidget);
      await tester.pumpWidget(view(1, height: 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MultiDateEventHeader<BasicEvent>)).height,
        0,
      );
      date.jumpTo(day.add(const Duration(days: 4)));
      await tester.pumpAndSettle();
      expect(find.byType(MultiDateEventHeaderOverflow), findsNothing);
      await tester.pumpWidget(const SizedBox());
      date.dispose();
      time.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'half-hour labels align inside the column and expose intrinsic width',
    (tester) async {
      Widget labels(TextDirection direction) => MaterialApp(
        localizationsDelegates: const [TimetableLocalizationsDelegate()],
        home: Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 300,
              child: TimeIndicators.halfHours(
                firstHalfHour: 0,
                lastHalfHour: 1,
                alignFirstAndLastLabelsInside: true,
                styleProvider: (time) => TimeIndicatorStyle.raw(
                  textStyle: const TextStyle(fontSize: 12),
                  label: time == Duration.zero ? 'midnight' : 'half past',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(labels(TextDirection.ltr));
      final render = tester.renderObject<RenderBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is MultiChildRenderObjectWidget &&
              widget.children.length == 2 &&
              widget.children.every((child) => child is TimeIndicatorsChild),
        ),
      );
      expect(render.getMinIntrinsicWidth(300), greaterThan(0));
      expect(
        render.getMaxIntrinsicWidth(300),
        greaterThanOrEqualTo(render.getMinIntrinsicWidth(300)),
      );
      expect(() => render.getMinIntrinsicHeight(100), throwsException);
      expect(() => render.getMaxIntrinsicHeight(100), throwsException);
      final bounds = tester.getRect(find.byType(TimeIndicators));
      expect(bounds.contains(tester.getTopLeft(find.text('midnight'))), isTrue);
      await tester.pumpWidget(labels(TextDirection.rtl));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(height: 100, child: TimeIndicators(children: [])),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
