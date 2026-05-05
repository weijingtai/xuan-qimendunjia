import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_ri_jia_stars.dart';
import 'package:qimendunjia/model/each_gong.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';

/// 日家奇门排盘器（独立实现）
///
/// 算法依据：
/// - [`docs/more_qimen/ri_jia_algorithm.md`](../../docs/more_qimen/ri_jia_algorithm.md) §3-§6
/// - 用户权威 spec（2026-05-04 修订）：旬头驱动 + 阳遁顺排 / 阴遁逆排
///
/// **不复用** [`GanZhiDrivenQiMenPan`] —— 日家用旬头驱动的飞布机制，
/// 与时/月/年家"旬首-值符"机制不同构（详见对照表 §五、§七）。
///
/// ## 核心算法
///
/// **九星飞布（含中5）**：
///
/// 1. **太乙起宫由日柱+阴阳遁决定**（旬头歌诀）：
///
///    | 旬头 | 阳遁起宫 | 阴遁起宫 |
///    | :--: | :--: | :--: |
///    | 甲子 | 艮8 | 坤2 |
///    | 甲戌 | 离9 | 坎1 |
///    | 甲申 | 坎1 | 离9 |
///    | 甲午 | 坤2 | 艮8 |
///    | 甲辰 | 震3 | 兑7 |
///    | 甲寅 | 巽4 | 乾6 |
///
///    旬内每多一天，起宫顺移 1（阳遁）或逆移 1（阴遁），直至旬末（癸日）回到旬头同宫。
///
///    公式（设 `d = jiazi.number - 1`, `n = d ÷ 10`, `i = d % 10`）：
///    - 阳遁起宫 = `((7 + n + i) mod 9) + 1`
///    - 阴遁起宫 = `((1 - n - i) mod 9) + 1`
///
/// 2. **从太乙起宫填入 9 星**（太乙→摄提→...→天乙）：
///    - 阳遁：数值 +1 顺排
///    - 阴遁：数值 -1 逆排
///
/// **八门排布**（用户 2026-05-04 spec）：
/// - 阳干日（甲丙戊庚壬）：从休门宫起，沿 **后天八卦顺时针** 路径
///   `[1坎,8艮,3震,4巽,9离,2坤,7兑,6乾]` 排 `[休,生,伤,杜,景,死,惊,开]`
/// - 阴干日（乙丁己辛癸）：从休门宫起，沿 **后天八卦逆时针** 路径
///   `[1坎,6乾,7兑,2坤,9离,4巽,3震,8艮]` 排 `[休,生,伤,杜,景,死,惊,开]`
/// - 中5无门
///
/// **占位策略**（日家不布三奇六仪、不用八神）：
/// - 所有干字段（diPan / tianPan / tianPanAnGan / renPanAnGan / yinGan）填 [TianGan.WU]
/// - 神字段（god / diGod）填 [EightGodsEnum.ZHI_FU]
/// - 中5的 door 占位为 [EightDoorEnum.XIU]（UI 渲染时按 `gongGua == HouTianGua.Center` 跳过）
/// - [zhiFuStar] 占位为太乙、[zhiShiDoor] 占位为休门
class RiJiaQiMen {
  final RiJiaJu ju;
  final PanArrangeSettings settings;

  /// 每宫信息（含中5；中5的 door 是占位）
  late final Map<HouTianGua, EachGong> gongMapper;

  /// 当日太乙落宫（占位用作 [zhiFuStarAtGong]）
  late final HouTianGua dayMainStarGong;

  /// 当日值符星占位 = 太乙
  RiJiaStarEnum get dayMainStar => RiJiaStarEnum.TAI_YI;

  /// 值符星（占位用太乙；日家无真值符）
  QiMenStar get zhiFuStar => dayMainStar;

  /// 值符星所在宫（= 太乙落宫）
  HouTianGua get zhiFuStarAtGong => dayMainStarGong;

  /// 值使门（占位用休门；日家以休门为纲）
  EightDoorEnum get zhiShiDoor => EightDoorEnum.XIU;

  /// 值使门所在宫（= 休门宫）
  HouTianGua get zhiShiDoorAtGong => ju.xiuMenGong;

  RiJiaQiMen({required this.ju, required this.settings}) {
    _arrange();
  }

  // ============== 常量序列 ==============

  /// 后天八卦顺时针跳5：1坎→8艮→3震→4巽→9离→2坤→7兑→6乾→1坎
  ///
  /// 用于 **阳干日** 的八门排布（用户 2026-05-04 权威 spec）。
  static const List<int> _clockwiseSkip5 = [1, 8, 3, 4, 9, 2, 7, 6];

  /// 后天八卦逆时针跳5：1坎→6乾→7兑→2坤→9离→4巽→3震→8艮→1坎
  ///
  /// 用于 **阴干日** 的八门排布（用户 2026-05-04 权威 spec）。
  static const List<int> _counterClockwiseSkip5 = [1, 6, 7, 2, 9, 4, 3, 8];

  /// 八门固定顺序：休、生、伤、杜、景、死、惊、开
  static const List<EightDoorEnum> _eightDoorOrder = [
    EightDoorEnum.XIU,    // 休
    EightDoorEnum.SHENG,  // 生
    EightDoorEnum.SHANG,  // 伤
    EightDoorEnum.DU,     // 杜
    EightDoorEnum.JING_S, // 景
    EightDoorEnum.SI,     // 死
    EightDoorEnum.JING_W, // 惊
    EightDoorEnum.KAI,    // 开
  ];

  // ============== 排盘流程 ==============

