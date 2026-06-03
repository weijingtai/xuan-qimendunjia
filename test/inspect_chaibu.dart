import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';

void main() {
  test('Inspect ChaiBuCalculator day pillar', () {
    final times = [
      DateTime(2026, 5, 25, 22, 55),
      DateTime(2026, 5, 25, 23, 5),
      DateTime(2026, 5, 26, 0, 5),
      DateTime(2026, 5, 26, 1, 5),
    ];

    for (final dt in times) {
      final ju = ChaiBuCalculator(dateTime: dt).calculate();
      final day = ju.fourZhuEightChar.split(' ')[2];
      print('$dt -> $day');
    }
  });
}
