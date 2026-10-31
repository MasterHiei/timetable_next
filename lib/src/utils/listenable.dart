// Changes from upstream: release mapped subscriptions when their observers detach.
import 'package:flutter/foundation.dart';

typedef Mapper<T, R> = R Function(T);

extension MapValueListenable<T> on ValueListenable<T> {
  ValueListenable<R> map<R>(Mapper<T, R> mapper) =>
      _MapValueListenable(this, mapper);
}

class _MapValueListenable<T, R> extends ChangeNotifier
    implements ValueListenable<R> {
  _MapValueListenable(this.listenable, this.mapper);

  final ValueListenable<T> listenable;
  final Mapper<T, R> mapper;

  late R _value;

  @override
  R get value => hasListeners ? _value : mapper(listenable.value);

  void _listener() {
    final next = mapper(listenable.value);
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    // Build-created mappings must not retain their source after views detach.
    if (!hasListeners) {
      _value = mapper(listenable.value);
      listenable.addListener(_listener);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) listenable.removeListener(_listener);
  }

  @override
  void dispose() {
    if (hasListeners) listenable.removeListener(_listener);
    super.dispose();
  }
}
