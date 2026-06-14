import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/data/models/mappers/each_gong_mapper.dart';
import 'package:qimendunjia/data/models/mappers/qimen_pan_mapper.dart';
import 'package:qimendunjia/data/models/mappers/shi_jia_ju_mapper.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart' as entity;
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_six_bing_ge_ju.dart';
import 'package:qimendunjia/enums/enum_six_geng_ge_ju.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';
import 'package:qimendunjia/model/each_gong.dart' as model;
import 'package:qimendunjia/model/each_gong_wang_shuai.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/model/shi_jia_ju.dart' as model_ju;
import 'package:qimendunjia/model/shi_jia_qi_men.dart' as model_qm;

import 'qimen_pan_adapter.dart';
import 'package:qimendunjia/enums/enum_most_popular_ge_ju.dart';

/// Bridge that converts [QiMenPan] domain entity into all the legacy
/// display data that the old [ShiJiaQiMen] model provided.
///
/// Lives in presentation/adapters/ (not pages/) so it CAN import model
/// types. Pages only consume the bridge's output — they never import
/// model/shi_jia_ju.dart or model/shi_jia_qi_men.dart directly.
class QiMenLegacyDisplayBridge {
  final QiMenPan? pan;
  final PanArrangeSettings settings;

  // ---- Adapter state ----
  final LegacyQiMenDisplayState displayState;

  // ---- Model-level gong data ----
  final Map<HouTianGua, model.EachGong> gongModelMapper;
  final Map<HouTianGua, EachGongWangShuai> gongWangShuaiMapper;

  // ---- GeJu lists ----
  final List<EnumSixGengGeJu> gengGeList;
  final List<EnumSixBingGeJu> bingGeList;

  // ---- Derived convenience fields ----
  final JiaZi yearJiaZi;
  final JiaZi monthJiaZi;
  final JiaZi dayJiaZi;
  final JiaZi timeJiaZi;
  final SixJia sixJiaXunHeader;
  final TianGan xunHeaderTianGan;
  final TianGan zhiFuGan;
  final MonthToken monthToken;
  final YinYang yinYangDun;
  final int juNumber;
  final TwentyFourJieQi jieQi;
  final PlateType plateType;
  final ArrangeType arrangeType;
  final String fourZhuEightChar;

  // ---- Pan-level GeJu ----
  final List<EnumMostPopularGeJu>? panGeJuList;

  // ---- ShiJiaJu convenience fields ----
  final TwentyFourJieQi? panJuJieQi;
  final EnumThreeYuan atThreeYuan;
  final int? juDayNumber;

  /// 旬首 (JiaZi xun header) — same as [timeJiaZi].xunHeader
  JiaZi get xunShou => timeJiaZi.xunHeader;

  QiMenLegacyDisplayBridge._({
    required this.pan,
    required this.settings,
    required this.displayState,
    required this.gongModelMapper,
    required this.gongWangShuaiMapper,
    required this.gengGeList,
    required this.bingGeList,
    required this.yearJiaZi,
    required this.monthJiaZi,
    required this.dayJiaZi,
    required this.timeJiaZi,
    required this.sixJiaXunHeader,
    required this.xunHeaderTianGan,
    required this.zhiFuGan,
    required this.monthToken,
    required this.yinYangDun,
    required this.juNumber,
    required this.jieQi,
    required this.plateType,
    required this.arrangeType,
    required this.fourZhuEightChar,
    required this.panGeJuList,
    required this.panJuJieQi,
    required this.atThreeYuan,
    required this.juDayNumber,
  });

  /// Build a bridge from a [QiMenPan] entity and [PanArrangeSettings].
  ///
  /// Internally converts entity EachGong → model EachGong and constructs
  /// a temporary model ShiJiaQiMen for WangShuai / GeJu computation.
  factory QiMenLegacyDisplayBridge.fromPan(
    QiMenPan pan,
    PanArrangeSettings settings,
  ) {
    // 1. Adapter display state
    final displayState = QiMenPanAdapter.convert(pan);

    // 2. Entity → model EachGong
    final Map<HouTianGua, model.EachGong> gongModelMapper = {};
    pan.gongMapper.forEach((gua, entityGong) {
      gongModelMapper[gua] = EachGongMapper.toModel(entityGong);
    });

    // 3. Build a temporary model ShiJiaJu for ShiJiaQiMen construction
    final entity.ShiJiaJu? entityJu = pan.shiJiaJu;
    final model_ju.ShiJiaJu modelJu = entityJu != null
        ? ShiJiaJuMapper.toModel(entityJu)
        : _buildFallbackModelJu(pan);

    // 4. Build temporary model ShiJiaQiMen for WangShuai + GeJu computation
    final modelPan = model_qm.ShiJiaQiMen(
      plateType: pan.plateType,
      shiJiaJu: modelJu,
      settings: settings,
    );

    // 5. Parse fourZhuEightChar for yearJiaZi, monthJiaZi
    final eightCharList = displayState.fourZhuEightChar.split(' ');
    final yearJiaZi = JiaZi.getFromGanZhiValue(eightCharList[0])!;
    final monthJiaZi = JiaZi.getFromGanZhiValue(eightCharList[1])!;

    return QiMenLegacyDisplayBridge._(
      pan: pan,
      settings: settings,
      displayState: displayState,
      gongModelMapper: gongModelMapper,
      gongWangShuaiMapper: modelPan.gongWangShuaiMapper,
      gengGeList: modelPan.gengGeList,
      bingGeList: modelPan.bingGeList,
      yearJiaZi: yearJiaZi,
      monthJiaZi: monthJiaZi,
      dayJiaZi: modelPan.dayJiaZi,
      timeJiaZi: modelPan.timeJiaZi,
      sixJiaXunHeader: displayState.sixJiaXunHeader,
      xunHeaderTianGan: displayState.xunHeaderTianGan,
      zhiFuGan: displayState.zhiFuGan,
      monthToken: displayState.monthToken,
      yinYangDun: displayState.yinYangDun,
      juNumber: displayState.juNumber,
      jieQi: displayState.jieQi,
      plateType: pan.plateType,
      arrangeType: settings.arrangeType,
      fourZhuEightChar: displayState.fourZhuEightChar,
      panGeJuList: modelPan.panGeJuList,
      panJuJieQi: entityJu?.panJuJieQi,
      atThreeYuan: entityJu!.atThreeYuan,
      juDayNumber: entityJu.juDayNumber,
    );
  }

