import 'package:common/adapters/lunar_adapter.dart';
import 'package:common/enums.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';

/// 日家奇门局计算器
///
/// 算法依据：[`docs/more_qimen/ri_jia_algorithm.md`](../../docs/more_qimen/ri_jia_algorithm.md)
///
/// 核心步骤：
/// 1. 取日柱（依赖 [LunarAdapter.fromDate]）
/// 2. 阴阳遁判定（按节气；冬至 → 夏至阳，夏至 → 冬至阴）
/// 3. **3 日同宫起休门**（按日柱 60 甲子序号 ÷ 3 取组号查表）
/// 4. 计算 [daysSinceJiaZi] = `dayJiaZi.number - 1`，作为太乙顺飞偏移
///
/// "3 日同宫" 算法本质（§3 数学化）：
///   - 60 甲子按 3 日一组分 20 组，组号 [0, 19]
///   - 每 8 组循环一次（跳过中5），即 `group_index % 8` 决定落宫
///   - 阳遁顺序：[1坎, 2坤, 3震, 4巽, 6乾, 7兑, 8艮, 9离]（跳过中5）
///   - 阴遁顺序：[9离, 8艮, 7兑, 6乾, 4巽, 3震, 2坤, 1坎]（阳遁逆序）
///
/// 经 60 甲子全覆盖验证：与 §3 文档表完全一致（详见
/// `test/test_ri_jia_qi_men.dart` 的 `_yangDunXiuMenMap.length == 20` 类自检）。
class RiJiaQiMenJuCalculator {
  final DateTime dateTime;

  RiJiaQiMenJuCalculator({required this.dateTime});

  /// 阳遁 8 宫循环顺序（跳过中5）
  ///
  /// 按 60 甲子顺序的 20 个 3 日组，依次落 [1坎,2坤,3震,4巽,6乾,7兑,8艮,9离] 循环。
  static const List<int> _yangDunGongCycle = [1, 2, 3, 4, 6, 7, 8, 9];

  /// 阴遁 8 宫循环顺序（阳遁逆序）
  static const List<int> _yinDunGongCycle = [9, 8, 7, 6, 4, 3, 2, 1];

  /// 由日柱定休门宫
  ///
  /// [dayJiaZi]：日柱（1-60）
  /// [yinYangDun]：阴阳遁
  ///
  /// 返回休门所落宫（1-9，永不为 5）。
  static HouTianGua calcXiuMenGong(JiaZi dayJiaZi, YinYang yinYangDun) {
    final groupIndex = (dayJiaZi.number - 1) ~/ 3; // [0, 19]
    final cycleIndex = groupIndex % 8; // [0, 7]
    final cycle =
        yinYangDun.isYang ? _yangDunGongCycle : _yinDunGongCycle;
    return HouTianGua.getGua(cycle[cycleIndex]);
  }

  RiJiaJu calculate() {
    final lunar = LunarAdapter.fromDate(dateTime);
    final dayJiaZi = JiaZi.getFromGanZhiValue(lunar.getDayInGanZhi())!;

    // 1. 阴阳遁判定（按节气）
    final jieQiName =
        lunar.getCurrentJieQi()?.getName() ?? lunar.getPrevJieQi().getName();
    final jieQi = TwentyFourJieQi.fromName(jieQiName);
    final yinYangDun = jieQi.yinYangDun;

    // 2. 起休门：3 日同宫公式查表
    final xiuMenGong = calcXiuMenGong(dayJiaZi, yinYangDun);

    // 3. 距甲子日天数（用于太乙顺飞偏移）
    final daysSinceJiaZi = dayJiaZi.number - 1;

    final fourZhu = [
      lunar.getYearInGanZhi(),
      lunar.getMonthInGanZhi(),
      lunar.getDayInGanZhi(),
      lunar.getTimeInGanZhi(),
    ].join(' ');

    return RiJiaJu(
      id: 'rijia-${dateTime.millisecondsSinceEpoch}',
      panDateTime: dateTime,
      yinYangDun: yinYangDun,
      dayJiaZi: dayJiaZi,
      daysSinceJiaZi: daysSinceJiaZi,
      xiuMenGong: xiuMenGong,
      jieQiAt: jieQi,
      fourZhuEightChar: fourZhu,
    );
  }
}
