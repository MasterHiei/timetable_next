// Changes from upstream: fixed animation completion, activity notification, reentry and disposal.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Interval;

import '../config.dart';
import '../utils.dart';
import 'visible_date_range.dart';

/// Controls the visible dates in Timetable widgets.
///
/// Listen to [date] for the current date and [visibleDates] for the visible interval.
///
/// To programmatically change the visible dates, use any of the following
/// functions:
///
/// * [animateToToday], [animateTo], or [animateToPage] if you want an animation
/// * [jumpToToday], [jumpTo], or [jumpToPage] if you don't want an animation
///
/// You can also get and update the [VisibleDateRange] via [visibleRange].
class DateController extends ValueNotifier<DatePageValueWithScrollActivity> {
  DateController({DateTime? initialDate, VisibleDateRange? visibleRange})
    : assert(initialDate.debugCheckIsValidTimetableDate()),
      // We set the correct value in the body below.
      super(
        DatePageValueWithScrollActivity(
          visibleRange ?? VisibleDateRange.week(),
          0,
          const IdleDateScrollActivity(),
        ),
      ) {
    // The correct value is set via the listener when we assign to our value.
    _date = ValueNotifier(DateTimeTimetable.dateFromPage(0));
    addListener(() => _date.value = value.date);

    // The correct value is set via the listener when we assign to our value.
    _visibleDates = ValueNotifier(Interval(DateTime(0), DateTime(0)));
    addListener(() => _visibleDates.value = value.visibleDates);

    final rawStartPage = initialDate?.page ?? DateTimeTimetable.today().page;
    value = value.copyWithActivity(
      page: value.visibleRange.getTargetPageForFocus(rawStartPage),
      activity: const IdleDateScrollActivity(),
    );
  }

  late final ValueNotifier<DateTime> _date;
  ValueListenable<DateTime> get date => _date;

  VisibleDateRange get visibleRange => value.visibleRange;
  set visibleRange(VisibleDateRange visibleRange) {
    if (!_beginOperation()) return;
    value = value.copyWithActivity(
      page: visibleRange.getTargetPageForFocus(value.page),
      visibleRange: visibleRange,
      activity: const IdleDateScrollActivity(),
    );
  }

  late final ValueNotifier<Interval> _visibleDates;
  ValueListenable<Interval> get visibleDates => _visibleDates;

  // Animation
  AnimationController? _animationController;

  Future<void> animateToToday({
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 200),
    required TickerProvider vsync,
  }) {
    return animateTo(
      DateTimeTimetable.today(),
      curve: curve,
      duration: duration,
      vsync: vsync,
    );
  }

  Future<void> animateTo(
    DateTime date, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 200),
    required TickerProvider vsync,
  }) {
    return animateToPage(
      date.page,
      curve: curve,
      duration: duration,
      vsync: vsync,
    );
  }

  Future<void> animateToPage(
    double page, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 200),
    required TickerProvider vsync,
  }) async {
    if (!_beginOperation()) return;
    final controller = AnimationController(
      debugLabel: 'DateController',
      vsync: vsync,
    );
    _animationController = controller;

    final previousPage = value.page;
    final targetPage = value.visibleRange.getTargetPageForFocus(page);
    final targetDatePageValue = DatePageValue(visibleRange, targetPage);
    controller.addListener(() {
      value = value.copyWithActivity(
        page: lerpDouble(previousPage, targetPage, controller.value)!,
        activity: controller.isAnimating
            ? DrivenDateScrollActivity(targetDatePageValue)
            : const IdleDateScrollActivity(),
      );
    });

    try {
      await controller.animateTo(1, duration: duration, curve: curve).orCancel;
    } on TickerCanceled {
      // Interruption completes the public future without reaching the target.
    } finally {
      // A replacement animation owns its own controller and must survive cleanup.
      if (identical(_animationController, controller)) {
        _animationController = null;
        controller.dispose();
      }
    }
  }

  void jumpToToday() => jumpTo(DateTimeTimetable.today());
  void jumpTo(DateTime date) {
    assert(date.debugCheckIsValidTimetableDate());
    jumpToPage(date.page);
  }

  void jumpToPage(double page) {
    if (!_beginOperation()) return;
    value = value.copyWithActivity(
      page: value.visibleRange.getTargetPageForFocus(page),
      activity: const IdleDateScrollActivity(),
    );
  }

  int _operation = 0;

  // Idle notifications can start a newer operation synchronously.
  bool _beginOperation() {
    assert(!_isDisposed);
    if (_isDisposed) return false;
    final operation = ++_operation;
    _cancelAnimation();
    return operation == _operation && !_isDisposed;
  }

  void cancelAnimation() {
    _operation++;
    _cancelAnimation();
  }

  void _cancelAnimation({bool notifyIdle = true}) {
    final controller = _animationController;
    if (controller == null) return;
    // Detach before notifying listeners, which can start another animation.
    _animationController = null;
    controller.dispose();
    if (notifyIdle) {
      value = value.copyWithActivity(activity: const IdleDateScrollActivity());
    }
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  @override
  void dispose() {
    assert(!_isDisposed);
    _isDisposed = true;
    _operation++;
    _cancelAnimation(notifyIdle: false);
    _date.dispose();
    _visibleDates.dispose();
    super.dispose();
  }
}

