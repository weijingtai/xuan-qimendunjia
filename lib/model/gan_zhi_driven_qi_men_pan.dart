import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/model/each_gong.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';

/// 干支双驱奇门排盘器（月家 + 年家共享）
///
/// 算法依据：docs/more_qimen/yue_jia_algorithm.md §5-§9
///         （与 nian_jia_algorithm.md §4-§8 同构）
///
/// 输入参数：
/// - [drivingGan] / [drivingZhi]：月家用月柱、年家用年柱
/// - [starSet]：9 颗星按宫号 1-9 顺序；月家用 NineStarsEnum，年家用 ZiBaiStarEnum
/// - [qiJuGong]：起局宫（月家 sanYuanToQiJuGong / 年家 NianJiaSanYuanAnchor 决定）
///
/// 当前实现进度（2026-04-30）：
/// - ✅ 步骤 1：地盘三奇六仪（阴遁逆飞戊起）
/// - 🚧 步骤 2-5：值符值使、天盘九星、人盘八门、神盘八神
///   均为 TODO，待 P3-T1.1 领域评审"逆九宫"路径与时家 arrangeJu 的关系确认后实现
class GanZhiDrivenQiMenPan {
  final BaseJu ju;
  final TianGan drivingGan;
  final DiZhi drivingZhi;

  /// 9 颗星按宫号 1-9 顺序排列
  final List<QiMenStar> starSet;

  /// 起局宫（戊落点）
  final HouTianGua qiJuGong;

  final PanArrangeSettings settings;

  /// 地盘三奇六仪：宫号(1-9) → 天干
  late final Map<int, TianGan> diPanGanByGong;

  /// 值符星
  late final QiMenStar zhiFuStar;

  /// 值使门
  late final EightDoorEnum zhiShiDoor;

  /// 值符星所在宫（即 drivingGan 在地盘的落宫）
  late final HouTianGua zhiFuStarAtGong;

  /// 值使门所在宫（即 drivingZhi 对应宫）
  late final HouTianGua zhiShiDoorAtGong;

  /// 完整宫位映射（待天/人/神三盘到位后填满）
  late final Map<HouTianGua, EachGong> gongMapper;

  GanZhiDrivenQiMenPan({
    required this.ju,
    required this.drivingGan,
    required this.drivingZhi,
    required this.starSet,
    required this.qiJuGong,
    required this.settings,
  }) {
    assert(starSet.length == 9, '星集长度必须为 9，实际 ${starSet.length}');
    for (int i = 0; i < 9; i++) {
      assert(starSet[i].number == i + 1,
          '星集必须按宫号 1-9 顺序排列：starSet[$i].number == ${starSet[i].number}');
    }
    _arrange();
  }

  // ============== 常量序列 ==============

  /// 阴遁九宫飞布路径（**逆时针**，含中5，9 元素）
  ///
  /// 按奇门遁甲飞布规则：[1,2,7,6,5,4,3,8,9]
  /// 验证（年家下元戊起兑7）：从 index=2 (gong=7) 起 9 步：
  ///   7戊 → 6己 → 5庚 → 4辛 → 3壬 → 8癸 → 9丁 → 1丙 → 2乙 ✓
  static const List<int> _yinDunGongSeq = [1, 2, 7, 6, 5, 4, 3, 8, 9];

  /// 阴遁逆时针 + 跳中 5（用于八神，8 元素）
  static const List<int> _yinDunGongSeqSkip5 = [1, 2, 7, 6, 4, 3, 8, 9];

  /// 阴遁九宫飞布路径（**顺时针**，含中5，9 元素）
  ///
  /// = 逆时针路径反向 = [9,8,3,4,5,6,7,2,1]
  /// 用于天盘九星顺时针布列（用户最新规范）。
  static const List<int> _yinDunGongSeqClockwise = [9, 8, 3, 4, 5, 6, 7, 2, 1];

  /// 阴遁顺时针 + 跳中 5（用于八门顺布，8 元素）
  static const List<int> _yinDunGongSeqClockwiseSkip5 = [9, 8, 3, 4, 6, 7, 2, 1];

  /// 三奇六仪戊起序列（无论阴阳遁，干的相对顺序固定为戊→己→庚→辛→壬→癸→丁→丙→乙）
  static const List<TianGan> _ganSeq = [
    TianGan.WU,  // 戊
    TianGan.JI,  // 己
    TianGan.GENG, // 庚
    TianGan.XIN, // 辛
    TianGan.REN, // 壬
    TianGan.GUI, // 癸
    TianGan.DING, // 丁
    TianGan.BING, // 丙
    TianGan.YI,  // 乙
  ];

