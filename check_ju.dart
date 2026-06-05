import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';

void main() {
  final dt = DateTime(2035, 5, 25, 17, 44);
  final shiJiaJu = ChaiBuCalculator(dateTime: dt).calculate();
  print('Date: $dt');
  print('Ju: ${shiJiaJu.juNumber}');
  print('JieQi: ${shiJiaJu.jieQiAt}');
  print('ThreeYuan: ${shiJiaJu.atThreeYuan}');
}
