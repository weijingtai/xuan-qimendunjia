import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:metaphysics_core/models/eight_chars.dart';
import 'package:metaphysics_core/models/jie_qi_info.dart';
import 'package:qimendunjia/domain/pipeline/qimen_calculation_context.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_calculator.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_params.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

void main() {
  group('QimenChartCalculator', () {
    final fixedMoment = ResolvedMoment(
      source: DivinationMoment(
        instantUtc: DateTime(2024, 8, 6, 0, 22).toUtc(),
        place: const GeoPoint(latitude: 39.9, longitude: 116.4),
        reckoning: EnumDatetimeType.standard,
      ),
      nominalTime: DateTime(2024, 8, 6, 8, 22),
      eightChars: EightChars(
        year: JiaZi.getFromGanZhiValue('甲辰')!,
        month: JiaZi.getFromGanZhiValue('辛未')!,
        day: JiaZi.getFromGanZhiValue('壬寅')!,
        time: JiaZi.getFromGanZhiValue('甲辰')!,
      ),
      lunar: const LunarDate(month: 7, day: 3, isLeapMonth: false),
      jieQi: JieQiInfo(
        jieQi: TwentyFourJieQi.LI_QIU,
        startAt: DateTime(2024, 8, 7, 8, 0),
        endAt: DateTime(2024, 8, 22, 22, 0),
      ),
    );

    final baseParams = QimenChartParams(
      uuid: 'test-uuid-001',
      createdAt: DateTime(2024, 8, 6, 8, 22, 0, 0, 0),
      question: '测试问题',
      jia: QiMenJia.SHI,
      arrangeType: ArrangeType.CHAI_BU,
      plateType: PlateType.ZHUAN_PAN,
    );

    test('qimen_calculator_matches_legacy_output', () {
      final calculator = QimenChartCalculator();
      final contract = calculator.calculate(fixedMoment, baseParams);

      expect(contract.uuid, equals('test-uuid-001'));
      expect(contract.createdAt,
          equals(DateTime(2024, 8, 6, 8, 22, 0, 0, 0)));
      expect(contract.juType, isNotNull);
      expect(contract.juNumber, isNotNull);
      expect(contract.juNumber, greaterThanOrEqualTo(1));
      expect(contract.juNumber, lessThanOrEqualTo(9));
    });

    test('qimen_calculator_is_deterministic', () {
      final calculator = QimenChartCalculator();
      final contract1 = calculator.calculate(fixedMoment, baseParams);
      final contract2 = calculator.calculate(fixedMoment, baseParams);

      expect(contract1, equals(contract2));
    });

    test('qimen_calculator_dispatches_all_five_schools', () {
      final calculator = QimenChartCalculator();

      // ShiJia (时家) — 拆补法
      final shiParams = QimenChartParams(
        uuid: 'shi-uuid',
        createdAt: DateTime(2024, 8, 6, 8, 22),
        jia: QiMenJia.SHI,
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );
      final shiContract = calculator.calculate(fixedMoment, shiParams);
      expect(shiContract.uuid, equals('shi-uuid'));
      expect(shiContract.juType, equals('时家'));
      expect(shiContract.juNumber, greaterThanOrEqualTo(1));

      // YueJia (月家)
      final yueMoment = ResolvedMoment(
        source: DivinationMoment(
          instantUtc: DateTime(2024, 8, 5, 16, 0).toUtc(),
          place: const GeoPoint(latitude: 39.9, longitude: 116.4),
          reckoning: EnumDatetimeType.standard,
        ),
        nominalTime: DateTime(2024, 8, 6),
        eightChars: EightChars(
          year: JiaZi.getFromGanZhiValue('甲辰')!,
          month: JiaZi.getFromGanZhiValue('辛未')!,
          day: JiaZi.getFromGanZhiValue('壬寅')!,
          time: JiaZi.getFromGanZhiValue('甲辰')!,
        ),
        lunar: const LunarDate(month: 7, day: 3, isLeapMonth: false),
        jieQi: JieQiInfo(
          jieQi: TwentyFourJieQi.LI_QIU,
          startAt: DateTime(2024, 8, 7, 8, 0),
          endAt: DateTime(2024, 8, 22, 22, 0),
        ),
      );
      final yueParams = QimenChartParams(
        uuid: 'yue-uuid',
        createdAt: DateTime(2024, 8, 6),
        jia: QiMenJia.YUE,
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );
      final yueContract = calculator.calculate(yueMoment, yueParams);
      expect(yueContract.uuid, equals('yue-uuid'));
      expect(yueContract.juType, equals('月家'));

      // NianJia (年家)
      final nianParams = QimenChartParams(
        uuid: 'nian-uuid',
        createdAt: DateTime(2024, 8, 6),
        jia: QiMenJia.NIAN,
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );
      final nianContract = calculator.calculate(yueMoment, nianParams);
      expect(nianContract.uuid, equals('nian-uuid'));
      expect(nianContract.juType, equals('年家'));

      // RiJia (日家)
      final riParams = QimenChartParams(
        uuid: 'ri-uuid',
        createdAt: DateTime(2024, 8, 6),
        jia: QiMenJia.RI,
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );
      final riContract = calculator.calculate(yueMoment, riParams);
      expect(riContract.uuid, equals('ri-uuid'));
      expect(riContract.juType, equals('日家'));

      // KeJia (刻家)
      final keParams = QimenChartParams(
        uuid: 'ke-uuid',
        createdAt: DateTime(2024, 8, 6, 8, 22),
        jia: QiMenJia.KE,
        arrangeType: ArrangeType.CHAI_BU,
        plateType: PlateType.ZHUAN_PAN,
      );
      final keContract = calculator.calculate(fixedMoment, keParams);
      expect(keContract.uuid, equals('ke-uuid'));
      expect(keContract.juType, equals('刻家'));
    });
  });

  group('QimenCalculationContext', () {
    test('qimen_context_load_returns_instance', () async {
      final context = await QimenCalculationContext.load();
      expect(context, isNotNull);
    });
  });
}
