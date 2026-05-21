import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/model/each_gong.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';

/// 刻家奇门排盘器
///
/// 算法依据：用户 spec 2026-05-05
///
/// **核心区别于时家 / 月家 / 年家**：
/// - 一时辰内分多刻起局，刻数与每刻时长由 `KeJiaJu.keScheme` 决定
///   （十刻五子建元：10刻×12分；八刻五马遁：8刻×15分）
/// - 局数推移由 `KeJiaQiMenJuCalculator` 上游决定（初局 = 时家局；阳顺阴逆推移）
/// - **yinYangDun = 刻干阴阳**（甲丙戊庚壬→YANG / 乙丁己辛癸→YIN）
/// - **值使飞至宫 = 刻支后天八卦配宫**（子→1, 丑寅→8, 卯→3, 辰巳→4, 午→9, 未申→2, 酉→7, 戌亥→6）
///   不是时家 / 月家 / 年家用的"步距"算法
/// - **八门 path direction**：阳干刻顺时针 [1,8,3,4,9,2,7,6]，阴干刻逆时针 [1,6,7,2,9,4,3,8]
/// - 九星 / 八神 / 三奇六仪 行进方向均由 yinYangDun 决定
class KeJiaQiMenPan {
  final KeJiaJu ju;
  final PanArrangeSettings settings;

  /// 9 颗星按宫号 1-9 顺序排列（仅占位，刻家实际只用 8 元素 _eightStarFixedOrder）
  final List<QiMenStar> starSet;

  /// 地盘三奇六仪：宫号(1-9) → 天干
  late final Map<int, TianGan> diPanGanByGong;

  /// 值符星
  late final QiMenStar zhiFuStar;

  /// 值使门
  late final EightDoorEnum zhiShiDoor;

  /// 值符星所在宫（= 刻干在地盘的落宫；刻干=甲时改用旬首遁干）
  late final HouTianGua zhiFuStarAtGong;

  /// 值使门所在宫（= 刻支后天八卦配宫）
  late final HouTianGua zhiShiDoorAtGong;

  /// 完整 9 宫映射
  late final Map<HouTianGua, EachGong> gongMapper;

