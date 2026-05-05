import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/nian_jia_ju.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/gan_zhi_driven_qi_men_pan.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/model/ri_jia_qi_men.dart';
import 'package:qimendunjia/model/shi_jia_qi_men.dart' as model;
import '../datasources/calculator/qimen_calculator_data_source.dart';
import '../models/mappers/each_gong_mapper.dart';
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
          return _arrangeYueJiaPan(ju as YueJiaJu, plateType, settings);
        case QiMenJia.NIAN:
          return _arrangeNianJiaPan(ju as NianJiaJu, plateType, settings);
        case QiMenJia.RI:
          return _arrangeRiJiaPan(ju as RiJiaJu, plateType, settings);
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

  /// 月家排盘：通过共享 GanZhiDrivenQiMenPan 完成，
  /// 然后组装为 domain 层 QiMenPan。
  ///
  /// 月家 starSet 复用时家北斗九星（[NineStarsEnum]）。
  QiMenPan _arrangeYueJiaPan(
      YueJiaJu ju, PlateType plateType, PanSettings settings) {
    final modelSettings = PanArrangeSettings(
      arrangeType: settings.arrangeType,
      jiGong: settings.jiGong,
      starMonthTokenType: settings.starMonthTokenType,
      starFourWeiGongType: settings.starFourWeiGongType,
      doorFourWeiGongType: settings.doorFourWeiGongType,
      godWithGongTypeEnum: settings.godWithGongType,
      ganGongType: settings.ganGongType,
    );

    final starSet = NineStarsEnum.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    final pan = GanZhiDrivenQiMenPan(
      ju: ju,
      drivingGan: ju.monthGan,
      drivingZhi: ju.monthZhi,
      starSet: starSet,
      qiJuGong: ju.qiJuGong,
      settings: modelSettings,
    );

    // 转 entity 层 EachGong
    final entityGongMapper = pan.gongMapper.map(
      (gua, modelGong) => MapEntry(gua, EachGongMapper.fromModel(modelGong)),
    );

    return QiMenPan(
      id: 'yuejia-${ju.panDateTime.millisecondsSinceEpoch}',
      panDateTime: ju.panDateTime,
      ju: ju,
      plateType: plateType,
      gongMapper: entityGongMapper,
      zhiShiDoor: pan.zhiShiDoor,
      zhiShiDoorAtGong: pan.zhiShiDoorAtGong,
      zhiFuStar: pan.zhiFuStar,
      zhiFuStarAtGong: pan.zhiFuStarAtGong,
      // 月家不参与伏吟反吟判定（占位 false；具体规则待 P3-T1.1 评审）
      isStarFuYin: false,
      isStarFanYin: false,
      isDoorFuYin: false,
      isDoorFanYin: false,
      isGanFuYin: false,
      isGanFanYin: false,
      // 驿马位：月家可由月支推得；占位用 ZI（待评审）
      horseLocation: DiZhi.ZI,
      panGeJuList: null,
    );
  }

  /// 年家排盘：与月家共享 GanZhiDrivenQiMenPan，仅驱动柱与起局机制不同。
  ///
  /// 算法依据：docs/more_qimen/nian_jia_algorithm.md
  /// - 驱动柱 = 年柱（年干→值符 / 年支→值使）
  /// - 起局宫由 NianJiaSanYuanAnchor.sanYuanToQiJuGong 决定（与月家映射不同）
  /// - 星集复用 NineStarsEnum（北斗九星，与时家、月家相同）
  QiMenPan _arrangeNianJiaPan(
      NianJiaJu ju, PlateType plateType, PanSettings settings) {
    final modelSettings = PanArrangeSettings(
      arrangeType: settings.arrangeType,
      jiGong: settings.jiGong,
      starMonthTokenType: settings.starMonthTokenType,
      starFourWeiGongType: settings.starFourWeiGongType,
      doorFourWeiGongType: settings.doorFourWeiGongType,
      godWithGongTypeEnum: settings.godWithGongType,
      ganGongType: settings.ganGongType,
    );

    final starSet = NineStarsEnum.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    final pan = GanZhiDrivenQiMenPan(
      ju: ju,
      drivingGan: ju.yearGan,
      drivingZhi: ju.yearZhi,
      starSet: starSet,
      qiJuGong: ju.qiJuGong,
      settings: modelSettings,
    );

    final entityGongMapper = pan.gongMapper.map(
      (gua, modelGong) => MapEntry(gua, EachGongMapper.fromModel(modelGong)),
    );

    return QiMenPan(
      id: 'nianjia-${ju.panDateTime.millisecondsSinceEpoch}',
      panDateTime: ju.panDateTime,
      ju: ju,
      plateType: plateType,
      gongMapper: entityGongMapper,
      zhiShiDoor: pan.zhiShiDoor,
      zhiShiDoorAtGong: pan.zhiShiDoorAtGong,
      zhiFuStar: pan.zhiFuStar,
      zhiFuStarAtGong: pan.zhiFuStarAtGong,
      // 年家不参与伏吟反吟（与月家相同；占位 false 待评审）
      isStarFuYin: false,
      isStarFanYin: false,
      isDoorFuYin: false,
      isDoorFanYin: false,
      isGanFuYin: false,
      isGanFanYin: false,
      horseLocation: DiZhi.ZI,
      panGeJuList: null,
    );
  }

  /// 日家排盘：独立排盘器（飞盘 + day-count 顺飞 + 不布奇仪 + 不用八神）
  ///
  /// 算法依据：docs/more_qimen/ri_jia_algorithm.md
  /// - 与时/月/年家结构性不同：不复用 GanZhiDrivenQiMenPan
  /// - zhiFuStar 占位用太乙、zhiShiDoor 占位用休门（日家以休门为纲）
  /// - 伏吟反吟语义不适用，全部 false
  /// - 中5也填星（与时家"天禽寄坤"不同），故 gongMapper 含 9 个键
  QiMenPan _arrangeRiJiaPan(
      RiJiaJu ju, PlateType plateType, PanSettings settings) {
    final modelSettings = PanArrangeSettings(
      arrangeType: settings.arrangeType,
      jiGong: settings.jiGong,
      starMonthTokenType: settings.starMonthTokenType,
      starFourWeiGongType: settings.starFourWeiGongType,
      doorFourWeiGongType: settings.doorFourWeiGongType,
      godWithGongTypeEnum: settings.godWithGongType,
      ganGongType: settings.ganGongType,
    );

    final pan = RiJiaQiMen(ju: ju, settings: modelSettings);

    final entityGongMapper = pan.gongMapper.map(
      (gua, modelGong) => MapEntry(gua, EachGongMapper.fromModel(modelGong)),
    );

    return QiMenPan(
      id: 'rijia-${ju.panDateTime.millisecondsSinceEpoch}',
      panDateTime: ju.panDateTime,
      ju: ju,
      plateType: plateType,
      gongMapper: entityGongMapper,
      // 占位：日家无值符值使，以休门为纲、太乙为日主星
      zhiShiDoor: pan.zhiShiDoor,
      zhiShiDoorAtGong: pan.zhiShiDoorAtGong,
      zhiFuStar: pan.zhiFuStar,
      zhiFuStarAtGong: pan.zhiFuStarAtGong,
      // 日家伏吟反吟语义不适用（无原宫、无三奇六仪）
      isStarFuYin: false,
      isStarFanYin: false,
      isDoorFuYin: false,
      isDoorFanYin: false,
      isGanFuYin: false,
      isGanFanYin: false,
      // 驿马位：日家可由日支推得（保留时家逻辑可复用）；本期占位
      horseLocation: DiZhi.ZI,
      panGeJuList: null,
    );
  }
}

