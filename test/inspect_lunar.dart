import 'package:flutter_test/flutter_test.dart';
import 'package:xuan_common/adapters/lunar_adapter.dart';

void main() {
  test('Inspect LunarAdapter day transition', () {
    final times = [
      DateTime(2026, 5, 25, 22, 55),
      DateTime(2026, 5, 25, 23, 5),
    ];

    for (final dt in times) {
      final lunar = LunarAdapter.fromDate(dt);
      print('$dt -> ${lunar.getDayInGanZhi()}');
    }
  });
}
