import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/model/each_gong.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';

/// 神刻奇门排盘器（2 分钟一干支）
///
/// 算法依据（用户 spec §一-§七 + 参考盘 2026-05-08 01:30 校准）：
///
/// §一 时间：刻柱 = 60 甲子顺推（每 2 分钟一干支，每时辰起甲子，与时柱解耦）。
/// §二 定局：阴阳遁 = 节气定（冬至后阳 / 夏至后阴）；局数取**进阶方法**——
///         base = 当前时辰时家局；**每旬（10 刻）局数 +1**：
///         `juNumber = ((base-1 + (keIndex-1)÷10) mod 9) + 1`。
///         （此 shift 在上游 [KeJiaQiMenJuCalculator] 完成；本盘只读 `ju.juNumber`。）
/// §三 地盘：三奇六仪戊起，阳遁顺布 1→9，阴遁逆布 9→1。
/// §四 值符值使：以**刻柱**所在旬的旬首作为定锚——
///         值符（星）= 旬首落宫的本位九星
///         值使（门）= 旬首落宫的本位八门
/// §五 天盘九星：值符星带到刻干在地盘的落宫（刻干为甲时改取旬首遁干），
///         其余 7 星按"蓬、任、冲、辅、英、芮、柱、心"顺时针（跳 5）填入。
/// §六 人盘八门：从旬首地盘宫位出发，**含中 5** 路径——
///         阳遁 1→2→3…→9→1 顺数，阴遁 9→8→7…→1→9 逆数；
///         **shift = 旬内位次 = keJiaZi.number - xunHeader.number ∈ [0,9]**
///         （与时家"步距"算法不同，也不是 keIndex-1）；
///         若停在中 5 则寄坤 2（传统八门寄宫）。
///         其余 7 门按"休、生、伤、杜、景、死、惊、开"顺时针（跳 5）填入。
/// §七 神盘八神：以"值符神"为首，从值符飞至宫起——
///         阳遁顺时针、阴遁逆时针填入"符、蛇、阴、合、虎、武、地、天"
///         （= [EightGodsEnum.yangDunList]）。
class ShenKeQiMenPan {
  final KeJiaJu ju;
  final PanArrangeSettings settings;

  /// 9 颗星按宫号 1-9 顺序排列
  final List<QiMenStar> starSet;

  /// 地盘三奇六仪：宫号(1-9) → 天干
  late final Map<int, TianGan> diPanGanByGong;

  /// 值符星
  late final QiMenStar zhiFuStar;

  /// 值使门
  late final EightDoorEnum zhiShiDoor;

  /// 值符星所在宫
  late final HouTianGua zhiFuStarAtGong;

  /// 值使门所在宫
  late final HouTianGua zhiShiDoorAtGong;

  /// 完整 9 宫映射
  late final Map<HouTianGua, EachGong> gongMapper;

  ShenKeQiMenPan({
    required this.ju,
    required this.starSet,
    required this.settings,
  }) {
    assert(starSet.length == 9, '星集长度必须为 9，实际 ${starSet.length}');
    _arrange();
  }

  // ============== 路径常量 ==============

  /// 顺时针 8 宫（跳中5）：1坎 → 8艮 → 3震 → 4巽 → 9离 → 2坤 → 7兑 → 6乾
  static const List<int> _clockwiseSkip5 = [1, 8, 3, 4, 9, 2, 7, 6];

  /// 逆时针 8 宫（跳中5）
  static const List<int> _counterClockwiseSkip5 = [1, 6, 7, 2, 9, 4, 3, 8];

  /// 升序 9 宫（含中5）— §三阳遁布地盘 / §六阳遁数门
  static const List<int> _ascendingAll = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// 降序 9 宫（含中5）— §三阴遁布地盘 / §六阴遁数门
  static const List<int> _descendingAll = [9, 8, 7, 6, 5, 4, 3, 2, 1];

  // ============== 序列常量 ==============

  static const List<TianGan> _ganSeq = [
    TianGan.WU,
    TianGan.JI,
    TianGan.GENG,
    TianGan.XIN,
    TianGan.REN,
    TianGan.GUI,
    TianGan.DING,
    TianGan.BING,
    TianGan.YI,
  ];