  void _arrange() {
    // 1. 九星飞布（含中5；阳遁顺排 / 阴遁逆排，太乙起宫由日柱+阴阳遁决定）
    final starByGong = _arrangeRiJiaStars(ju.yinYangDun, ju.dayJiaZi);

    // 太乙落宫即"值符占位"宫号
    final taiYiGong = taiYiQiGong(ju.dayJiaZi, ju.yinYangDun);
    dayMainStarGong = taiYiGong;

    // 2. 八门排布（基于日干阴阳）
    final doorByGong = _arrangeEightDoors(ju.xiuMenGong, ju.isYangDayGan);

    // 3. 组装 9 宫
    final result = <HouTianGua, EachGong>{};
    for (int i = 1; i <= 9; i++) {
      final gua = HouTianGua.getGua(i);
      final star = starByGong[i];
      if (star == null) {
        throw StateError('_arrange: 宫 $i 缺九星');
      }
      // 中5无门，占位用休门；UI 层按 gongGua == Center 判断后跳过
      final door = doorByGong[i] ?? EightDoorEnum.XIU;
      result[gua] = EachGong(
        gongNumber: i,
        gongGua: gua,
        star: star,
        door: door,
        // 神 / 干字段：日家不用，全部占位
        god: EightGodsEnum.ZHI_FU,
        diGod: EightGodsEnum.ZHI_FU,
        diPan: TianGan.WU,
        tianPan: TianGan.WU,
        tianPanAnGan: TianGan.WU,
        renPanAnGan: TianGan.WU,
        yinGan: TianGan.WU,
      );
    }
    gongMapper = result;
  }

  /// 太乙起宫(用户 2026-05-04 权威 spec — 旬头驱动)
  ///
  /// 算法:
  ///   d = jiazi.number - 1     (0-59)
  ///   n = d ÷ 10               (旬号 0-5)
  ///   i = d % 10               (旬内序号 0-9, 0=甲日, 9=癸日)
  ///   阳遁起宫 = ((7 + n + i) mod 9) + 1
  ///   阴遁起宫 = ((1 - n - i) mod 9) + 1
  ///
  /// 旬头起宫表(由公式推得,可手工验证):
  ///
  /// | 旬头 | n | 阳遁 | 阴遁 |
  /// | :--: | :--: | :--: | :--: |
  /// | 甲子 | 0 | 艮8 | 坤2 |
  /// | 甲戌 | 1 | 离9 | 坎1 |
  /// | 甲申 | 2 | 坎1 | 离9 |
  /// | 甲午 | 3 | 坤2 | 艮8 |
  /// | 甲辰 | 4 | 震3 | 兑7 |
  /// | 甲寅 | 5 | 巽4 | 乾6 |
  ///
  /// 旬内每天 +1(阳遁) / -1(阴遁), 旬末癸日回到旬头同宫,下一旬头再 +1/-1。
  static HouTianGua taiYiQiGong(JiaZi dayJiaZi, YinYang yinYangDun) {
    final d = dayJiaZi.number - 1;
    final n = d ~/ 10;
    final i = d % 10;
    int gongNumber;
    if (yinYangDun.isYang) {
      gongNumber = ((7 + n + i) % 9) + 1;
    } else {
      // 阴遁逆移；用 +9 让 mod 行为更明确(虽然 Dart 的 % 对负数也返回非负)
      gongNumber = (((1 - n - i) % 9) + 9) % 9 + 1;
    }
    return HouTianGua.getGua(gongNumber);
  }

  /// 九星飞布(含中5;9 星 ↔ 9 宫一一对应)
  ///
  /// 从太乙起宫开始,按宫号填入 9 星(太乙→摄提→...→天乙):
  ///   - 阳遁: 数值 +1 顺排
  ///   - 阴遁: 数值 -1 逆排
  Map<int, RiJiaStarEnum> _arrangeRiJiaStars(YinYang yinYang, JiaZi dayJiaZi) {
    final taiYiGong = taiYiQiGong(dayJiaZi, yinYang).houTianOrder;
    final result = <int, RiJiaStarEnum>{};
    for (int starIdx = 0; starIdx < 9; starIdx++) {
      final delta = yinYang.isYang ? starIdx : -starIdx;
      final gongNumber = (((taiYiGong - 1 + delta) % 9) + 9) % 9 + 1;
      result[gongNumber] = RiJiaStarEnum.fromNumber(starIdx + 1);
    }
    return result;
  }

  /// 八门排布
  ///
  /// 阳干：从休门宫起，沿 [_clockwiseSkip5]（顺时针）排 [_eightDoorOrder]
  /// 阴干：从休门宫起，沿 [_counterClockwiseSkip5]（逆时针）排 [_eightDoorOrder]
  /// 中5 无门（不在返回 Map 中）。
  Map<int, EightDoorEnum> _arrangeEightDoors(
      HouTianGua xiuMenGong, bool isYangGan) {
    final path = isYangGan ? _clockwiseSkip5 : _counterClockwiseSkip5;
    final xiuMenGongNumber = xiuMenGong.houTianOrder;
    final startIdx = path.indexOf(xiuMenGongNumber);
    if (startIdx < 0) {
      throw StateError(
          '_arrangeEightDoors: 休门宫号 $xiuMenGongNumber 不在路径 $path 中（中5不应作为休门宫）');
    }
    final result = <int, EightDoorEnum>{};
    for (int i = 0; i < 8; i++) {
      final gongNumber = path[(startIdx + i) % 8];
      result[gongNumber] = _eightDoorOrder[i];
    }
    return result;
  }
}
