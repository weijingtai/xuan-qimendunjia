import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

void main() {
  test('check day', () {
    final dt = DateTime(2026, 5, 25, 17, 40);
    final solar = Solar.fromFullDate(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    final lunar = Lunar.fromSolar(solar);
    print('DATE_CHECK: ${lunar.getDayInGanZhi()}');
  });
}
