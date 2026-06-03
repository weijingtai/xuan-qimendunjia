import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';

void main() {
  final dtLate = DateTime(2026, 5, 25, 23, 5);
  final dtEarly = DateTime(2026, 5, 26, 0, 5);

  final juLate = ChaiBuCalculator(dateTime: dtLate).calculate();
  final juEarly = ChaiBuCalculator(dateTime: dtEarly).calculate();

  print('Late (23:05): ${juLate.fourZhuEightChar}');
  print('Early (00:05): ${juEarly.fourZhuEightChar}');
}