  /// 北斗九星固定顺序（用户最新规范）：
  /// 天蓬、天芮、天冲、天辅、天英、天禽、天柱、天任、天心
  ///
  /// 用于布列天盘九星：从值符在该 list 中的索引起，沿 [_yinDunGongSeqClockwise]
  /// 顺时针填入。
  static const List<NineStarsEnum> _beiDouFixedOrder = [
    NineStarsEnum.PENG,   // 天蓬 (idx 0)
    NineStarsEnum.RUI,    // 天芮 (idx 1)
    NineStarsEnum.CHONG,  // 天冲 (idx 2)
    NineStarsEnum.FU,     // 天辅 (idx 3)
    NineStarsEnum.YING,   // 天英 (idx 4)
    NineStarsEnum.QIN,    // 天禽 (idx 5) — 中5寄坤2
    NineStarsEnum.ZHU,    // 天柱 (idx 6)
    NineStarsEnum.REN,    // 天任 (idx 7)
    NineStarsEnum.XIN,    // 天心 (idx 8)
  ];

  /// 宫号 → 本位北斗星（用于值符识别：旬首落宫的本位星）
  static const Map<int, NineStarsEnum> _gongToStarBenWei = {
    1: NineStarsEnum.PENG,   // 坎1·天蓬
    2: NineStarsEnum.RUI,    // 坤2·天芮
    3: NineStarsEnum.CHONG,  // 震3·天冲
    4: NineStarsEnum.FU,     // 巽4·天辅
    5: NineStarsEnum.QIN,    // 中5·天禽（寄坤2）
    6: NineStarsEnum.XIN,    // 乾6·天心
    7: NineStarsEnum.ZHU,    // 兑7·天柱
    8: NineStarsEnum.REN,    // 艮8·天任
    9: NineStarsEnum.YING,   // 离9·天英
  };

  /// 八门固定顺序（标准）：休、生、伤、杜、景、死、惊、开
  static const List<EightDoorEnum> _eightDoorFixedOrder = [
    EightDoorEnum.XIU,    // 休 (idx 0)
    EightDoorEnum.SHENG,  // 生 (idx 1)
    EightDoorEnum.SHANG,  // 伤 (idx 2)
    EightDoorEnum.DU,     // 杜 (idx 3)
    EightDoorEnum.JING_S, // 景 (idx 4)
    EightDoorEnum.SI,     // 死 (idx 5)
    EightDoorEnum.JING_W, // 惊 (idx 6)
    EightDoorEnum.KAI,    // 开 (idx 7)
  ];

  /// 八神固定顺序（标准）：值符、腾蛇、太阴、六合、白虎、玄武、九地、九天
  static const List<EightGodsEnum> _eightGodFixedOrder = [
    EightGodsEnum.ZHI_FU,   // 值符
    EightGodsEnum.TENG_SHE, // 腾蛇
    EightGodsEnum.TAI_YIN,  // 太阴
    EightGodsEnum.LIU_HE,   // 六合
    EightGodsEnum.BAI_HU,   // 白虎
    EightGodsEnum.XUAN_WU,  // 玄武
    EightGodsEnum.JIU_DI,   // 九地
    EightGodsEnum.JIU_TIAN, // 九天
  ];

  /// 宫号 → 本位八门（用于"值使门"判定）
  static const Map<int, EightDoorEnum> _gongNumberToDoorBenWei = {
    1: EightDoorEnum.XIU,        // 坎1·休
    2: EightDoorEnum.SI,         // 坤2·死
    3: EightDoorEnum.SHANG,      // 震3·伤
    4: EightDoorEnum.DU,         // 巽4·杜
    // 5: 中宫无门
    6: EightDoorEnum.KAI,        // 乾6·开
    7: EightDoorEnum.JING_W,     // 兑7·惊
    8: EightDoorEnum.SHENG,      // 艮8·生
    9: EightDoorEnum.JING_S,     // 离9·景
  };

  /// 后天八卦地支配宫
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
    // 步骤 1：地盘三奇六仪（阴遁逆时针戊起）
    diPanGanByGong = _placeDiPan();

    // 步骤 2：识别值符 / 值使（北斗派旬首落宫本位）
    final drivingJiaZi = JiaZi.getFromGanZhiEnum(drivingGan, drivingZhi);
    final xunHeaderJiaZi = drivingJiaZi.xunHeader;
    final xunHeaderTianGan = SixJia.getSixJiaByJiaZi(xunHeaderJiaZi).gan;

