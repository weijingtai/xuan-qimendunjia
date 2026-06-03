import 'package:flutter_test/flutter_test.dart';
import 'package:xuan_common/adapters/lunar_adapter.dart';

void main() {
  test('Print day pillars', () {
    final dt = DateTime(2026, 5, 25, 12, 0);
    final lunar = LunarAdapter.fromDate(dt);
    print('2026-05-25: ${lunar.getDayInGanZhi()}');
    
    final dtNext = DateTime(2026, 5, 26, 12, 0);
    final lunarNext = LunarAdapter.fromDate(dtNext);
    print('2026-05-26: ${lunarNext.getDayInGanZhi()}');
  });
}
