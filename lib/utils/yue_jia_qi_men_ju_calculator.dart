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

  /// 年支 → 三元映射（按孟仲季）
  ///
  /// 寅申巳亥 → 上元（孟）
  /// 子午卯酉 → 中元（仲）
  /// 辰戌丑未 → 下元（季）
  static SanYuanType yearZhiToSanYuan(DiZhi yearZhi) {
    const meng = {DiZhi.YIN, DiZhi.SHEN, DiZhi.SI, DiZhi.HAI};
    const zhong = {DiZhi.ZI, DiZhi.WU, DiZhi.MAO, DiZhi.YOU};
    if (meng.contains(yearZhi)) return SanYuanType.SHANG;
    if (zhong.contains(yearZhi)) return SanYuanType.ZHONG;
    return SanYuanType.XIA;
  }

  /// 月家三元 → 起局宫
  ///
  /// **注意**：与年家映射不同，请勿混用。
  /// 月家：上元坎1 / 中元兑7 / 下元巽4
  static HouTianGua sanYuanToQiJuGong(SanYuanType sy) {
    switch (sy) {
      case SanYuanType.SHANG:
        return HouTianGua.Kan; // 1
      case SanYuanType.ZHONG:
        return HouTianGua.Dui; // 7
      case SanYuanType.XIA:
        return HouTianGua.Xun; // 4
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