    // 旬首遁干在地盘的原始落宫（可能为 5）
    final xunHeaderGongRaw = diPanGanByGong.entries
        .firstWhere((e) => e.value == xunHeaderTianGan,
            orElse: () => throw StateError(
                '旬首天干 $xunHeaderTianGan 未落入地盘'))
        .key;
    // 中5 寄坤2：旬首落中5 时所有"本位查找"按坤2 处理
    final xunHeaderGongAdj =
        xunHeaderGongRaw == 5 ? 2 : xunHeaderGongRaw;

    // 值符星 = 旬首落宫的本位北斗星
    final zhiFuStarBeiDou = _gongToStarBenWei[xunHeaderGongAdj]!;
    zhiFuStar = zhiFuStarBeiDou; // 协变到 QiMenStar

    // 值使门 = 旬首落宫的本位时家门
    zhiShiDoor = _gongNumberToDoorBenWei[xunHeaderGongAdj]!;

    // drivingGan 在地盘的落宫（值符飞至此宫）
    final drivingGanGongRaw = diPanGanByGong.entries
        .firstWhere((e) => e.value == drivingGan,
            orElse: () =>
                throw StateError('drivingGan $drivingGan 未落入地盘'))
        .key;
    final drivingGanGongAdj =
        drivingGanGongRaw == 5 ? 2 : drivingGanGongRaw;
    zhiFuStarAtGong = HouTianGua.getGua(drivingGanGongAdj);

    // drivingZhi → 后天八卦地支配宫（值使飞至此宫，地支永不落中5）
    final drivingZhiGongNumber = _diZhiToGongNumber(drivingZhi);
    zhiShiDoorAtGong = HouTianGua.getGua(drivingZhiGongNumber);

    // 步骤 3：天盘九星 — 飞盘**顺时针**，固定顺序蓬芮冲辅英禽柱任心
    final tianPanStarByGong =
        _arrangeTianPanStars(drivingGanGongAdj, zhiFuStarBeiDou);

    // 步骤 4：人盘八门 — 飞盘**顺时针**跳中5，固定顺序休生伤杜景死惊开
    final renPanDoorByGong =
        _arrangeRenPanDoors(drivingZhiGongNumber, zhiShiDoor);

    // 步骤 5：神盘八神 — 飞盘**逆时针**跳中5，固定顺序值符…九天
    final shenPanGodByGong = _arrangeShenPanGods(drivingGanGongAdj);

