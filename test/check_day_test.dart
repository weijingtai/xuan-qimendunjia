import 'package:flutter_test/flutter_test.dart';
import 'package:tyme/tyme.dart';

void main() {
  test('check day', () {
    final dt = DateTime(2026, 5, 25, 17, 40);
    final solar = SolarDay.fromYmd(dt.year, dt.month, dt.day);
    final lunar = solar.getLunarDay();
    print('DATE_CHECK: ${lunar.getSixtyCycle().getName()}');
  });
}
