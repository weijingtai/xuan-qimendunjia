import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';
import 'package:xuan_time_location/xuan_time_location.dart';

import 'qimen_calculation_context.dart';
import 'qimen_chart_calculator.dart';
import 'qimen_chart_params.dart';

/// 奇门遁甲管线编排器，参照铁板神数 TiebanPipelineExecutor 结构。
///
/// 每次排盘会变的数据（时刻、params）统一走 [ChartRequest]；
/// 跨次排盘不变的 momentResolver、recordRepository 作为构造参数注入。
final class QimenPipelineExecutor {
  final MomentResolver _momentResolver;

  /// 可选注入的落库仓储（domain/pipeline 层可触达 repository interface）。
  final QimenRecordRepository? _recordRepository;

  QimenPipelineExecutor({
    MomentResolver? momentResolver,
    QimenRecordRepository? recordRepository,
  }) : _momentResolver = momentResolver ?? const DefaultMomentResolver(),
       _recordRepository = recordRepository;

  /// 执行奇门管线：加载 context → 构造 calculator → 计算合约。
  Future<QimenDivinationRecordContract> execute(
    ChartRequest<QimenChartParams> request,
  ) async {
    final moment = _momentResolver.resolve(request.moment);
    final context = await QimenCalculationContext.load();
    final calculator = QimenChartCalculator(context: context);
    return calculator.calculate(moment, request.params);
  }

  /// 排盘并落库 Record；未注入仓储时仅排盘不落库。
  Future<Chart> executeAndSave(
    ChartRequest<QimenChartParams> request,
  ) async {
    final contract = await execute(request);
    final repo = _recordRepository;
    if (repo != null) {
      await repo.saveRecord(contract);
    }
    return contract;
  }
}