    gongMapper = _assemble(
      diPan: diPanGanByGong,
      tianPanStars: tianPanStarByGong,
      renPanDoors: renPanDoorByGong,
      shenPanGods: shenPanGodByGong,
    );
  }

  /// 阴遁地盘三奇六仪：起局宫放戊，按 [_yinDunGongSeq] 逆时针填入 9 个干。
  Map<int, TianGan> _placeDiPan() {
    final startIdx = _yinDunGongSeq.indexOf(qiJuGong.houTianOrder);
    if (startIdx < 0) {
      throw StateError('起局宫 ${qiJuGong.name} 不在九宫飞布序列中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 9; i++) {
      final gongIdx = _yinDunGongSeq[(startIdx + i) % 9];
      result[gongIdx] = _ganSeq[i];
    }
    return result;
  }

  /// 排天盘九星 — 顺时针 + 北斗固定顺序
  ///
  /// 算法（用户最新规范）：
  /// - 起：drivingGanGong（值符落宫）
  /// - 走：[_yinDunGongSeqClockwise]（顺时针 9 步含中5）
  /// - 序：从值符在 [_beiDouFixedOrder] 中的索引起 cyclic
  Map<int, QiMenStar> _arrangeTianPanStars(
      int targetGong, NineStarsEnum zhiFuStarBeiDou) {
    final pathStartIdx = _yinDunGongSeqClockwise.indexOf(targetGong);
    if (pathStartIdx < 0) {
      throw StateError(
          'targetGong=$targetGong 不在顺时针路径中（中5寄2应已处理）');
    }
    final zhiFuIdx = _beiDouFixedOrder.indexOf(zhiFuStarBeiDou);
    if (zhiFuIdx < 0) {
      throw StateError('值符星 $zhiFuStarBeiDou 不在北斗固定顺序中');
    }
    final result = <int, QiMenStar>{};
    for (int i = 0; i < 9; i++) {
      final gongNum = _yinDunGongSeqClockwise[(pathStartIdx + i) % 9];
      final star = _beiDouFixedOrder[(zhiFuIdx + i) % 9];
      result[gongNum] = star;
    }
    return result;
  }

  /// 排人盘八门 — 顺时针跳中5 + 标准固定顺序
  ///
  /// 算法（用户最新规范）：
  /// - 起：drivingZhiGong（值使落宫）
  /// - 走：[_yinDunGongSeqClockwiseSkip5]（顺时针 8 步跳中5）
  /// - 序：从值使在 [_eightDoorFixedOrder] 中的索引起 cyclic
  Map<int, EightDoorEnum> _arrangeRenPanDoors(
      int targetGong, EightDoorEnum zhiShiDoor) {
    final pathStartIdx =
        _yinDunGongSeqClockwiseSkip5.indexOf(targetGong);
    if (pathStartIdx < 0) {
      throw StateError(
          'drivingZhiGong=$targetGong 不在顺时针跳5路径中（地支不应落中5）');
    }
    final zhiShiIdx = _eightDoorFixedOrder.indexOf(zhiShiDoor);
    if (zhiShiIdx < 0) {
      throw StateError('值使门 $zhiShiDoor 不在八门固定顺序中');
    }
    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNum =
          _yinDunGongSeqClockwiseSkip5[(pathStartIdx + i) % 8];
      result[gongNum] = _eightDoorFixedOrder[(zhiShiIdx + i) % 8];
    }
    return result;
  }

  /// 排神盘八神 — 逆时针跳中5 + 标准固定顺序
  ///
  /// 算法（用户最新规范）：
  /// - 起：drivingGanGong（值符落宫）
  /// - 走：[_yinDunGongSeqSkip5]（逆时针 8 步跳中5）
  /// - 序：[_eightGodFixedOrder]（值符神在索引 0，依次填入）
  Map<int, EightGodsEnum> _arrangeShenPanGods(int zhiFuGongAdj) {
    final pathStartIdx = _yinDunGongSeqSkip5.indexOf(zhiFuGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          'zhiFuGongAdj=$zhiFuGongAdj 不在逆时针跳5路径中（中5寄2应已处理）');
    }
    final result = <int, EightGodsEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNum = _yinDunGongSeqSkip5[(pathStartIdx + i) % 8];
      result[gongNum] = _eightGodFixedOrder[i];
    }
    return result;
  }

  /// 组装 9 宫的 EachGong
  ///
  /// 八门 / 八神只在 8 个非中宫飞布；中 5 宫**寄坤 2**：
  /// star/door/god 直接复用坤 2 的对应值（与时家一致语义）。
  /// 月家 / 年家无"天盘干"概念，`tianPan` 字段填地盘干占位；
  /// 暗干 / 隐干同样置占位（这些字段属时家的延伸概念，月年家不强相关）。
  Map<HouTianGua, EachGong> _assemble({
    required Map<int, TianGan> diPan,
    required Map<int, QiMenStar> tianPanStars,
    required Map<int, EightDoorEnum> renPanDoors,
    required Map<int, EightGodsEnum> shenPanGods,
  }) {
    final result = <HouTianGua, EachGong>{};
    for (int i = 1; i <= 9; i++) {
      if (i == 5) continue; // 中宫晚于 8 宫处理（见下方寄坤2）
      final gua = HouTianGua.getGua(i);
      final ganHere = diPan[i] ?? TianGan.WU;
      result[gua] = EachGong(
        gongNumber: i,
        gongGua: gua,
        star: tianPanStars[i] ?? starSet[i - 1],
        door: renPanDoors[i] ??
            (throw StateError('宫 $i 缺八门')),
        god: shenPanGods[i] ??
            (throw StateError('宫 $i 缺八神')),
        diGod: shenPanGods[i] ??
            EightGodsEnum.ZHI_FU, // 月年家暂不区分天地神
        diPan: ganHere,
        tianPan: ganHere, // 月年家暂无"天盘干"独立概念，用地盘干占位
        tianPanAnGan: ganHere,
        renPanAnGan: ganHere,
        yinGan: ganHere,
      );
    }

    // 中 5 寄坤 2：直接复用坤 2 宫的星 / 门 / 神，地盘干用中宫自己的
    final kunGong = result[HouTianGua.Kun]!;
    final ganAtCenter = diPan[5] ?? TianGan.WU;
    result[HouTianGua.Center] = EachGong(
      gongNumber: 5,
      gongGua: HouTianGua.Center,
      star: kunGong.star,
      door: kunGong.door,
      god: kunGong.god,
      diGod: kunGong.diGod,
      diPan: ganAtCenter,
      tianPan: ganAtCenter,
      tianPanAnGan: ganAtCenter,
      renPanAnGan: ganAtCenter,
      yinGan: ganAtCenter,
    );

    return result;
  }
}
