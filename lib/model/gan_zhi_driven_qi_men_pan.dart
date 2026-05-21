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
  //
  // 按用户校准（2026-05-04 更新）：
  //   - 地盘干：阴遁默认 "数字降序" [9..1]（保留校准 2026-05-01）
  //   - 九星：顺布八宫，路径 = 时家顺时针 [1,8,3,4,9,2,7,6]，星序 [蓬,任,冲,辅,英,芮,柱,心]
  //          天禽星寄于八宫之一（依"中宫寄干 + 天禽寄宫"逻辑）
  //   - 八门：顺排八门，路径 = 时家奇门顺时针 [1,8,3,4,9,2,7,6]（同时家算法）
  //   - 天盘干：路径 = 时家奇门顺时针 [1,8,3,4,9,2,7,6]（同时家算法）
  //   - 八神：从值符宫起，沿后天八卦"真逆时针" [1,6,7,2,9,4,3,8] 顺序填入八神

  /// 逆行（阴遁默认）含中5
  ///
  /// 验证（年家下元戊起兑7）：从 index=2 (gong=7) 起 9 步循环
  ///   7戊 → 6己 → 5庚 → 4辛 → 3壬 → 2癸 → 1丁 → 9丙 → 8乙
  static const List<int> _gongSeqDescending = [9, 8, 7, 6, 5, 4, 3, 2, 1];

  /// 时家奇门顺时针 8 宫（跳中5）：1坎 → 8艮 → 3震 → 4巽 → 9离 → 2坤 → 7兑 → 6乾
  /// 用于八门顺排 / 天盘九星 / 天盘干（与时家奇门同结构）
  static const List<int> _shiJiaClockwiseSkip5 = [1, 8, 3, 4, 9, 2, 7, 6];

  /// 后天八卦真逆时针 8 宫（跳中5）：1坎 → 6乾 → 7兑 → 2坤 → 9离 → 4巽 → 3震 → 8艮
  /// 用于八神：从值符宫起逆时针填入"值符 腾蛇 太阴 六合 白虎 玄武 九地 九天"
  static const List<int> _shiJiaCounterClockwiseSkip5 = [1, 6, 7, 2, 9, 4, 3, 8];

  // 历史命名兼容（保留以减少替换面）
  static const List<int> _yinDunGongSeq = _gongSeqDescending;

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

  /// 八星固定顺序（2026-05-04 校准）：
  /// 蓬、任、冲、辅、英、芮、柱、心 —— 8 元素，不含天禽。
  /// 天禽星寄于八宫之一（依"中宫寄干"逻辑），不参与本序列布列。
  ///
  /// 用于天盘九星顺布八宫：从值符星在本序列中的索引起，沿
  /// [_shiJiaClockwiseSkip5] 顺时针填入。与时家奇门
  /// [NineStarsEnum.listOrderedByClockwiseWithoutYing] 同序。
  static const List<NineStarsEnum> _eightStarFixedOrder = [
    NineStarsEnum.PENG,   // 蓬 (idx 0)
    NineStarsEnum.REN,    // 任 (idx 1)
    NineStarsEnum.CHONG,  // 冲 (idx 2)
    NineStarsEnum.FU,     // 辅 (idx 3)
    NineStarsEnum.YING,   // 英 (idx 4)
    NineStarsEnum.RUI,    // 芮 (idx 5)
    NineStarsEnum.ZHU,    // 柱 (idx 6)
    NineStarsEnum.XIN,    // 心 (idx 7)
  ];

  /// 宫号 → 本位八星（用于值符识别：旬首落宫的本位星）
  /// 不含中5：旬首若落中5，调用方已 redirect 至坤2 (xunHeaderGongAdj)。
  static const Map<int, NineStarsEnum> _gongToStarBenWei = {
    1: NineStarsEnum.PENG,   // 坎1·天蓬
    2: NineStarsEnum.RUI,    // 坤2·天芮
    3: NineStarsEnum.CHONG,  // 震3·天冲
    4: NineStarsEnum.FU,     // 巽4·天辅
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

  /// 时家"步距"算法（用于值使门飞至宫的定位）
  ///
  /// 从 startGong 起，按 [1..9] 顺序，阳遁顺数 / 阴遁逆数 step 步。
  /// 月家 / 年家恒阴遁，故实际只走逆数分支。
  ///
  /// 与时家 `shi_jia_qi_men.dart::calculateZhuanPan` 行 374-390 的实现等价。
  /// 调用方负责处理终点若为中5 时的寄宫策略。
  static int _walkByStep(int startGong, int step, YinYang yinYangDun) {
    const ascending = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    final idx = ascending.indexOf(startGong);
    if (idx < 0) {
      throw StateError('_walkByStep: startGong=$startGong 不在 [1..9] 中');
    }
    final base = [
      ...ascending.sublist(idx),
      ...ascending.sublist(0, idx),
    ];
    // base 长度 9，再加首项一遍以容纳 step==9（同时家边界处理）
    final walk = yinYangDun.isYang
        ? [...base, base.first] // 阳遁顺数
        : [base.first, ...base.skip(1).toList().reversed, base.first]; // 阴遁逆数
    if (step < 0 || step >= walk.length) {
      throw StateError(
          '_walkByStep: step=$step 超出范围 [0, ${walk.length - 1}]');
    }
    return walk[step];
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

    // 值使门飞至宫：时家"步距"算法（月家 / 年家恒阴遁，逆数九宫）
    //   totalStep = drivingJiaZi 与 旬首 JiaZi 在六十甲子的步距
    //   从 xunHeaderGongRaw 起，沿 [1..9]，阴遁逆数 totalStep 步
    //   终点若落中5，固定寄坤2
    final totalStep = drivingJiaZi.number - xunHeaderJiaZi.number;
    int drivingZhiGongNumber =
        _walkByStep(xunHeaderGongRaw, totalStep, ju.yinYangDun);
    if (drivingZhiGongNumber == 5) {
      drivingZhiGongNumber = 2; // 月家 / 年家固定寄坤2
    }
    zhiShiDoorAtGong = HouTianGua.getGua(drivingZhiGongNumber);

    // 步骤 3：天盘九星 — 飞盘**顺时针**，固定顺序蓬芮冲辅英禽柱任心
    final tianPanStarByGong =
        _arrangeTianPanStars(xunHeaderGongAdj, drivingGanGongAdj);

    // 步骤 4：人盘八门 — 顺排八门（同时家奇门），路径 [1,8,3,4,9,2,7,6]
    final renPanDoorByGong =
        _arrangeRenPanDoors(xunHeaderGongAdj, drivingZhiGongNumber);

    // 步骤 5：神盘八神 — 飞盘**逆时针**跳中5，固定顺序值符…九天
    final shenPanGodByGong = _arrangeShenPanGods(drivingGanGongAdj);

    // 步骤 6：天盘干 — 同时家奇门，旬首干跟随值符飞，路径 [1,8,3,4,9,2,7,6]
    final tianPanGanByGong =
        _arrangeTianPanGan(xunHeaderGongAdj, drivingGanGongAdj);

    gongMapper = _assemble(
      diPan: diPanGanByGong,
      tianPan: tianPanGanByGong,
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

  /// 排天盘九星 — **顺布八宫**（同时家奇门转盘算法）
  ///
  /// 算法：
  /// - 路径：[_shiJiaClockwiseSkip5]（后天八卦真顺时针，跳中5）
  /// - 起点：drivingGanGongAdj（值符所落宫）
  /// - 八星固定顺序：[_eightStarFixedOrder] = 蓬 任 冲 辅 英 芮 柱 心
  /// - 把路径旋转到 drivingGanGongAdj 起，把星序旋转到 zhiFuStar 起，索引对齐配对
  ///
  /// 中5无星位（天禽星寄于八宫之一，由 _assemble 的寄宫逻辑落位）。
  Map<int, QiMenStar> _arrangeTianPanStars(
      int xunHeaderGongAdj, int drivingGanGongAdj) {
    final pathStartIdx = _shiJiaClockwiseSkip5.indexOf(drivingGanGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          '_arrangeTianPanStars: drivingGanGongAdj=$drivingGanGongAdj 不在顺时针路径 $_shiJiaClockwiseSkip5 中');
    }
    final zhiFuStar = _gongToStarBenWei[xunHeaderGongAdj];
    if (zhiFuStar == null) {
      throw StateError(
          '_arrangeTianPanStars: xunHeaderGongAdj=$xunHeaderGongAdj 不在 8 宫本位星表中（中5应已寄2）');
    }
    final starStartIdx = _eightStarFixedOrder.indexOf(zhiFuStar);
    final result = <int, QiMenStar>{};
    for (int i = 0; i < 8; i++) {
      final gong = _shiJiaClockwiseSkip5[(pathStartIdx + i) % 8];
      final star = _eightStarFixedOrder[(starStartIdx + i) % 8];
      result[gong] = star;
    }
    return result;
  }

  /// 排人盘八门 — **顺排八门**（同时家奇门转盘算法）
  ///
  /// 算法：
  /// - 路径：[_shiJiaClockwiseSkip5]（后天八卦真顺时针，跳中5）
  /// - 起点：drivingZhiGong（值使门所落宫，本位即为值使门 zhiShiDoor）
  /// - 八门固定顺序：[_eightDoorFixedOrder] = 休生伤杜景死惊开
  /// - 把路径旋转到 drivingZhiGong 起，把门序旋转到 zhiShiDoor 起，索引对齐配对
  ///
  /// 调用方保证 xunHeaderGongAdj ≠ 5、drivingZhiGong ≠ 5（地支不应落中5）
  Map<int, EightDoorEnum> _arrangeRenPanDoors(
      int xunHeaderGongAdj, int drivingZhiGong) {
    if (drivingZhiGong == 5) {
      throw StateError(
          '_arrangeRenPanDoors: drivingZhiGong 不应为 5（地支永不落中5）');
    }
    final pathStartIdx = _shiJiaClockwiseSkip5.indexOf(drivingZhiGong);
    if (pathStartIdx < 0) {
      throw StateError(
          '_arrangeRenPanDoors: drivingZhiGong=$drivingZhiGong 不在顺时针路径 $_shiJiaClockwiseSkip5 中');
    }
    final zhiShiDoor = _gongNumberToDoorBenWei[xunHeaderGongAdj];
    if (zhiShiDoor == null) {
      throw StateError(
          '_arrangeRenPanDoors: xunHeaderGongAdj=$xunHeaderGongAdj 不在本位门表中（中5应已寄2）');
    }
    final doorStartIdx = _eightDoorFixedOrder.indexOf(zhiShiDoor);
    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gong = _shiJiaClockwiseSkip5[(pathStartIdx + i) % 8];
      final door = _eightDoorFixedOrder[(doorStartIdx + i) % 8];
      result[gong] = door;
    }
    return result;
  }

  /// 排天盘干 — 同时家奇门转盘算法
  ///
  /// 思想：旬首遁干跟着值符飞至 drivingGanGongAdj，旬首位置的地盘干"上飞到"值符位置；
  /// 各干顺时针同步飞动。
  ///
  /// 算法：
  /// - 路径：[_shiJiaClockwiseSkip5]（后天八卦真顺时针，跳中5）
  /// - 旋转 1：路径起点 = drivingGanGongAdj（天盘各宫的迭代起点）
  /// - 旋转 2：路径起点 = xunHeaderGongAdj（地盘各宫的迭代起点）
  /// - 配对：天盘[路径1[i]] = 地盘[路径2[i]]
  ///
  /// 调用方保证 xunHeaderGongAdj ≠ 5、drivingGanGongAdj ≠ 5（中5已寄2）
  Map<int, TianGan> _arrangeTianPanGan(
      int xunHeaderGongAdj, int drivingGanGongAdj) {
    final tianStartIdx = _shiJiaClockwiseSkip5.indexOf(drivingGanGongAdj);
    final diStartIdx = _shiJiaClockwiseSkip5.indexOf(xunHeaderGongAdj);
    if (tianStartIdx < 0 || diStartIdx < 0) {
      throw StateError(
          '_arrangeTianPanGan: 宫号 (旬首=$xunHeaderGongAdj, 值符=$drivingGanGongAdj) 必须在 $_shiJiaClockwiseSkip5 中');
    }
    final result = <int, TianGan>{};
    for (int i = 0; i < 8; i++) {
      final tianGong = _shiJiaClockwiseSkip5[(tianStartIdx + i) % 8];
      final diGong = _shiJiaClockwiseSkip5[(diStartIdx + i) % 8];
      final ganHere = diPanGanByGong[diGong];
      if (ganHere == null) {
        throw StateError('_arrangeTianPanGan: 地盘干缺宫 $diGong');
      }
      result[tianGong] = ganHere;
    }
    return result;
  }

  /// 排神盘八神 — 后天八卦真逆时针跳中5 + 标准固定顺序
  ///
  /// 算法（2026-05-04 校准）：
  /// - 起：drivingGanGong（值符落宫）
  /// - 走：[_shiJiaCounterClockwiseSkip5] = [1,6,7,2,9,4,3,8]（真逆时针跳5）
  /// - 序：[_eightGodFixedOrder]（值符神在索引 0，依次填入"值符 腾蛇 太阴 六合 白虎 玄武 九地 九天"）
  ///
  /// 验证：值符宫=1 时，神→宫映射应为
  ///   值符=1, 腾蛇=6, 太阴=7, 六合=2, 白虎=9, 玄武=4, 九地=3, 九天=8
  Map<int, EightGodsEnum> _arrangeShenPanGods(int zhiFuGongAdj) {
    final pathStartIdx = _shiJiaCounterClockwiseSkip5.indexOf(zhiFuGongAdj);
    if (pathStartIdx < 0) {
      throw StateError(
          'zhiFuGongAdj=$zhiFuGongAdj 不在真逆时针跳5路径 $_shiJiaCounterClockwiseSkip5 中（中5寄2应已处理）');
    }
    final result = <int, EightGodsEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNum = _shiJiaCounterClockwiseSkip5[(pathStartIdx + i) % 8];
      result[gongNum] = _eightGodFixedOrder[i];
    }
    return result;
  }

  /// 组装 9 宫的 EachGong
  ///
  /// 1. 八宫各自填入 star / door / god / 地盘干 / 天盘干
  /// 2. 中5自身的 EachGong：星位为天禽（中宫之星家），其余字段寄坤2
  /// 3. **中宫寄干 + 天禽寄宫**（同时家奇门）：
  ///    - 坤2的 `diPanJiGan` ← 中5地盘干
  ///    - 找到天盘上"坤2地盘干"所落之宫 X，X 为天禽寄宫
  ///    - X.tianPanJiGan ← 中5地盘干，X.isJiTianQin = true
  /// 4. 暗干 / 隐干暂置占位（属时家延伸字段，月年家不强相关）
  Map<HouTianGua, EachGong> _assemble({
    required Map<int, TianGan> diPan,
    required Map<int, TianGan> tianPan,
    required Map<int, QiMenStar> tianPanStars,
    required Map<int, EightDoorEnum> renPanDoors,
    required Map<int, EightGodsEnum> shenPanGods,
  }) {
    final result = <HouTianGua, EachGong>{};
    for (int i = 1; i <= 9; i++) {
      if (i == 5) continue; // 中宫晚于 8 宫处理
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
            EightGodsEnum.ZHI_FU, // 月年家暂不区分天地神
        diPan: ganHere,
        tianPan: tianGanHere,
        tianPanAnGan: ganHere,
        renPanAnGan: ganHere,
        yinGan: ganHere,
      );
    }

    // 中 5 EachGong：天禽星家，其余字段寄坤2（保留 UI 兼容）
    final kunGong = result[HouTianGua.Kun]!;
    final ganAtCenter = diPan[5] ?? TianGan.WU;
    result[HouTianGua.Center] = EachGong(
      gongNumber: 5,
      gongGua: HouTianGua.Center,
      star: NineStarsEnum.QIN, // 天禽：中宫为天禽星之家
      door: kunGong.door,
      god: kunGong.god,
      diGod: kunGong.diGod,
      diPan: ganAtCenter,
      tianPan: ganAtCenter, // 中5无独立天盘干（已寄出至坤2 副位）
      tianPanAnGan: ganAtCenter,
      renPanAnGan: ganAtCenter,
      yinGan: ganAtCenter,
    );

    // 中宫寄干 + 天禽寄宫（同时家奇门 settleCenterGongJiGong 逻辑）
    _settleJiGong(result, ganAtCenter, kunGong.diPan);

    return result;
  }

  /// 中宫寄干 + 天禽寄宫
  ///
  /// 算法（同时家奇门 `_settle`）：
  /// 1. 寄宫为坤2（月家 / 年家固定寄2，不依赖 jieQi）
  /// 2. 坤2.diPanJiGan = 中5地盘干（中宫地盘干寄到坤2的副位）
  /// 3. 沿天盘找出 g.tianPan == 坤2.diPan 的宫 X：
  ///    - X 即天禽星天盘寄宫
  ///    - X.tianPanJiGan = 中5地盘干
  ///    - X.isJiTianQin = true（标记天禽星寄于此宫）
  void _settleJiGong(
    Map<HouTianGua, EachGong> gongRes,
    TianGan ganAtCenter,
    TianGan kunDiPanGan,
  ) {
    final jiGong = gongRes[HouTianGua.Kun];
    if (jiGong == null) return;
    // (1) 中宫地盘干寄坤2 副位
    jiGong.diPanJiGan = ganAtCenter;
    // (2) 天盘上坤2地盘干所落之宫 = 天禽寄宫
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
