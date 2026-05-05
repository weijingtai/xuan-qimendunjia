import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';

/// 日家九星
///
/// 顺序：太乙(1) → 摄提(2) → 轩辕(3) → 招摇(4) → 天符(5) → 青龙(6) → 咸池(7) → 太阴(8) → 天乙(9)
///
/// 与时家北斗九星（NineStarsEnum）**不通用**，是日家专属星集。
///
/// 算法依据：[`docs/more_qimen/ri_jia_algorithm.md`](../../../docs/more_qimen/ri_jia_algorithm.md) §1。
///
/// 吉凶（用户 2026-05-04 校准）：
///   - 吉星（4 颗）：太乙、青龙、太阴、天乙
///   - 中平（2 颗）：天符、轩辕
///   - 凶星（3 颗）：摄提、招摇、咸池
///
/// 排盘特性（与时家不同）：
///   - 不强调五行（[fiveXing] 恒为 null）
///   - 无"原宫"概念（[originalGong] 恒为 null，不参与伏吟反吟判定）
///   - 9 星按宫号 1-9 一一对应（含中5），不跳宫
enum RiJiaStarEnum implements QiMenStar {
  TAI_YI(1, "太乙", "乙"),
  SHE_TI(2, "摄提", "摄"),
  XUAN_YUAN(3, "轩辕", "轩"),
  ZHAO_YAO(4, "招摇", "招"),
  TIAN_FU(5, "天符", "符"),
  QING_LONG(6, "青龙", "青"),
  XIAN_CHI(7, "咸池", "咸"),
  TAI_YIN(8, "太阴", "阴"),
  TIAN_YI(9, "天乙", "天乙"); // 注意：双字单字名，UI 渲染时优先使用 [name]

  @override
  final int number;

  @override
  final String name;

  @override
  final String singleCharName;

  /// 日家不强调五行，恒为 null
  @override
  FiveXing? get fiveXing => null;

  /// 日家 day-count 体系无"原宫"概念，恒为 null
  /// （故 [EachGong.isStarFuYin] / [isStarFanYin] 在日家恒为 false）
  @override
  HouTianGua? get originalGong => null;

  const RiJiaStarEnum(this.number, this.name, this.singleCharName);

  /// 是否为吉星：太乙、青龙、太阴、天乙（用户 2026-05-04 校准）
  bool get isJi =>
      this == TAI_YI ||
      this == QING_LONG ||
      this == TAI_YIN ||
      this == TIAN_YI;

  /// 是否为中平星：天符、轩辕（用户 2026-05-04 校准）
  bool get isPing => this == TIAN_FU || this == XUAN_YUAN;

  /// 是否为凶星：摄提、招摇、咸池（用户 2026-05-04 校准）
  bool get isXiong =>
      this == SHE_TI || this == ZHAO_YAO || this == XIAN_CHI;

  static RiJiaStarEnum fromNumber(int n) =>
      values.firstWhere((e) => e.number == n,
          orElse: () => throw ArgumentError(
              'RiJiaStarEnum.fromNumber: 期望 1-9，实际 $n'));

  static RiJiaStarEnum fromName(String name) =>
      values.firstWhere((e) => e.name == name,
          orElse: () => throw ArgumentError(
              'RiJiaStarEnum.fromName: 未找到名为 $name 的日家星'));
}
