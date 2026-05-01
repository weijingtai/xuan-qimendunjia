import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
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

  /// 阴遁九宫逆飞路径（按后天八卦逆向圆周序）
  /// 1坎 → 9离 → 8艮 → 7兑 → 6乾 → 5中 → 4巽 → 3震 → 2坤
  static const List<int> _yinDunGongSeq = [1, 9, 8, 7, 6, 5, 4, 3, 2];

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
    // 步骤 1：地盘三奇六仪（阴遁逆飞戊起，已实现）
    diPanGanByGong = _placeDiPan();

    // 步骤 2：旬首得值符值使（TODO）
    final drivingJiaZi =
        JiaZi.getFromGanZhiEnum(drivingGan, drivingZhi);
    final xunHeaderJiaZi = drivingJiaZi.xunHeader;
    final xunHeaderTianGan = SixJia.getSixJiaByJiaZi(xunHeaderJiaZi).gan;
    final xunHeaderGongNumber = diPanGanByGong.entries
        .firstWhere((e) => e.value == xunHeaderTianGan,
            orElse: () => throw StateError(
                '旬首天干 $xunHeaderTianGan 未落入地盘'))
        .key;
    zhiFuStar = starSet[xunHeaderGongNumber - 1];
    zhiShiDoor = _gongNumberToDoorBenWei[xunHeaderGongNumber] ??
        (throw StateError('旬首落中5宫，应寄坤2，请使用寄宫规则'));

    // 步骤 3：天盘九星（值符随 drivingGan，TODO 完整逆飞分配）
    final drivingGanGongNumber = diPanGanByGong.entries
        .firstWhere((e) => e.value == drivingGan,
            orElse: () =>
                throw StateError('drivingGan $drivingGan 未落入地盘'))
        .key;
    zhiFuStarAtGong = HouTianGua.getGua(drivingGanGongNumber);

    // 步骤 4：人盘八门（值使逆数到 drivingZhi 宫，TODO）
    final drivingZhiGongNumber = _diZhiToGongNumber(drivingZhi);
    zhiShiDoorAtGong = HouTianGua.getGua(drivingZhiGongNumber);

    // 步骤 3：天盘九星 — 飞盘逆飞，值符跟 drivingGan 落宫
    final tianPanStarByGong =
        _arrangeTianPanStars(drivingGanGongNumber, xunHeaderGongNumber);

    // 步骤 4：人盘八门 — 飞盘逆飞，值使从 xunHeaderGong 飞至 drivingZhiGong
    final renPanDoorByGong =
        _arrangeRenPanDoors(drivingZhiGongNumber, xunHeaderGongNumber);

    // 步骤 5：神盘八神 — 值符神跟天盘值符星落宫，其余逆排
    final shenPanGodByGong = _arrangeShenPanGods(drivingGanGongNumber);

    gongMapper = _assemble(
      diPan: diPanGanByGong,
      tianPanStars: tianPanStarByGong,
      renPanDoors: renPanDoorByGong,
      shenPanGods: shenPanGodByGong,
    );
  }

  /// 阴遁地盘三奇六仪：起局宫放戊，按九宫逆飞填入 9 个干。
  /// 中5位置仍占座；上层若需"中5寄坤2"在 EachGong 组装时另行处理。
  Map<int, TianGan> _placeDiPan() {
    final startIdx = _yinDunGongSeq.indexOf(qiJuGong.houTianOrder);
    if (startIdx < 0) {
      throw StateError('起局宫 ${qiJuGong.name} 不在九宫逆飞序列中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 9; i++) {
      final gongIdx = _yinDunGongSeq[(startIdx + i) % 9];
      result[gongIdx] = _ganSeq[i];
    }
    return result;
  }

  /// 排天盘九星（飞盘 + 阴遁逆飞）
  ///
  /// 算法（对照表 §五 + yue_jia_algorithm.md §7）：
  /// - 值符星 = `starSet[xunHeaderGong - 1]`
  /// - 值符星飞至 `targetGong`（即 drivingGanGong）
  /// - 其余九星按 `starSet` 顺序，沿"九宫逆飞"路径依次填入
  Map<int, QiMenStar> _arrangeTianPanStars(int targetGong, int xunHeaderGong) {
    final pathStartIdx = _yinDunGongSeq.indexOf(targetGong);
    if (pathStartIdx < 0) {
      throw StateError('drivingGan 落入中5（路径外），暂不支持');
    }
    final starStartIdx = xunHeaderGong - 1;
    final result = <int, QiMenStar>{};
    for (int i = 0; i < 9; i++) {
      final gongNum = _yinDunGongSeq[(pathStartIdx + i) % 9];
      final starIdx = (starStartIdx + i) % 9;
      result[gongNum] = starSet[starIdx];
    }
    return result;
  }

  /// 排人盘八门（飞盘 + 阴遁逆飞，跳中5）
  ///
  /// 算法（对照表 §六 + yue_jia_algorithm.md §8）：
  /// - 值使门 = xunHeaderGong 宫的本位门
  /// - 值使从其本宫起，逆数到 drivingZhiGong
  /// - 其余八门按本位顺序逆飞
  ///
  /// 中5无门：8 个门飞布在 [1, 9, 8, 7, 6, 4, 3, 2] 八宫。
  Map<int, EightDoorEnum> _arrangeRenPanDoors(
      int targetGong, int xunHeaderGong) {
    // 八门按"宫号本位"展开（跳5）
    const doorBenWeiOrdered = <EightDoorEnum>[
      EightDoorEnum.XIU,    // 坎1
      EightDoorEnum.SI,     // 坤2
      EightDoorEnum.SHANG,  // 震3
      EightDoorEnum.DU,     // 巽4
      EightDoorEnum.KAI,    // 乾6
      EightDoorEnum.JING_W, // 兑7
      EightDoorEnum.SHENG,  // 艮8
      EightDoorEnum.JING_S, // 离9
    ];
    const doorGongNumbers = [1, 2, 3, 4, 6, 7, 8, 9];
    const doorPath = [1, 9, 8, 7, 6, 4, 3, 2]; // 阴遁逆飞跳中5

    final doorStartIdx = doorGongNumbers.indexOf(xunHeaderGong);
    if (doorStartIdx < 0) {
      // 旬首落中5：寄坤2，等价于值使按坤2本位起算
      // TODO P3-T1.1 评审：旬首落中5的值使寄宫规则
      throw UnimplementedError('旬首落中5，值使寄宫规则待评审');
    }
    final pathStartIdx = doorPath.indexOf(targetGong);
    if (pathStartIdx < 0) {
      throw StateError('drivingZhi 落入中5无门，路径不存在');
    }

    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNum = doorPath[(pathStartIdx + i) % 8];
      final doorIdx = (doorStartIdx + i) % 8;
      result[gongNum] = doorBenWeiOrdered[doorIdx];
    }
    return result;
  }

  /// 排神盘八神（飞盘 + 阴遁逆飞，跳中5）
  ///
  /// 算法（对照表 §七 + yue_jia_algorithm.md §9）：
  /// - 值符神跟天盘值符星，落于 zhiFuGongNumber
  /// - 其余八神按"值符 → 螣蛇 → 太阴 → 六合 → 白虎 → 玄武 → 九地 → 九天"逆排
  Map<int, EightGodsEnum> _arrangeShenPanGods(int zhiFuGongNumber) {
    const godOrder = <EightGodsEnum>[
      EightGodsEnum.ZHI_FU,
      EightGodsEnum.TENG_SHE,
      EightGodsEnum.TAI_YIN,
      EightGodsEnum.LIU_HE,
      EightGodsEnum.BAI_HU,
      EightGodsEnum.XUAN_WU,
      EightGodsEnum.JIU_DI,
      EightGodsEnum.JIU_TIAN,
    ];
    const godPath = [1, 9, 8, 7, 6, 4, 3, 2]; // 跳中5

    final pathStartIdx = godPath.indexOf(zhiFuGongNumber);
    if (pathStartIdx < 0) {
      // 值符星落中5：寄坤2 — 同八门寄宫规则
      // TODO P3-T1.1 评审
      throw UnimplementedError('值符星落中5，神盘寄宫规则待评审');
    }

    final result = <int, EightGodsEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNum = godPath[(pathStartIdx + i) % 8];
      result[gongNum] = godOrder[i];
    }
    return result;
  }

  /// 组装 8 宫（中5不参与）的 EachGong
  ///
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
      if (i == 5) continue;
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
    return result;
  }
}
