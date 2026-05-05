import 'package:common/enums.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

import 'base_entity.dart';
import 'base_ju.dart';

/// 日家局实体
///
/// 日家奇门以"日"为单位起盘（区别于时家以时辰、月家以月、年家以年）。
///
/// 算法核心（与其他三家不同）：
/// - **飞盘**（不是转盘）—— 9 个固定宫位间逐宫飞布，不进行整盘旋转
/// - **不布三奇六仪地盘** —— 纯九宫门 + 星
/// - **无值符 / 无值使** —— 以 **休门** 为纲（[xiuMenGong]）
/// - **不用八神** —— 改用黄道黑道、喜神、贵神（神煞体系，作为后续 Phase）
/// - **专属九星**（[RiJiaStarEnum]）—— 太乙、摄提、轩辕、招摇、天符、青龙、咸池、太阴、天乙
///
/// 起盘驱动量：
/// - [yinYangDun]：阴阳遁（按节气；冬至 → 夏至阳，夏至 → 冬至阴）
/// - [dayJiaZi]：日柱（决定休门宫，按"3 日同宫"查表）
/// - [daysSinceJiaZi]：距甲子日天数 d（0-59，决定太乙顺飞偏移）
///
/// 详见 [`docs/more_qimen/ri_jia_algorithm.md`](../../../docs/more_qimen/ri_jia_algorithm.md)
/// 与四家对照表 [`qimen_jia_comparison.md`](../../../docs/more_qimen/qimen_jia_comparison.md)。
class RiJiaJu extends Equatable implements Entity, BaseJu {
  @override
  final String id;

  @override
  final DateTime panDateTime;

  @override
  QiMenJia get jia => QiMenJia.RI;

  @override
  final YinYang yinYangDun;

  @override
  final String fourZhuEightChar;

  /// 日柱（核心驱动量；定休门宫）
  final JiaZi dayJiaZi;

  /// 距上一甲子日的天数（0-59，用于太乙顺飞偏移）
  final int daysSinceJiaZi;

  /// 休门所落宫（按 §3 "3 日同宫" 表查得；日家以休门为纲）
  final HouTianGua xiuMenGong;

  /// 当前节气（用于阴阳遁判定 + UI 显示）
  final TwentyFourJieQi jieQiAt;

  /// 日家"局数" = 休门宫号
  ///
  /// 时/月/年家是局数 = 起局宫号；日家无传统三元局，
  /// 用休门宫号作为对应概念（保持 [BaseJu] 接口语义统一）。
  @override
  int get juNumber => xiuMenGong.houTianOrder;

  /// 日干阴阳（决定八门排布方向：阳干顺、阴干逆）
  bool get isYangDayGan => dayJiaZi.gan.yinYang.isYang;

  RiJiaJu({
    required this.id,
    required this.panDateTime,
    required this.yinYangDun,
    required this.dayJiaZi,
    required this.daysSinceJiaZi,
    required this.xiuMenGong,
    required this.jieQiAt,
    required this.fourZhuEightChar,
  })  : assert(daysSinceJiaZi >= 0 && daysSinceJiaZi < 60,
            'daysSinceJiaZi 必须在 [0, 59]，实际 $daysSinceJiaZi'),
        assert(xiuMenGong != HouTianGua.Center,
            '休门不应落中5（日家中5无门）');

  @override
  List<Object?> get props => [
        id,
        panDateTime,
        yinYangDun,
        dayJiaZi,
        daysSinceJiaZi,
        xiuMenGong,
        jieQiAt,
        fourZhuEightChar,
      ];

  String get juDescription =>
      '${yinYangDun.isYang ? "阳" : "阴"}遁日家·休门${xiuMenGong.name}${xiuMenGong.houTianOrder}宫';
}
