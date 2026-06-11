import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/san_yuan_type.dart';

/// 年家三元起算锚点
///
/// 算法依据：docs/more_qimen/nian_jia_algorithm.md §3-§4
/// 锚点（方案 A，主流《奇门遁甲秘笈大全》）：
/// - 上元第 1 年 = 1864（公元）
/// - 中元第 1 年 = 1924
/// - 下元第 1 年 = 1984（当前所在元，覆盖到 2043）
///
/// 周期：60 年/元 × 3 元 = 180 年大循环。
class NianJiaSanYuanAnchor {
  static const int upperYuanStartYear = 1864;
  static const int middleYuanStartYear = 1924;
  static const int lowerYuanStartYear = 1984;
  static const int yearsPerYuan = 60;
  static const int totalCycle = yearsPerYuan * 3; // 180

  /// 反查：公历年 → (三元, 元内年序 1-60)
  ///
  /// 输入年应当与立春纪年的 yearJiaZi 对应（即 2024-01-15 应传 2023）
  static (SanYuanType, int) yearToYuanAndIndex(int year) {
    final offset = year - upperYuanStartYear;
    final normalized = ((offset % totalCycle) + totalCycle) % totalCycle;

    if (normalized < yearsPerYuan) {
      return (SanYuanType.SHANG, normalized + 1);
    } else if (normalized < yearsPerYuan * 2) {
      return (SanYuanType.ZHONG, normalized - yearsPerYuan + 1);
    } else {
      return (SanYuanType.XIA, normalized - yearsPerYuan * 2 + 1);
    }
  }

  /// 年家三元 → 起局宫（**与月家映射不同**）
  ///
  /// - 月家：上元坎 1 / 中元兑 7 / 下元巽 4（按年支孟仲季）
  /// - 年家：上元坎 1 / 中元巽 4 / 下元兑 7（按 60 年三元）
  static HouTianGua sanYuanToQiJuGong(SanYuanType sy) {
    switch (sy) {
      case SanYuanType.SHANG:
        return HouTianGua.Kan; // 1
      case SanYuanType.ZHONG:
        return HouTianGua.Xun; // 4
      case SanYuanType.XIA:
        return HouTianGua.Dui; // 7
    }
  }
}
