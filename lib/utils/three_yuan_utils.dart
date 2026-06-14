import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';

/// 三元判断工具
///
/// 从 [ShiJiaQiMenJuCalculator] 中提取的纯函数，
/// 用于根据符头甲子判断上中下三元。
/// 页面层不再需要导入 qi_men_ju_calculator.dart。
class ThreeYuanUtils {
  ThreeYuanUtils._();

  /// 根据符头甲子判断三元
  ///
  /// - 子午卯酉 → 上元
  /// - 寅申巳亥 → 中元
  /// - 辰戌丑未 → 下元
  static EnumThreeYuan getThreeYuanByFuHead(JiaZi fuTou) {
    if (DiZhi.fourMuYu.contains(fuTou.diZhi)) {
      return EnumThreeYuan.START;
    } else if (DiZhi.fourYiMa.contains(fuTou.diZhi)) {
      return EnumThreeYuan.MIDDLE;
    } else {
      return EnumThreeYuan.END;
    }
  }
}
