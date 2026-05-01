import 'package:common/enums.dart';

/// 奇门九星基类接口
///
/// 时家用 NineStarsEnum（蓬/任/冲/辅/英/芮/柱/心/禽），
/// 月家复用此集合，
/// 日家用 RiJiaStarEnum（太乙/摄提/...），
/// 年家用 ZiBaiStarEnum（一白/二黑/...紫白九星）。
///
/// 各家的星集都通过此接口暴露排盘 / UI 渲染所需的共同字段。
/// 详见 docs/more_qimen/extra_hour_plans.md §4.6。
abstract class QiMenStar {
  /// 显示全名（"天蓬" / "太乙" / "一白"）
  String get name;

  /// 单字简写（"蓬" / "乙" / "白"）
  ///
  /// 注意：日家"天乙"是双字、年家紫白星"白"在三处重名（一/六/八白），
  /// UI 渲染时如需消歧应优先使用 [name] 而非本字段。
  String get singleCharName;

  /// 序号（1-9，对应宫数）
  int get number;

  /// 五行属性
  ///
  /// 时家九星与年家紫白星均有；日家不强调五行，可返回 null。
  FiveXing? get fiveXing;

  /// 原宫位
  ///
  /// 时家九星各有原宫，用于伏吟/反吟判定。
  /// 日家 day-count 体系无"原宫"概念，可返回 null。
  /// 年家紫白星名义对应宫位但**不参与伏吟反吟**判定，调用方需注意语义差异。
  HouTianGua? get originalGong;
}
