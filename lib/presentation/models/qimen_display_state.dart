import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/usecases/select_gong_usecase.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_most_popular_ge_ju.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:tuple/tuple.dart';

/// Unified display state for QiMen pan rendering.
///
/// Aggregates all data that any QiMen page needs to render a complete pan:
/// - Ju metadata (from [LegacyQiMenDisplayState] / [QiMenPanAdapter])
/// - Palace data (9-gong mapper from [QiMenPan])
/// - Fu/Fan-yin flags, horse location, ge-ju list
/// - Selected palace detail ([GongDetailInfo])
///
/// This model is the **output** contract: ViewModel emits it via
/// [QiMenUiState.success(displayState)], and any page (legacy, mvvm, multi_jia)
/// reads from it without depending on ViewModel internals.
class QiMenDisplayState {
  // ===========================================================================
  // Ju metadata (mirrors LegacyQiMenDisplayState fields)
  // ===========================================================================

  /// 起盘时间
  final DateTime panDateTime;

  /// 家维度
  final QiMenJia jia;

  /// 阴阳遁
  final YinYang yinYangDun;

  /// 局数
  final int juNumber;

  /// 节气
  final TwentyFourJieQi jieQi;

  /// 四柱八字
  final String fourZhuEightChar;

  /// 盘类型（转盘/飞盘）
  final PlateType plateType;

  // ===========================================================================
  // 值符值使
  // ===========================================================================

  /// 值使门
  final EightDoorEnum zhiShiDoor;

  /// 值符星 (NineStarsEnum for shi-jia; other types may differ)
  final NineStarsEnum zhiFuStar;

  /// 值符天干
  final TianGan zhiFuGan;

  /// 值符星所在宫
  final HouTianGua zhiFuStarAtGong;

  /// 值使门所在宫
  final HouTianGua zhiShiDoorAtGong;

  // ===========================================================================
  // 旬空
  // ===========================================================================

  /// 旬首天干
  final TianGan xunHeaderTianGan;

  /// 时柱旬空
  final Tuple2<DiZhi, DiZhi> timeXunKong;

  /// 日柱旬空
  final Tuple2<DiZhi, DiZhi> dayXunKong;

  /// 月柱旬空
  final Tuple2<DiZhi, DiZhi> monthXunKong;

  /// 年柱旬空
  final Tuple2<DiZhi, DiZhi> yearXunKong;

  /// 马星位
  final DiZhi horseLocation;

  // ===========================================================================
  // 六甲
  // ===========================================================================

  /// 六甲旬首
  final SixJia sixJiaXunHeader;

  /// 是否六击星
  final bool isSixJiXing;

  /// 月将
  final MonthToken monthToken;

  /// 日家甲子
  final JiaZi dayJiaZi;

  /// 时家甲子
  final JiaZi timeJiaZi;

  // ===========================================================================
  // 伏吟 / 反吟
  // ===========================================================================

  /// 星伏吟
  final bool isStarFuYin;

  /// 星反吟
  final bool isStarFanYin;

  /// 门伏吟
  final bool isDoorFuYin;

  /// 门反吟
  final bool isDoorFanYin;

  /// 干伏吟
  final bool isGanFuYin;

  /// 干反吟
  final bool isGanFanYin;

  // ===========================================================================
  // 九宫数据
  // ===========================================================================

  /// 九宫信息映射（卦象 -> 宫位信息）
  final Map<HouTianGua, EachGong> gongMapper;

  /// 格局列表（盘级别）
  final List<EnumMostPopularGeJu>? panGeJuList;

  // ===========================================================================
  // 选中宫位详情
  // ===========================================================================

  /// 当前选中的宫位（null 表示未选中）
  final HouTianGua? selectedGongGua;

  /// 选中宫位的详情信息（克应、格局等）
  final GongDetailInfo? gongDetailInfo;

  const QiMenDisplayState({
    required this.panDateTime,
    required this.jia,
    required this.yinYangDun,
    required this.juNumber,
    required this.jieQi,
    required this.fourZhuEightChar,
    required this.plateType,
    required this.zhiShiDoor,
    required this.zhiFuStar,
    required this.zhiFuGan,
    required this.zhiFuStarAtGong,
    required this.zhiShiDoorAtGong,
    required this.xunHeaderTianGan,
    required this.timeXunKong,
    required this.dayXunKong,
    required this.monthXunKong,
    required this.yearXunKong,
    required this.horseLocation,
    required this.sixJiaXunHeader,
    required this.isSixJiXing,
    required this.monthToken,
    required this.dayJiaZi,
    required this.timeJiaZi,
    required this.isStarFuYin,
    required this.isStarFanYin,
    required this.isDoorFuYin,
    required this.isDoorFanYin,
    required this.isGanFuYin,
    required this.isGanFanYin,
    required this.gongMapper,
    this.panGeJuList,
    this.selectedGongGua,
    this.gongDetailInfo,
  });