/// The value held by [DateController].
@immutable
class DatePageValue with Diagnosticable {
  const DatePageValue(this.visibleRange, this.page);

  final VisibleDateRange visibleRange;
  int get visibleDayCount => visibleRange.visibleDayCount;

  final double page;
  DateTime get date => DateTimeTimetable.dateFromPage(page.round());

  int get firstVisiblePage => page.floor();

  /// The first date that is at least partially visible.
  DateTime get firstVisibleDate {
    final result = DateTimeTimetable.dateFromPage(firstVisiblePage);
    assert(result.debugCheckIsValidTimetableDate());
    return result;
  }

  int get lastVisiblePage => page.ceil() + visibleDayCount - 1;

  /// The last date that is at least partially visible.
  DateTime get lastVisibleDate {
    final result = DateTimeTimetable.dateFromPage(lastVisiblePage);
    assert(result.debugCheckIsValidTimetableDate());
    return result;
  }

  /// The interval of dates that are at least partially visible.
  Interval get visibleDates {
    final result = Interval(firstVisibleDate, lastVisibleDate.atEndOfDay);
    assert(result.debugCheckIsValidTimetableDateInterval());
    return result;
  }

  Iterable<DateTime> get visibleDatesIterable sync* {
    var currentDate = firstVisibleDate;
    while (currentDate <= lastVisibleDate) {
      yield currentDate;
      currentDate = currentDate.add(1.days);
    }
  }

  DatePageValue copyWith({VisibleDateRange? visibleRange, double? page}) =>
      DatePageValue(visibleRange ?? this.visibleRange, page ?? this.page);

  @override
  int get hashCode => Object.hash(visibleRange, page);
  @override
  bool operator ==(Object other) {
    return other is DatePageValue &&
        runtimeType == other.runtimeType &&
        visibleRange == other.visibleRange &&
        page == other.page;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('visibleRange', visibleRange));
    properties.add(DoubleProperty('page', page));
    properties.add(DateDiagnosticsProperty('date', date));
  }
}

class DatePageValueWithScrollActivity extends DatePageValue {
  const DatePageValueWithScrollActivity(
    super.visibleRange,
    super.page,
    this.activity,
  );

  final DateScrollActivity activity;

  // Activity transitions must notify listeners even when the page is unchanged.
  @override
  int get hashCode => Object.hash(super.hashCode, activity);

  @override
  bool operator ==(Object other) =>
      other is DatePageValueWithScrollActivity &&
      super == other &&
      activity == other.activity;

  DatePageValueWithScrollActivity copyWithActivity({
    VisibleDateRange? visibleRange,
    double? page,
    required DateScrollActivity activity,
  }) {
    return DatePageValueWithScrollActivity(
      visibleRange ?? this.visibleRange,
      page ?? this.page,
      activity,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('activity', activity));
  }
}

/// The equivalent of [ScrollActivity] for [DateController].
@immutable
abstract class DateScrollActivity with Diagnosticable {
  const DateScrollActivity();
}

/// A scroll activity that does nothing.
class IdleDateScrollActivity extends DateScrollActivity {
  const IdleDateScrollActivity();
}

/// The activity a [DateController] performs when the user drags their finger
/// across the screen and is settling afterwards.
class DragDateScrollActivity extends DateScrollActivity {
  const DragDateScrollActivity();
}

/// A scroll activity for when the [DateController] is animated to a new page.
class DrivenDateScrollActivity extends DateScrollActivity {
  const DrivenDateScrollActivity(this.target);

  final DatePageValue target;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('target', target));
  }
}

/// Provides the [DateController] for Timetable widgets below it.
///
/// See also:
///
/// * [TimetableConfig], which bundles multiple configuration widgets for
///   Timetable.
class DefaultDateController extends InheritedWidget {
  const DefaultDateController({
    super.key,
    required this.controller,
    required super.child,
  });

  final DateController controller;

  @override
  bool updateShouldNotify(DefaultDateController oldWidget) =>
      controller != oldWidget.controller;

  static DateController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DefaultDateController>()
        ?.controller;
  }
}
