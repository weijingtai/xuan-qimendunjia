import 'package:metaphysics_core/enums.dart';

/// 符头计算工具
///
/// 从 [ChaiBuCalculator] 中提取的纯函数，
/// 用于根据日干支计算符头。
/// 页面层不再需要导入 qi_men_ju_calculator.dart。
class FuTouUtils {
  FuTouUtils._();

  /// 拆补法 凡 甲己为符头
  ///
  /// 根据日干支获取符头甲子
  static JiaZi getFuTouByDayJiaZi(JiaZi dayGanZhi) {
    int model = dayGanZhi.number % 5;
    JiaZi fuTou;
    if (model % 5 == 0) {
      // 当前为日干支为 每一符头的最后一个
      fuTou = JiaZi.getByNumber(dayGanZhi.number - 4);
    } else if (model == 1) {
      // 当前日干支为 为 符头自己
      fuTou = dayGanZhi;
    } else {
      // 当前日干支为 符头的前一个
      fuTou = JiaZi.getByNumber(dayGanZhi.number - model + 1);
    }
    return fuTou;
  }
}
