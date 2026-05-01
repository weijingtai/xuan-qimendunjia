import '../../enums/enum_arrange_plate_type.dart';
import '../../enums/enum_qi_men_jia.dart';
import '../entities/base_ju.dart';
import '../repositories/qimen_calculator_repository.dart';
import 'base_usecase.dart';

/// 计算局数用例参数
class CalculateJuParams {
  final DateTime dateTime;
  final QiMenJia jia;
  final ArrangeType arrangeType;

  const CalculateJuParams({
    required this.dateTime,
    this.jia = QiMenJia.SHI,
    required this.arrangeType,
  });
}

/// 计算局数用例
///
/// 负责计算奇门遁甲的局数。
///
/// 返回 [BaseJu]：时家返回 `ShiJiaJu`，月家 `YueJiaJu`，
/// 调用方用 `ju.jia` 或类型守卫处理。
class CalculateJuUseCase extends UseCase<BaseJu, CalculateJuParams> {
  final QiMenCalculatorRepository _repository;

  CalculateJuUseCase(this._repository);

  @override
  Future<BaseJu> execute(CalculateJuParams params) async {
    try {
      return await _repository.calculateJu(
        dateTime: params.dateTime,
        jia: params.jia,
        arrangeType: params.arrangeType,
      );
    } catch (e) {
      if (e is QiMenCalculationException) rethrow;
      throw QiMenCalculationException('计算局数失败: $e');
    }
  }
}
