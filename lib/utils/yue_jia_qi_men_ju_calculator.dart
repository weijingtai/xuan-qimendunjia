import 'package:xuan_common/adapters/lunar_adapter.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/san_yuan_type.dart';
import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';

/// 月家奇门三元定局策略
///
/// 用户规范："有两种说法"：
/// - [COARSE]（方法 2，粗分）：每 5 年用一个固定局数（上元 7 / 中元 1 / 下元 4）
/// - [FINE]（方法 1，细分）：5 年内每 10 个月切换一次局数，6 段递减
///   （上元 7→6→5→4→3→2 / 中元 1→9→8→7→6→5 / 下元 4→3→2→1→9→8）
enum YueJiaSanYuanStrategy {
  /// 粗分：5 年一局（默认）
  COARSE,

  /// 细分：10 月一局，6 段递减
  FINE,
}

/// 月家奇门局计算器
///
/// 算法依据：docs/more_qimen/yue_jia_algorithm.md
///
/// 核心步骤：
/// 1. 取年柱、月柱（依赖 LunarAdapter，已含五虎遁推月干 + 节气分月支）
/// 2. **符头年回溯**：年干非甲己时倒推到最近的甲或己年作为符头
/// 3. 按符头年的年支孟仲季定三元
/// 4. 按 [strategy] 决定局数：
///    - COARSE：局数 = 三元起局数（7/1/4）
///    - FINE：按月柱在 60 月周期的 bucket（每 10 月一段）递减
/// 5. 局数 → 起局宫
class YueJiaQiMenJuCalculator {
  final DateTime dateTime;
  final YueJiaSanYuanStrategy strategy;

  YueJiaQiMenJuCalculator({
    required this.dateTime,
    this.strategy = YueJiaSanYuanStrategy.COARSE,
  });

  /// 找出年柱的"符头年"
  ///
  /// 用户规范："若年干非甲或己，需倒推至最近的甲或己年作为符头，再定元。"
  ///
  /// - 甲己年自身即符头年（直接返回）
  /// - 其他年份倒推 1-4 步必命中（甲己年每 5 年出现一次）
  static JiaZi findFuTouYear(JiaZi yearJiaZi) {
    JiaZi current = yearJiaZi;
    // 安全边界：60 甲子内最多 4 步即可找到甲己年
    for (int step = 0; step < 5; step++) {
      if (current.gan == TianGan.JIA || current.gan == TianGan.JI) {
        return current;
      }
      int prevNumber = current.number - 1;
      if (prevNumber < 1) prevNumber = 60;
      current = JiaZi.getByNumber(prevNumber);
    }
    throw StateError(
        '未能在 5 步内找到符头年（理论不会到达；输入：${yearJiaZi.name}）');
  }

  /// 年支 → 三元映射
  ///
  /// 用户最新规范（2026-05-01 校准）：
  /// - 子午卯酉 → 上元（七局，兑7 起）
  /// - 寅申巳亥 → 中元（一局，坎1 起）
  /// - 辰戌丑未 → 下元（四局，巽4 起）
  ///
  /// **注意**：调用前应先用 [findFuTouYear] 取得符头年，再用其年支查询。
  static SanYuanType yearZhiToSanYuan(DiZhi yearZhi) {
    const shang = {DiZhi.ZI, DiZhi.WU, DiZhi.MAO, DiZhi.YOU};
    const zhong = {DiZhi.YIN, DiZhi.SHEN, DiZhi.SI, DiZhi.HAI};
    if (shang.contains(yearZhi)) return SanYuanType.SHANG;
    if (zhong.contains(yearZhi)) return SanYuanType.ZHONG;
    return SanYuanType.XIA;
  }

  /// 三元 → 起局数（COARSE 法用）
  ///
  /// 上元 7 / 中元 1 / 下元 4
  static int sanYuanToStartingJu(SanYuanType sy) {
    switch (sy) {
      case SanYuanType.SHANG:
        return 7;
      case SanYuanType.ZHONG:
        return 1;
      case SanYuanType.XIA:
        return 4;
    }
  }

