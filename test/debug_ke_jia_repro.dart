import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/data/repositories/qimen_calculator_repository_impl.dart';
import 'package:qimendunjia/data/datasources/calculator/qimen_calculator_data_source.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/utils/ke_jia_qi_men_ju_calculator.dart';

/// 用于 debug：直接调用刻家 calculator + 排盘，把 stack trace 打出来。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repro KeJia arrange error', () async {
    final dt = DateTime(2026, 5, 5, 14, 30);
    print('--- 1. KeJiaQiMenJuCalculator.calculate() ---');
    final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();
    print('KeJiaJu: jia=${ju.jia.name} juNumber=${ju.juNumber} '
        'yinYangDun=${ju.yinYangDun.name} keIndex=${ju.keIndex} '
        'shiJiaZi=${ju.shiJiaZi.name} keJiaZi=${ju.keJiaZi.name} '
        'initJu=${ju.initJuNumber} fourZhu="${ju.fourZhuEightChar}"');

    print('--- 2. arrangePan() ---');
    final repo = QiMenCalculatorRepositoryImpl({
      QiMenJia.KE: {
        for (final t in ArrangeType.values) t: KeJiaCalculatorDataSource(),
      },
    });
    try {
      final pan = await repo.arrangePan(
        ju: ju,
        plateType: PlateType.ZHUAN_PAN,
        settings: PanSettings.defaultSettings(),
      );
      print('OK pan.id=${pan.id} gongs=${pan.gongMapper.length}');
    } catch (e, st) {
      print('ERROR: $e');
      print(st);
      rethrow;
    }
  });
}