  // ===========================================================================
  // Convenience
  // ===========================================================================

  /// 是否存在任何伏吟
  bool get hasAnyFuYin => isStarFuYin || isDoorFuYin || isGanFuYin;

  /// 是否存在任何反吟
  bool get hasAnyFanYin => isStarFanYin || isDoorFanYin || isGanFanYin;

  /// 获取指定宫位信息
  EachGong? getGong(HouTianGua gua) => gongMapper[gua];

  /// 获取盘局简要描述
  String get brief {
    final juBrief = jia == QiMenJia.SHI
        ? '$juNumber局'
        : '${jia.name}·$juNumber局';
    return '$juBrief ${plateType.name}';
  }

  // ===========================================================================
  // Copy
  // ===========================================================================

  QiMenDisplayState copyWith({
    DateTime? panDateTime,
    QiMenJia? jia,
    YinYang? yinYangDun,
    int? juNumber,
    TwentyFourJieQi? jieQi,
    String? fourZhuEightChar,
    PlateType? plateType,
    EightDoorEnum? zhiShiDoor,
    NineStarsEnum? zhiFuStar,
    TianGan? zhiFuGan,
    HouTianGua? zhiFuStarAtGong,
    HouTianGua? zhiShiDoorAtGong,
    TianGan? xunHeaderTianGan,
    Tuple2<DiZhi, DiZhi>? timeXunKong,
    Tuple2<DiZhi, DiZhi>? dayXunKong,
    Tuple2<DiZhi, DiZhi>? monthXunKong,
    Tuple2<DiZhi, DiZhi>? yearXunKong,
    DiZhi? horseLocation,
    SixJia? sixJiaXunHeader,
    bool? isSixJiXing,
    MonthToken? monthToken,
    JiaZi? dayJiaZi,
    JiaZi? timeJiaZi,
    bool? isStarFuYin,
    bool? isStarFanYin,
    bool? isDoorFuYin,
    bool? isDoorFanYin,
    bool? isGanFuYin,
    bool? isGanFanYin,
    Map<HouTianGua, EachGong>? gongMapper,
    List<EnumMostPopularGeJu>? panGeJuList,
    HouTianGua? selectedGongGua,
    GongDetailInfo? gongDetailInfo,
  }) {
    return QiMenDisplayState(
      panDateTime: panDateTime ?? this.panDateTime,
      jia: jia ?? this.jia,
      yinYangDun: yinYangDun ?? this.yinYangDun,
      juNumber: juNumber ?? this.juNumber,
      jieQi: jieQi ?? this.jieQi,
      fourZhuEightChar: fourZhuEightChar ?? this.fourZhuEightChar,
      plateType: plateType ?? this.plateType,
      zhiShiDoor: zhiShiDoor ?? this.zhiShiDoor,
      zhiFuStar: zhiFuStar ?? this.zhiFuStar,
      zhiFuGan: zhiFuGan ?? this.zhiFuGan,
      zhiFuStarAtGong: zhiFuStarAtGong ?? this.zhiFuStarAtGong,
      zhiShiDoorAtGong: zhiShiDoorAtGong ?? this.zhiShiDoorAtGong,
      xunHeaderTianGan: xunHeaderTianGan ?? this.xunHeaderTianGan,
      timeXunKong: timeXunKong ?? this.timeXunKong,
      dayXunKong: dayXunKong ?? this.dayXunKong,
      monthXunKong: monthXunKong ?? this.monthXunKong,
      yearXunKong: yearXunKong ?? this.yearXunKong,
      horseLocation: horseLocation ?? this.horseLocation,
      sixJiaXunHeader: sixJiaXunHeader ?? this.sixJiaXunHeader,
      isSixJiXing: isSixJiXing ?? this.isSixJiXing,
      monthToken: monthToken ?? this.monthToken,
      dayJiaZi: dayJiaZi ?? this.dayJiaZi,
      timeJiaZi: timeJiaZi ?? this.timeJiaZi,
      isStarFuYin: isStarFuYin ?? this.isStarFuYin,
      isStarFanYin: isStarFanYin ?? this.isStarFanYin,
      isDoorFuYin: isDoorFuYin ?? this.isDoorFuYin,
      isDoorFanYin: isDoorFanYin ?? this.isDoorFanYin,
      isGanFuYin: isGanFuYin ?? this.isGanFuYin,
      isGanFanYin: isGanFanYin ?? this.isGanFanYin,
      gongMapper: gongMapper ?? this.gongMapper,
      panGeJuList: panGeJuList ?? this.panGeJuList,
      selectedGongGua: selectedGongGua ?? this.selectedGongGua,
      gongDetailInfo: gongDetailInfo ?? this.gongDetailInfo,
    );
  }

  @override
  String toString() =>
      'QiMenDisplayState(brief=$brief, gongs=${gongMapper.length}, '
      'selected=$selectedGongGua)';
}
