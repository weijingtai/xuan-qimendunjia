import 'package:metaphysics_core/enums.dart';
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';
import 'package:qimendunjia/data/models/mappers/shi_jia_ju_mapper.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/shi_jia_ju.dart' as model;
import 'package:qimendunjia/utils/ke_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/nian_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/ri_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/utils/yue_jia_qi_men_ju_calculator.dart';
import 'qimen_chart_params.dart';

final class QimenChartCalculator
    implements
        ChartCalculator<QimenChartParams, QimenDivinationRecordContract> {
  const QimenChartCalculator();

  @override
  String get module => 'qimendunjia';

  @override
  QimenDivinationRecordContract calculate(
      ResolvedMoment moment, QimenChartParams params) {
    final dt = moment.nominalTime;

    switch (params.jia) {
      case QiMenJia.SHI:
        return _calculateShiJia(dt, params);
      case QiMenJia.YUE:
        return _calculateYueJia(dt, params);
      case QiMenJia.NIAN:
        return _calculateNianJia(dt, params);
      case QiMenJia.RI:
        return _calculateRiJia(dt, params);
      case QiMenJia.KE:
        return _calculateKeJia(dt, params);
    }
  }

  QimenDivinationRecordContract _calculateShiJia(
      DateTime dt, QimenChartParams params) {
    final modelJu = _computeShiJiaJu(dt, params.arrangeType);
    final entityJu = ShiJiaJuMapper.fromModel(modelJu);
    return QimenDivinationRecordContract(
      uuid: params.uuid,
      createdAt: params.createdAt,
      question: params.question,
      datetimeJson: dt.toIso8601String(),
      juType: entityJu.jia.name,
      juNumber: entityJu.juNumber,
      paramsJson: params.toJson().toString(),
    );
  }

  QimenDivinationRecordContract _calculateYueJia(
      DateTime dt, QimenChartParams params) {
    final strategy = params.arrangeType == ArrangeType.ZHI_RUN
        ? YueJiaSanYuanStrategy.FINE
        : YueJiaSanYuanStrategy.COARSE;
    final ju = YueJiaQiMenJuCalculator(
      dateTime: dt,
      strategy: strategy,
    ).calculate();
    return QimenDivinationRecordContract(
      uuid: params.uuid,
      createdAt: params.createdAt,
      question: params.question,
      datetimeJson: dt.toIso8601String(),
      juType: ju.jia.name,
      juNumber: ju.juNumber,
      paramsJson: params.toJson().toString(),
    );
  }

  QimenDivinationRecordContract _calculateNianJia(
      DateTime dt, QimenChartParams params) {
    final ju = NianJiaQiMenJuCalculator(dateTime: dt).calculate();
    return QimenDivinationRecordContract(
      uuid: params.uuid,
      createdAt: params.createdAt,
      question: params.question,
      datetimeJson: dt.toIso8601String(),
      juType: ju.jia.name,
      juNumber: ju.juNumber,
      paramsJson: params.toJson().toString(),
    );
  }

  QimenDivinationRecordContract _calculateRiJia(
      DateTime dt, QimenChartParams params) {
    final ju = RiJiaQiMenJuCalculator(dateTime: dt).calculate();
    return QimenDivinationRecordContract(
      uuid: params.uuid,
      createdAt: params.createdAt,
      question: params.question,
      datetimeJson: dt.toIso8601String(),
      juType: ju.jia.name,
      juNumber: ju.juNumber,
      paramsJson: params.toJson().toString(),
    );
  }

  QimenDivinationRecordContract _calculateKeJia(
      DateTime dt, QimenChartParams params) {
    final keScheme = params.keScheme ?? KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN;
    final ju = KeJiaQiMenJuCalculator(dateTime: dt, keScheme: keScheme)
        .calculate();
    return QimenDivinationRecordContract(
      uuid: params.uuid,
      createdAt: params.createdAt,
      question: params.question,
      datetimeJson: dt.toIso8601String(),
      juType: ju.jia.name,
      juNumber: ju.juNumber,
      paramsJson: params.toJson().toString(),
    );
  }

  static model.ShiJiaJu _computeShiJiaJu(DateTime dt, ArrangeType arrangeType) {
    switch (arrangeType) {
      case ArrangeType.CHAI_BU:
        return ChaiBuCalculator(dateTime: dt).calculate();
      case ArrangeType.ZHI_RUN:
        return ZhiRunCalculator(dateTime: dt).calculate();
      case ArrangeType.MAO_SHAN:
        return MaoShanCalculator(dateTime: dt).calculate();
      case ArrangeType.YIN_PAN:
        return YinPanCalculator(dateTime: dt).calculate();
      case ArrangeType.MANUALLY:
        return ChaiBuCalculator(dateTime: dt).calculate();
    }
  }
}