  /// Build a bridge from raw components (PlateType, entity ShiJiaJu, settings).
  ///
  /// Internally creates model ShiJiaJu / ShiJiaQiMen for computation,
  /// then converts back to entity QiMenPan.
  factory QiMenLegacyDisplayBridge.fromRawComponents({
    required PlateType plateType,
    required entity.ShiJiaJu shiJiaJu,
    required PanArrangeSettings settings,
  }) {
    // 1. Create model types
    final modelJu = ShiJiaJuMapper.toModel(shiJiaJu);
    final modelPan = model_qm.ShiJiaQiMen(
      plateType: plateType,
      shiJiaJu: modelJu,
      settings: settings,
    );

    // 2. Create entity QiMenPan from model (for bridge.pan field)
    final entityPan = QiMenPanMapper.fromModel(modelPan);

    // 3. Create display state from model data
    final displayState = LegacyQiMenDisplayState(
      zhiShiDoor: modelPan.zhiShiDoor,
      zhiFuStar: modelPan.zhiFuStar,
      xunHeaderTianGan: modelPan.xunHeaderTianGan,
      timeXunKong: modelPan.timeXunKong,
      dayXunKong: modelPan.dayXunKong,
      monthXunKong: modelPan.monthXunKong,
      yearXunKong: modelPan.yearXunKong,
      horseLocation: modelPan.horseLocation,
      monthToken: modelPan.monthToken,
      dayJiaZi: modelPan.dayJiaZi,
      timeJiaZi: modelPan.timeJiaZi,
      yinYangDun: modelPan.yinYangDun,
      juNumber: modelPan.juNumber,
      jieQi: modelPan.jieQi,
      fourZhuEightChar: modelPan.eightChatStr,
      sixJiaXunHeader: modelPan.sixJiaXunHeader,
      isSixJiXing: modelPan.isSixJiXing,
      zhiFuGan: modelPan.zhiFuGan,
      zhiFuStarAtGong: modelPan.zhiFuStarAtGong,
      zhiShiDoorAtGong: modelPan.zhiShiDoorAtGong,
    );

    return QiMenLegacyDisplayBridge._(
      pan: entityPan,
      settings: settings,
      displayState: displayState,
      gongModelMapper: modelPan.gongMapper,
      gongWangShuaiMapper: modelPan.gongWangShuaiMapper,
      gengGeList: modelPan.gengGeList,
      bingGeList: modelPan.bingGeList,
      yearJiaZi: modelPan.yearJiaZi,
      monthJiaZi: modelPan.monthJiaZi,
      dayJiaZi: modelPan.dayJiaZi,
      timeJiaZi: modelPan.timeJiaZi,
      sixJiaXunHeader: modelPan.sixJiaXunHeader,
      xunHeaderTianGan: modelPan.xunHeaderTianGan,
      zhiFuGan: modelPan.zhiFuGan,
      monthToken: modelPan.monthToken,
      yinYangDun: modelPan.yinYangDun,
      juNumber: modelPan.juNumber,
      jieQi: modelPan.jieQi,
      plateType: plateType,
      arrangeType: settings.arrangeType,
      fourZhuEightChar: modelPan.eightChatStr,
      panGeJuList: modelPan.panGeJuList,
      panJuJieQi: shiJiaJu.panJuJieQi,
      atThreeYuan: shiJiaJu.atThreeYuan,
      juDayNumber: shiJiaJu.juDayNumber,
    );
  }

  /// Fallback: build a model ShiJiaJu from QiMenPan when shiJiaJu is null.
  static model_ju.ShiJiaJu _buildFallbackModelJu(QiMenPan pan) {
    final eightCharList = pan.ju.fourZhuEightChar.split(' ');
    final dayJiaZi = JiaZi.getFromGanZhiValue(eightCharList[2])!;
    return model_ju.ShiJiaJu(
      panDateTime: pan.panDateTime,
      juNumber: pan.ju.juNumber,
      fuTouJiaZi: dayJiaZi, // placeholder
      yinYangDun: pan.ju.yinYangDun,
      jieQiAt: TwentyFourJieQi.DONG_ZHI, // placeholder
      jieQiEnd: TwentyFourJieQi.DONG_ZHI,
      atThreeYuan: EnumThreeYuan.START,
      fourZhuEightChar: pan.ju.fourZhuEightChar,
    );
  }
}