  /// 局数 → 起局宫
  ///
  /// 1坎 / 2坤 / 3震 / 4巽 / 5中（寄坤2）/ 6乾 / 7兑 / 8艮 / 9离
  static HouTianGua juNumberToQiJuGong(int juNumber) {
    return HouTianGua.values
        .firstWhere((g) => g.houTianOrder == juNumber);
  }

  /// 三元 → 起局宫（COARSE 法用，等价于 [juNumberToQiJuGong] of [sanYuanToStartingJu]）
  ///
  /// 保留作为向后兼容入口（既有测试 / 调用方使用此名）。
  /// 用户最新规范：
  /// - 上元 → 兑7（阴七局）
  /// - 中元 → 坎1（阴一局）
  /// - 下元 → 巽4（阴四局）
  static HouTianGua sanYuanToQiJuGong(SanYuanType sy) =>
      juNumberToQiJuGong(sanYuanToStartingJu(sy));

  /// 月柱 + 三元 → 局数（FINE 法用）
  ///
  /// 用户规范（方法 1）：5 年（60 月）内按月柱位置分 6 段（每段 10 月），
  /// 局数从该三元起局数开始，每 10 月递减 1。
  ///
  /// 月柱周期：从符头年（甲或己年）的丙寅月（正月）开始的 60 月。
  /// 60 甲子里 丙寅月 的 number = 3。所以：
  ///   relIndex = (monthJiaZi.number - 3 + 60) % 60   ∈ [0, 59]
  ///   bucket = relIndex ~/ 10                         ∈ [0, 5]
  ///   juNumber = ((startingJu - bucket - 1) % 9 + 9) % 9 + 1
  ///
  /// 例：上元（startingJu=7）下：
  ///   bucket 0 → 7局, 1 → 6, 2 → 5, 3 → 4, 4 → 3, 5 → 2 ✓
  /// 中元（startingJu=1）下：
  ///   bucket 0 → 1局, 1 → 9, 2 → 8, 3 → 7, 4 → 6, 5 → 5 ✓
  /// 下元（startingJu=4）下：
  ///   bucket 0 → 4局, 1 → 3, 2 → 2, 3 → 1, 4 → 9, 5 → 8 ✓
  static int juNumberFromMonth(JiaZi monthJiaZi, SanYuanType sanYuan) {
    final relIndex = (monthJiaZi.number - 3 + 60) % 60;
    final bucket = relIndex ~/ 10;
    final startingJu = sanYuanToStartingJu(sanYuan);
    return ((startingJu - bucket - 1) % 9 + 9) % 9 + 1;
  }

  YueJiaJu calculate() {
    final lunar = LunarAdapter.fromDate(dateTime);
    final yearJiaZi = JiaZi.getFromGanZhiValue(lunar.getYearInGanZhi())!;
    final monthJiaZi = JiaZi.getFromGanZhiValue(lunar.getMonthInGanZhi())!;

    // 符头年回溯：非甲己年倒推到最近的甲或己年
    final fuTouYear = findFuTouYear(yearJiaZi);
    final sanYuan = yearZhiToSanYuan(fuTouYear.diZhi);

    // 按策略决定局数：COARSE 用三元起局数（5 年固定）；FINE 按月柱细分
    final juNumber = strategy == YueJiaSanYuanStrategy.FINE
        ? juNumberFromMonth(monthJiaZi, sanYuan)
        : sanYuanToStartingJu(sanYuan);
    final qiJuGong = juNumberToQiJuGong(juNumber);

    final fourZhu = [
      lunar.getYearInGanZhi(),
      lunar.getMonthInGanZhi(),
      lunar.getDayInGanZhi(),
      lunar.getTimeInGanZhi(),
    ].join(' ');
    return YueJiaJu(
      id: 'yuejia-${strategy.name}-${dateTime.millisecondsSinceEpoch}',
      panDateTime: dateTime,
      yearJiaZi: yearJiaZi,
      monthJiaZi: monthJiaZi,
      sanYuan: sanYuan,
      qiJuGong: qiJuGong,
      fourZhuEightChar: fourZhu,
    );
  }
}