  /// 八星固定顺序：蓬、任、冲、辅、英、芮、柱、心
  static const List<NineStarsEnum> _eightStarFixedOrder = [
    NineStarsEnum.PENG,
    NineStarsEnum.REN,
    NineStarsEnum.CHONG,
    NineStarsEnum.FU,
    NineStarsEnum.YING,
    NineStarsEnum.RUI,
    NineStarsEnum.ZHU,
    NineStarsEnum.XIN,
  ];

  /// 八门固定顺序：休、生、伤、杜、景、死、惊、开
  static const List<EightDoorEnum> _eightDoorFixedOrder = [
    EightDoorEnum.XIU,
    EightDoorEnum.SHENG,
    EightDoorEnum.SHANG,
    EightDoorEnum.DU,
    EightDoorEnum.JING_S,
    EightDoorEnum.SI,
    EightDoorEnum.JING_W,
    EightDoorEnum.KAI,
  ];

  /// 宫号 → 本位八星（中5 寄坤2）
  static const Map<int, NineStarsEnum> _gongToStarBenWei = {
    1: NineStarsEnum.PENG,
    2: NineStarsEnum.RUI,
    3: NineStarsEnum.CHONG,
    4: NineStarsEnum.FU,
    6: NineStarsEnum.XIN,
    7: NineStarsEnum.ZHU,
    8: NineStarsEnum.REN,
    9: NineStarsEnum.YING,
  };

  /// 宫号 → 本位八门（中5 寄坤2）
  static const Map<int, EightDoorEnum> _gongNumberToDoorBenWei = {
    1: EightDoorEnum.XIU,
    2: EightDoorEnum.SI,
    3: EightDoorEnum.SHANG,
    4: EightDoorEnum.DU,
    6: EightDoorEnum.KAI,
    7: EightDoorEnum.JING_W,
    8: EightDoorEnum.SHENG,
    9: EightDoorEnum.JING_S,
  };

  // ============== 排盘流程 ==============

  void _arrange() {
    // §三 布地盘
    diPanGanByGong = _placeDiPan();

    // §四 识别值符 / 值使（按刻柱旬首）
    final keJiaZi = ju.keJiaZi;
    final xunHeaderJiaZi = keJiaZi.xunHeader;
    final xunHeaderTianGan = SixJia.getSixJiaByJiaZi(xunHeaderJiaZi).gan;

    final xunHeaderGongRaw = diPanGanByGong.entries
        .firstWhere(
          (e) => e.value == xunHeaderTianGan,
          orElse: () =>
              throw StateError('神刻：旬首天干 $xunHeaderTianGan 未落入地盘'),
        )
        .key;
    final xunHeaderGongAdj = xunHeaderGongRaw == 5 ? 2 : xunHeaderGongRaw;

    zhiFuStar = _gongToStarBenWei[xunHeaderGongAdj]!;
    zhiShiDoor = _gongNumberToDoorBenWei[xunHeaderGongAdj]!;
    final NineStarsEnum zhiFuStarBeiDou =
        _gongToStarBenWei[xunHeaderGongAdj]!;

    // §五 值符飞至宫 = 刻干在地盘的落宫（刻干为甲时改用旬首遁干）
    TianGan effectiveKeGan = keJiaZi.gan;
    if (effectiveKeGan == TianGan.JIA) {
      effectiveKeGan = xunHeaderTianGan;
    }
    final keGanGongRaw = diPanGanByGong.entries
        .firstWhere(
          (e) => e.value == effectiveKeGan,
          orElse: () => throw StateError('神刻：刻干 $effectiveKeGan 未落入地盘'),
        )
        .key;
    final keGanGongAdj = keGanGongRaw == 5 ? 2 : keGanGongRaw;
    zhiFuStarAtGong = HouTianGua.getGua(keGanGongAdj);

    // §六 值使飞至宫 — 1→2→3 含中 5 顺数（阳）/ 9→8→7 逆数（阴）
    // 起：旬首地盘原宫；shift = **旬内位次** = keJiaZi.number - xunHeader.number ∈ [0,9]
    // 若停在中 5 → 寄坤 2
    final fullPath = ju.yinYangDun.isYang ? _ascendingAll : _descendingAll;
    final startIdx = fullPath.indexOf(xunHeaderGongRaw);
    if (startIdx < 0) {
      throw StateError(
          '神刻 §六：旬首落宫 $xunHeaderGongRaw 不在 9 宫路径 $fullPath 中');
    }
    final shift = keJiaZi.number - xunHeaderJiaZi.number;
    final landedRaw = fullPath[(startIdx + shift) % 9];
    final keZhiGongNumber = landedRaw == 5 ? 2 : landedRaw;
    zhiShiDoorAtGong = HouTianGua.getGua(keZhiGongNumber);

    // §五 天盘九星（顺时针跳 5）
    final tianPanStarByGong =
        _arrangeTianPanStars(zhiFuStarBeiDou, keGanGongAdj);

    // §六 人盘八门（顺时针跳 5 起值使位）
    final renPanDoorByGong = _arrangeRenPanDoors(zhiShiDoor, keZhiGongNumber);

    // §七 神盘八神（阳顺阴逆 + yangDunList）
    final shenPanGodByGong = _arrangeShenPanGods(keGanGongAdj);

    // 天盘干（旬首干跟随值符飞）
    final tianPanGanByGong =
        _arrangeTianPanGan(xunHeaderGongAdj, keGanGongAdj);

    gongMapper = _assemble(
      diPan: diPanGanByGong,
      tianPan: tianPanGanByGong,
      tianPanStars: tianPanStarByGong,
      renPanDoors: renPanDoorByGong,
      shenPanGods: shenPanGodByGong,
    );
  }

