import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

import 'qimen_calculation_context.dart';
import 'qimen_chart_calculator.dart';
import 'qimen_chart_params.dart';

/// 奇门遁甲管线编排器，参照铁板神数 TiebanPipelineExecutor 结构。
class QimenPipelineResult {
  final QimenDivinationRecordContract contract;
  const QimenPipelineResult({required this.contract});
}

class QimenPipelineExecutor {
  Future<QimenPipelineResult> execute({
    required ResolvedMoment moment,
    required QimenChartParams params,
  }) async {
    final context = await QimenCalculationContext.load();
    final calculator = QimenChartCalculator(context: context);
    final contract = calculator.calculate(moment, params);
    return QimenPipelineResult(contract: contract);
  }
}
