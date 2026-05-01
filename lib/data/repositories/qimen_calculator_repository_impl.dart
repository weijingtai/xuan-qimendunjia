import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/model/shi_jia_qi_men.dart' as model;
import '../datasources/calculator/qimen_calculator_data_source.dart';
import '../models/mappers/qimen_pan_mapper.dart';
import '../models/mappers/shi_jia_ju_mapper.dart';

/// 奇门计算器仓储实现
///
/// 接受双维 `Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>`，
/// 按 (jia, arrangeType) 复合键查找具体计算器；未注册组合抛
/// [UnsupportedJiaArrangeException]。
class QiMenCalculatorRepositoryImpl implements QiMenCalculatorRepository {
  final Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>> _calculators;

  QiMenCalculatorRepositoryImpl(this._calculators);

  @override
  Future<ShiJiaJu> calculateJu({
    required DateTime dateTime,
    required QiMenJia jia,
    required ArrangeType arrangeType,
  }) async {
    final familyMap = _calculators[jia];
    final calculator = familyMap?[arrangeType];
    if (calculator == null) {
      throw UnsupportedJiaArrangeException(jia, arrangeType);
    }

    try {
      // 调用计算器计算
      final modelJu = await calculator.calculate(dateTime);

      // 转换为 Entity
      return ShiJiaJuMapper.fromModel(modelJu);
    } catch (e) {
      if (e is UnsupportedJiaArrangeException) rethrow;
      throw QiMenCalculationException('计算局数失败: $e');
    }
  }

  @override
  Future<QiMenPan> arrangePan({
    required ShiJiaJu ju,
    required PlateType plateType,
    required PanSettings settings,
  }) async {
    try {
      // 将 Entity 转换为 Model
      final modelJu = ShiJiaJuMapper.toModel(ju);

      // 转换 PanSettings 为 PanArrangeSettings
      final modelSettings = PanArrangeSettings(
        arrangeType: settings.arrangeType,
        jiGong: settings.jiGong,
        starMonthTokenType: settings.starMonthTokenType,
        starFourWeiGongType: settings.starFourWeiGongType,
        doorFourWeiGongType: settings.doorFourWeiGongType,
        godWithGongTypeEnum: settings.godWithGongType,
        ganGongType: settings.ganGongType,
      );

      // 调用排盘逻辑（Phase 1 仅时家；Phase 2/3/4 在此按 ju.jia 派发）
      final modelPan = model.ShiJiaQiMen(
        plateType: plateType,
        shiJiaJu: modelJu,
        settings: modelSettings,
      );

      // 转换为 Entity
      return QiMenPanMapper.fromModel(modelPan);
    } catch (e) {
      throw QiMenCalculationException('排盘失败: $e');
    }
  }
}

