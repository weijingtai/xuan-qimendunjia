import 'package:common/adapters/lunar_adapter.dart';
import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/san_yuan_type.dart';
import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';

/// 月家奇门局计算器
///
/// 算法依据：docs/more_qimen/yue_jia_algorithm.md
///
/// 核心步骤：
/// 1. 取年柱、月柱（依赖 LunarAdapter，已含五虎遁推月干 + 节气分月支）
/// 2. 按年支孟仲季定三元
/// 3. 三元 → 起局宫
class YueJiaQiMenJuCalculator {
  final DateTime dateTime;

  YueJiaQiMenJuCalculator({required this.dateTime});

  /// 年支 → 三元映射
  ///
  /// 用户最新规范（2026-05-01 校准）：
  /// - 子午卯酉 → 上元（七局，兑7 起）
  /// - 寅申巳亥 → 中元（一局，坎1 起）
  /// - 辰戌丑未 → 下元（四局，巽4 起）
  static SanYuanType yearZhiToSanYuan(DiZhi yearZhi) {
    const shang = {DiZhi.ZI, DiZhi.WU, DiZhi.MAO, DiZhi.YOU};
    const zhong = {DiZhi.YIN, DiZhi.SHEN, DiZhi.SI, DiZhi.HAI};
    if (shang.contains(yearZhi)) return SanYuanType.SHANG;
    if (zhong.contains(yearZhi)) return SanYuanType.ZHONG;
    return SanYuanType.XIA;
  }

  /// 月家三元 → 起局宫
  ///
  /// 用户最新规范：
  /// - 上元 → 兑7（阴七局）
  /// - 中元 → 坎1（阴一局）
  /// - 下元 → 巽4（阴四局）
  ///
  /// **注意**：与年家映射不同，请勿混用。
  static HouTianGua sanYuanToQiJuGong(SanYuanType sy) {
    switch (sy) {
      case SanYuanType.SHANG:
        return HouTianGua.Dui; // 7（上元 - 子午卯酉）
      case SanYuanType.ZHONG:
        return HouTianGua.Kan; // 1（中元 - 寅申巳亥）
      case SanYuanType.XIA:
        return HouTianGua.Xun; // 4（下元 - 辰戌丑未）
    }
  }

  YueJiaJu calculate() {
    final lunar = LunarAdapter.fromDate(dateTime);
    final yearJiaZi = JiaZi.getFromGanZhiValue(lunar.getYearInGanZhi())!;
    final monthJiaZi = JiaZi.getFromGanZhiValue(lunar.getMonthInGanZhi())!;
    final sanYuan = yearZhiToSanYuan(yearJiaZi.diZhi);
    final qiJuGong = sanYuanToQiJuGong(sanYuan);
    final fourZhu = [
      lunar.getYearInGanZhi(),
      lunar.getMonthInGanZhi(),
      lunar.getDayInGanZhi(),
      lunar.getTimeInGanZhi(),
    ].join(' ');
    return YueJiaJu(
      id: 'yuejia-${dateTime.millisecondsSinceEpoch}',
      panDateTime: dateTime,
      yearJiaZi: yearJiaZi,
      monthJiaZi: monthJiaZi,
      sanYuan: sanYuan,
      qiJuGong: qiJuGong,
      fourZhuEightChar: fourZhu,
    );
  }
}
