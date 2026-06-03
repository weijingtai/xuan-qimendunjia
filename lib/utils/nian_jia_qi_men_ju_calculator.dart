import 'package:xuan_common/adapters/lunar_adapter.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/nian_jia_ju.dart';
import 'package:qimendunjia/utils/nian_jia_san_yuan_anchor.dart';

/// 年家奇门局计算器
///
/// 算法依据：docs/more_qimen/nian_jia_algorithm.md
///
/// 步骤：
/// 1. 取年柱（依赖 LunarAdapter 立春纪年）
/// 2. 把 yearJiaZi 对应的"实际公历年"传给 [NianJiaSanYuanAnchor]
///    定三元 + 元内年序
/// 3. 三元 → 起局宫
class NianJiaQiMenJuCalculator {
  final DateTime dateTime;

  NianJiaQiMenJuCalculator({required this.dateTime});

  NianJiaJu calculate() {
    final lunar = LunarAdapter.fromDate(dateTime);
    final yearJiaZi = JiaZi.getFromGanZhiValue(lunar.getYearInGanZhi())!;

    // 立春纪年与公历年可能不一致：2024-01-15 的 yearJiaZi 是癸卯（即 2023 年柱），
    // 此时锚点查询应传 2023 而非公历年 2024。
    // 通过 dateTime.year 与 yearJiaZi 的差值推得：
    final solarYearForAnchor = _yearJiaZiToSolarYear(yearJiaZi, dateTime);
    final (sanYuan, indexInYuan) =
        NianJiaSanYuanAnchor.yearToYuanAndIndex(solarYearForAnchor);
    final qiJuGong = NianJiaSanYuanAnchor.sanYuanToQiJuGong(sanYuan);

    final fourZhu = [
      lunar.getYearInGanZhi(),
      lunar.getMonthInGanZhi(),
      lunar.getDayInGanZhi(),
      lunar.getTimeInGanZhi(),
    ].join(' ');

    return NianJiaJu(
      id: 'nianjia-${solarYearForAnchor}-${dateTime.millisecondsSinceEpoch}',
      panDateTime: dateTime,
      yearJiaZi: yearJiaZi,
      sanYuan: sanYuan,
      yearIndexInYuan: indexInYuan,
      qiJuGong: qiJuGong,
      fourZhuEightChar: fourZhu,
    );
  }

  /// 把 [yearJiaZi] 对应回实际公历年。
  ///
  /// LunarAdapter 已按立春切换年柱，所以 [dateTime.year] 与 yearJiaZi 可能差 1。
  /// 用 60 年甲子周期 + dateTime.year 邻域定位（搜索 ±1 年内匹配的甲子序号）。
  int _yearJiaZiToSolarYear(JiaZi yearJiaZi, DateTime around) {
    // 60 甲子: 1984 = 甲子, 故 公历年 → jiaZi.number 的关系：
    // jiaZiNumber = ((year - 1984) % 60 + 60) % 60 + 1
    int yearJiaZiNumber(int y) => ((y - 1984) % 60 + 60) % 60 + 1;

    // 候选年: dateTime.year 与 dateTime.year - 1（立春前可能属上一年柱）
    for (final candidate in [around.year, around.year - 1]) {
      if (yearJiaZiNumber(candidate) == yearJiaZi.number) {
        return candidate;
      }
    }
    // 兜底（理论不会到这里）
    return around.year;
  }
}