  Map<int, TianGan> _placeDiPan() {
    final path = ju.yinYangDun.isYang ? _ascendingAll : _descendingAll;
    final qiJuGongNumber = ju.juNumber;
    final startIdx = path.indexOf(qiJuGongNumber);
    if (startIdx < 0) {
      throw StateError('神刻：起局宫 $qiJuGongNumber 不在路径中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 9; i++) {
      final gongIdx = path[(startIdx + i) % 9];
      result[gongIdx] = _ganSeq[i];
    }
    return result;
  }

  Map<int, QiMenStar> _arrangeTianPanStars(
      NineStarsEnum zhiFuStar, int drivingGanGongAdj) {
    final pathStartIdx = _clockwiseSkip5.indexOf(drivingGanGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          '神刻 §五：drivingGanGongAdj=$drivingGanGongAdj 不在顺时针路径中');
    }
    final starStartIdx = _eightStarFixedOrder.indexOf(zhiFuStar);
    final result = <int, QiMenStar>{};
    for (int i = 0; i < 8; i++) {
      final gong = _clockwiseSkip5[(pathStartIdx + i) % 8];
      final star = _eightStarFixedOrder[(starStartIdx + i) % 8];
      result[gong] = star;
    }
    return result;
  }

  /// 八门顺时针跳 5 起值使位（§六"其余门随转"）
  Map<int, EightDoorEnum> _arrangeRenPanDoors(
      EightDoorEnum zhiShiDoor, int drivingZhiGong) {
    if (drivingZhiGong == 5) {
      throw StateError('神刻 §六：值使位不应为 5（已寄 2）');
    }
    final pathStartIdx = _clockwiseSkip5.indexOf(drivingZhiGong);
    if (pathStartIdx < 0) {
      throw StateError(
          '神刻 §六：drivingZhiGong=$drivingZhiGong 不在顺时针路径中');
    }
    final doorStartIdx = _eightDoorFixedOrder.indexOf(zhiShiDoor);
    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gong = _clockwiseSkip5[(pathStartIdx + i) % 8];
      final door = _eightDoorFixedOrder[(doorStartIdx + i) % 8];
      result[gong] = door;
    }
    return result;
  }

  /// §七 神盘八神 — 阳遁顺时针、阴遁逆时针 + yangDunList
  Map<int, EightGodsEnum> _arrangeShenPanGods(int drivingGanGongAdj) {
    final path =
        ju.yinYangDun.isYang ? _clockwiseSkip5 : _counterClockwiseSkip5;
    final pathStartIdx = path.indexOf(drivingGanGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          '神刻 §七：drivingGanGongAdj=$drivingGanGongAdj 不在路径 $path 中');
    }
    final godList = EightGodsEnum.yangDunList;
    final result = <int, EightGodsEnum>{};
    for (int i = 0; i < 8; i++) {
      final gong = path[(pathStartIdx + i) % 8];
      result[gong] = godList[i];
    }
    return result;
  }

  Map<int, TianGan> _arrangeTianPanGan(
      int xunHeaderGongAdj, int drivingGanGongAdj) {
    final tianStartIdx = _clockwiseSkip5.indexOf(drivingGanGongAdj);
    final diStartIdx = _clockwiseSkip5.indexOf(xunHeaderGongAdj);
    if (tianStartIdx < 0 || diStartIdx < 0) {
      throw StateError(
          '神刻：天盘干路径异常 (旬首=$xunHeaderGongAdj 值符=$drivingGanGongAdj)');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 8; i++) {
      final tianGong = _clockwiseSkip5[(tianStartIdx + i) % 8];
      final diGong = _clockwiseSkip5[(diStartIdx + i) % 8];
      final ganHere = diPanGanByGong[diGong];
      if (ganHere == null) {
        throw StateError('神刻：地盘干缺宫 $diGong');
      }
      result[tianGong] = ganHere;
    }
    return result;
  }

  Map<HouTianGua, EachGong> _assemble({
    required Map<int, TianGan> diPan,
    required Map<int, TianGan> tianPan,
    required Map<int, QiMenStar> tianPanStars,
    required Map<int, EightDoorEnum> renPanDoors,
    required Map<int, EightGodsEnum> shenPanGods,
  }) {
    final result = <HouTianGua, EachGong>{};
    for (int i = 1; i <= 9; i++) {
      if (i == 5) continue;
      final gua = HouTianGua.getGua(i);
      final ganHere = diPan[i] ?? TianGan.WU;
      final tianGanHere = tianPan[i] ?? ganHere;
      result[gua] = EachGong(
        gongNumber: i,
        gongGua: gua,
        star: tianPanStars[i] ?? starSet[i - 1],
        door: renPanDoors[i] ?? (throw StateError('神刻：宫 $i 缺八门')),
        god: shenPanGods[i] ?? (throw StateError('神刻：宫 $i 缺八神')),
        diGod: shenPanGods[i] ?? EightGodsEnum.ZHI_FU,
        diPan: ganHere,
        tianPan: tianGanHere,
        tianPanAnGan: ganHere,
        renPanAnGan: ganHere,
        yinGan: ganHere,
      );
    }

    // 中 5：天禽星家，其余字段寄坤 2
    final kunGong = result[HouTianGua.Kun]!;
    final ganAtCenter = diPan[5] ?? TianGan.WU;
    result[HouTianGua.Center] = EachGong(
      gongNumber: 5,
      gongGua: HouTianGua.Center,
      star: NineStarsEnum.QIN,
      door: kunGong.door,
      god: kunGong.god,
      diGod: kunGong.diGod,
      diPan: ganAtCenter,
      tianPan: ganAtCenter,
      tianPanAnGan: ganAtCenter,
      renPanAnGan: ganAtCenter,
      yinGan: ganAtCenter,
    );

    _settleJiGong(result, ganAtCenter, kunGong.diPan);
    return result;
  }

  void _settleJiGong(
    Map<HouTianGua, EachGong> gongRes,
    TianGan ganAtCenter,
    TianGan kunDiPanGan,
  ) {
    final jiGong = gongRes[HouTianGua.Kun];
    if (jiGong == null) return;
    jiGong.diPanJiGan = ganAtCenter;
    EachGong? jiTianQinGong;
    for (final g in gongRes.values) {
      if (g.gongGua == HouTianGua.Center) continue;
      if (g.tianPan == kunDiPanGan) {
        jiTianQinGong = g;
        break;
      }
    }
    if (jiTianQinGong != null) {
      jiTianQinGong.tianPanJiGan = ganAtCenter;
      jiTianQinGong.isJiTianQin = true;
    }
  }
}