  KeJiaQiMenPan({
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

  /// 逆时针 8 宫（跳中5）：1坎 → 6乾 → 7兑 → 2坤 → 9离 → 4巽 → 3震 → 8艮
  static const List<int> _counterClockwiseSkip5 = [1, 6, 7, 2, 9, 4, 3, 8];

  /// 升序 9 宫（含中5），用于阳遁布地盘
  static const List<int> _ascendingAll = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// 降序 9 宫（含中5），用于阴遁布地盘
  static const List<int> _descendingAll = [9, 8, 7, 6, 5, 4, 3, 2, 1];

  // ============== 序列常量 ==============

  /// 三奇六仪戊起序列
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

  /// 八星固定顺序：蓬、任、冲、辅、英、芮、柱、心（不含天禽）
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

  /// 刻家阳遁八神序（与时家不同：用朱雀/勾陈替代白虎/玄武）
  ///
  /// 与 [EightGodsEnum.feiPanYangDunList] 去掉太常一致，对照参考排盘
  /// （2026-05-06 申时刻家阳遁六局）：值符 4 → 腾蛇 9 → 太阴 2 → 六合 7
  /// → 勾陈 6 → 朱雀 1 → 九地 8 → 九天 3
  static const List<EightGodsEnum> _keJiaYangDunGods = [
    EightGodsEnum.ZHI_FU,
    EightGodsEnum.TENG_SHE,
    EightGodsEnum.TAI_YIN,
    EightGodsEnum.LIU_HE,
    EightGodsEnum.GOU_CHEN,
    EightGodsEnum.ZHU_QI,
    EightGodsEnum.JIU_DI,
    EightGodsEnum.JIU_TIAN,
  ];

  /// 刻家阴遁八神序
  ///
  /// 推断：与 [EightGodsEnum.feiPanYinDunList] 去掉太常一致；
  /// 与时家 yangDunList 巧合相同。需用户提供阴遁参考排盘验证。
  /// TODO(2026-05-06): 等用户给阴遁示例后再 lock
  static const List<EightGodsEnum> _keJiaYinDunGods = [
    EightGodsEnum.ZHI_FU,
    EightGodsEnum.TENG_SHE,
    EightGodsEnum.TAI_YIN,
    EightGodsEnum.LIU_HE,
    EightGodsEnum.BAI_HU,
    EightGodsEnum.XUAN_WU,
    EightGodsEnum.JIU_DI,
    EightGodsEnum.JIU_TIAN,
  ];

  /// 宫号 → 本位八星
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

  /// 宫号 → 本位八门
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

  /// 后天八卦地支配宫（用户 spec：值使飞至刻支对应宫）
  /// 子→坎1, 丑寅→艮8, 卯→震3, 辰巳→巽4, 午→离9, 未申→坤2, 酉→兑7, 戌亥→乾6
  static int _diZhiToGongNumber(DiZhi zhi) {
    switch (zhi) {
      case DiZhi.ZI:
        return 1;
      case DiZhi.CHOU:
      case DiZhi.YIN:
        return 8;
      case DiZhi.MAO:
        return 3;
      case DiZhi.CHEN:
      case DiZhi.SI:
        return 4;
      case DiZhi.WU:
        return 9;
      case DiZhi.WEI:
      case DiZhi.SHEN:
        return 2;
      case DiZhi.YOU:
        return 7;
      case DiZhi.XU:
      case DiZhi.HAI:
        return 6;
    }
  }

  // ============== 排盘流程 ==============

  void _arrange() {
    // 步骤 1：地盘三奇六仪（按 yinYangDun 决定顺布 / 逆布）
    diPanGanByGong = _placeDiPan();

    // 步骤 2：识别值符 / 值使
    final keJiaZi = ju.keJiaZi;
    final xunHeaderJiaZi = keJiaZi.xunHeader;
    final xunHeaderTianGan = SixJia.getSixJiaByJiaZi(xunHeaderJiaZi).gan;

    final xunHeaderGongRaw = diPanGanByGong.entries
        .firstWhere((e) => e.value == xunHeaderTianGan,
            orElse: () => throw StateError(
                '旬首天干 $xunHeaderTianGan 未落入地盘'))
        .key;
    // 中5 寄坤2：用于本位查找
    final xunHeaderGongAdj =
        xunHeaderGongRaw == 5 ? 2 : xunHeaderGongRaw;

    final zhiFuStarBeiDou = _gongToStarBenWei[xunHeaderGongAdj]!;
    zhiFuStar = zhiFuStarBeiDou;
    zhiShiDoor = _gongNumberToDoorBenWei[xunHeaderGongAdj]!;

    // 步骤 3：值符飞至宫 = 刻干在地盘的落宫（刻干 = 甲时改用旬首遁干）
    TianGan effectiveKeGan = keJiaZi.gan;
    if (effectiveKeGan == TianGan.JIA) {
      effectiveKeGan = xunHeaderTianGan;
    }
    final keGanGongRaw = diPanGanByGong.entries
        .firstWhere((e) => e.value == effectiveKeGan,
            orElse: () => throw StateError(
                '刻干 $effectiveKeGan 未落入地盘'))
        .key;
    final keGanGongAdj = keGanGongRaw == 5 ? 2 : keGanGongRaw;
    zhiFuStarAtGong = HouTianGua.getGua(keGanGongAdj);

    // 步骤 4：值使飞至宫
    //
    // 不同刻方案规则：
    // - 60刻·神刻：值使从旬首落宫起，按 step = keJiaZi.number - xunHeader.number
    //   沿"阳顺阴逆"路径飞（与时家奇门转盘一致）。当 keJiaZi=旬首本身 step=0
    //   时，值使与值符同宫。
    // - 8/10刻：用户最初 spec 的"刻支后天八卦配宫表"。
    final int keZhiGongNumber;
    if (ju.keScheme == KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI) {
      final step = keJiaZi.number - xunHeaderJiaZi.number;
      final path = ju.yinYangDun.isYang
          ? _clockwiseSkip5
          : _counterClockwiseSkip5;
      final startIdx = path.indexOf(xunHeaderGongAdj);
      if (startIdx < 0) {
        throw StateError(
            '步骤4: 旬首落宫 $xunHeaderGongAdj 不在路径 $path 中');
      }
      keZhiGongNumber = path[(startIdx + step) % 8];
    } else {
      keZhiGongNumber = _diZhiToGongNumber(keJiaZi.diZhi);
    }
    zhiShiDoorAtGong = HouTianGua.getGua(keZhiGongNumber);

    // 步骤 5：天盘九星（顺时针 path，与时家一致）
    final tianPanStarByGong =
        _arrangeTianPanStars(zhiFuStarBeiDou, keGanGongAdj);

    // 步骤 6：人盘八门（path direction 由刻干阴阳决定 — 用户 spec §3）
    final renPanDoorByGong =
        _arrangeRenPanDoors(zhiShiDoor, keZhiGongNumber);

    // 步骤 7：神盘八神（顺时针 path + yangDunList / yinDunList，与时家一致）
    final shenPanGodByGong = _arrangeShenPanGods(keGanGongAdj);

    // 步骤 8：天盘干（旬首干跟随值符飞，路径 = 顺时针）
    final tianPanGanByGong = _arrangeTianPanGan(xunHeaderGongAdj, keGanGongAdj);

    gongMapper = _assemble(
      diPan: diPanGanByGong,
      tianPan: tianPanGanByGong,
      tianPanStars: tianPanStarByGong,
      renPanDoors: renPanDoorByGong,
      shenPanGods: shenPanGodByGong,
    );
  }

  /// 布地盘三奇六仪
  ///
  /// - 阳遁顺布：起局宫起戊，沿 [_ascendingAll] 顺数戊→己→...→乙
  /// - 阴遁逆布：起局宫起戊，沿 [_descendingAll] 逆数戊→己→...→乙
  Map<int, TianGan> _placeDiPan() {
    final path = ju.yinYangDun.isYang ? _ascendingAll : _descendingAll;
    final qiJuGongNumber = ju.juNumber;
    final startIdx = path.indexOf(qiJuGongNumber);
    if (startIdx < 0) {
      throw StateError('起局宫 $qiJuGongNumber 不在路径中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 9; i++) {
      final gongIdx = path[(startIdx + i) % 9];
      result[gongIdx] = _ganSeq[i];
    }
    return result;
  }

  /// 排天盘九星 — 顺布八宫（顺时针 path）
  ///
  /// 起：drivingGanGong（值符所落宫）；从 zhiFuStar 起按八星固定顺序顺时针填入
  Map<int, QiMenStar> _arrangeTianPanStars(
      NineStarsEnum zhiFuStar, int drivingGanGongAdj) {
    final pathStartIdx = _clockwiseSkip5.indexOf(drivingGanGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          '_arrangeTianPanStars: drivingGanGongAdj=$drivingGanGongAdj 不在顺时针路径中');
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

  /// 排人盘八门 — path direction 由刻干阴阳决定（用户 spec §3）
  ///
  /// - 阳干刻 → 顺时针 [1,8,3,4,9,2,7,6]
  /// - 阴干刻 → 逆时针 [1,6,7,2,9,4,3,8]
  /// 起：drivingZhiGong（值使所落宫，= 刻支配宫）；从 zhiShiDoor 起按八门固定顺序填入
  Map<int, EightDoorEnum> _arrangeRenPanDoors(
      EightDoorEnum zhiShiDoor, int drivingZhiGong) {
    if (drivingZhiGong == 5) {
      throw StateError(
          '_arrangeRenPanDoors: 刻支配宫不应为 5（地支永不落中5）');
    }
    final path =
        ju.yinYangDun.isYang ? _clockwiseSkip5 : _counterClockwiseSkip5;
    final pathStartIdx = path.indexOf(drivingZhiGong);
    if (pathStartIdx < 0) {
      throw StateError(
          '_arrangeRenPanDoors: drivingZhiGong=$drivingZhiGong 不在 $path 中');
    }
    final doorStartIdx = _eightDoorFixedOrder.indexOf(zhiShiDoor);
    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gong = path[(pathStartIdx + i) % 8];
      final door = _eightDoorFixedOrder[(doorStartIdx + i) % 8];
      result[gong] = door;
    }
    return result;
  }

  /// 排神盘八神 — 顺时针 path + 刻家专属八神 list（朱雀/勾陈）
  ///
  /// 起：drivingGanGong（值符所落宫）；从 ZHI_FU 起按相应方向 list 填入。
  /// 与时家不同，刻家用 [_keJiaYangDunGods] / [_keJiaYinDunGods]。
  Map<int, EightGodsEnum> _arrangeShenPanGods(int drivingGanGongAdj) {
    final pathStartIdx = _clockwiseSkip5.indexOf(drivingGanGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          '_arrangeShenPanGods: drivingGanGongAdj=$drivingGanGongAdj 不在顺时针路径中');
    }
    final godList = ju.yinYangDun.isYang
        ? _keJiaYangDunGods
        : _keJiaYinDunGods;
    final result = <int, EightGodsEnum>{};
    for (int i = 0; i < 8; i++) {
      final gong = _clockwiseSkip5[(pathStartIdx + i) % 8];
      result[gong] = godList[i];
    }
    return result;
  }

  /// 排天盘干 — 旬首干跟随值符飞，路径 = 顺时针 [1,8,3,4,9,2,7,6]
  Map<int, TianGan> _arrangeTianPanGan(
      int xunHeaderGongAdj, int drivingGanGongAdj) {
    final tianStartIdx = _clockwiseSkip5.indexOf(drivingGanGongAdj);
    final diStartIdx = _clockwiseSkip5.indexOf(xunHeaderGongAdj);
    if (tianStartIdx < 0 || diStartIdx < 0) {
      throw StateError(
          '_arrangeTianPanGan: 宫号 (旬首=$xunHeaderGongAdj, 值符=$drivingGanGongAdj) 必须在顺时针路径中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 8; i++) {
      final tianGong = _clockwiseSkip5[(tianStartIdx + i) % 8];
      final diGong = _clockwiseSkip5[(diStartIdx + i) % 8];
      final ganHere = diPanGanByGong[diGong];
      if (ganHere == null) {
        throw StateError('_arrangeTianPanGan: 地盘干缺宫 $diGong');
      }
      result[tianGong] = ganHere;
    }
    return result;
  }

  /// 组装 9 宫的 EachGong + 中宫寄干 + 天禽寄宫
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
        door: renPanDoors[i] ??
            (throw StateError('宫 $i 缺八门')),
        god: shenPanGods[i] ??
            (throw StateError('宫 $i 缺八神')),
        diGod: shenPanGods[i] ??
            EightGodsEnum.ZHI_FU,
        diPan: ganHere,
        tianPan: tianGanHere,
        tianPanAnGan: ganHere,
        renPanAnGan: ganHere,
        yinGan: ganHere,
      );
    }

    // 中5 EachGong：天禽星家，其余字段寄坤2
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

    // 中宫寄干 + 天禽寄宫（同时家 settleCenterGongJiGong 逻辑）
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
