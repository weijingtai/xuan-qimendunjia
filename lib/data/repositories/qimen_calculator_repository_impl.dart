import 'package:qimendunjia/domain/entities/base_ju.dart';
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
  Future<BaseJu> calculateJu({
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
      // DataSource 直接返回 domain 层 BaseJu（时家协变返回 ShiJiaJu）
      return await calculator.calculate(dateTime);
    } catch (e) {
      if (e is UnsupportedJiaArrangeException) rethrow;
      throw QiMenCalculationException('计算局数失败: $e');
    }
  }

  @override
  Future<QiMenPan> arrangePan({
    required BaseJu ju,
    required PlateType plateType,
    required PanSettings settings,
  }) async {
    try {
      // 按家派发到具体排盘器
      switch (ju.jia) {
        case QiMenJia.SHI:
          return _arrangeShiJiaPan(ju as ShiJiaJu, plateType, settings);
        case QiMenJia.YUE:
        case QiMenJia.NIAN:
        case QiMenJia.RI:
          throw UnsupportedJiaArrangeException(ju.jia, settings.arrangeType);
      }
    } catch (e) {
      if (e is UnsupportedJiaArrangeException) rethrow;
      throw QiMenCalculationException('排盘失败: $e');
    }
  }

  QiMenPan _arrangeShiJiaPan(
      ShiJiaJu ju, PlateType plateType, PanSettings settings) {
    final modelJu = ShiJiaJuMapper.toModel(ju);
    final modelSettings = PanArrangeSettings(
      arrangeType: settings.arrangeType,
      jiGong: settings.jiGong,
      starMonthTokenType: settings.starMonthTokenType,
      starFourWeiGongType: settings.starFourWeiGongType,
      doorFourWeiGongType: settings.doorFourWeiGongType,
      godWithGongTypeEnum: settings.godWithGongType,
      ganGongType: settings.ganGongType,
    );
    final modelPan = model.ShiJiaQiMen(
      plateType: plateType,
      shiJiaJu: modelJu,
      settings: modelSettings,
    );
    return QiMenPanMapper.fromModel(modelPan);
  }
}

