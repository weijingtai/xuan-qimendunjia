import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:metaphysics_core/models/eight_chars.dart';
import 'package:metaphysics_core/models/divination_datetime.dart';
import 'package:metaphysics_core/models/jie_qi_info.dart';
import 'package:qimendunjia/domain/pipeline/qimen_calculation_context.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_calculator.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_params.dart';
import 'package:qimendunjia/domain/pipeline/qimen_pipeline_executor.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

void main() {
  group('QimenPipelineExecutor', () {
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

    final executor = QimenPipelineExecutor(
      momentResolver: _FixedMomentResolver(),
    );

    test('qimen_executor_produces_contract', () async {
      final contract = await executor.execute(
        ChartRequest<QimenChartParams>(
          moment: fixedMoment.source,
          params: baseParams,
        ),
      );

      expect(contract.uuid, equals('test-uuid-001'));
      expect(contract.createdAt, equals(DateTime(2024, 8, 6, 8, 22, 0, 0, 0)));
      expect(contract.juType, equals('时家'));
      expect(contract.juNumber, equals(1));
    });

    test('qimen_executor_matches_direct_calculator_call', () async {
      final result = await executor.execute(
        ChartRequest<QimenChartParams>(
          moment: fixedMoment.source,
          params: baseParams,
        ),
      );

      final calculator = QimenChartCalculator(
        context: await QimenCalculationContext.load(),
      );
      final directContract = calculator.calculate(fixedMoment, baseParams);

      expect(result.toJson(), directContract.toJson());
    });

    test('qimen_executor_is_deterministic', () async {
      final request = ChartRequest<QimenChartParams>(
        moment: fixedMoment.source,
        params: baseParams,
      );
      final result1 = await executor.execute(request);
      final result2 = await executor.execute(request);

      expect(result1.toJson(), result2.toJson());
    });
  });
}

/// 固定 ResolvedMoment，隔离真实历法计算。
class _FixedMomentResolver implements MomentResolver {
  const _FixedMomentResolver();

  @override
  ResolvedMoment resolve(DivinationMoment moment) => ResolvedMoment(
        source: moment,
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

  @override
  List<ResolvedMoment> resolveCandidates(
    DivinationMoment moment,
    CandidateSpec spec,
  ) => [];
}
