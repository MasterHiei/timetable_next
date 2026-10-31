import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable_next/src/utils/listenable.dart';

class _Source extends ValueNotifier<int> {
  _Source() : super(0);
  bool get observed => hasListeners;
}

void main() {
  test(
    'mapped values release their source after the last observer detaches',
    () {
      final source = _Source();
      final mapped = source.map((value) => value.isEven);
      var notifications = 0;
      void listener() => notifications++;
      mapped.addListener(listener);
      expect(source.observed, isTrue);
      expect(mapped.value, isTrue);
      source.value = 2;
      expect(notifications, 0);
      source.value = 3;
      expect(mapped.value, isFalse);
      expect(notifications, 1);
      mapped.removeListener(listener);
      expect(source.observed, isFalse);
      source.value = 4;
      expect(mapped.value, isTrue);
      mapped.addListener(listener);
      source.value = 5;
      expect(notifications, 2);
      (mapped as ChangeNotifier).dispose();
      expect(source.observed, isFalse);
      source.dispose();
    },
  );
}
