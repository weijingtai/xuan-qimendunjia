import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

import 'base_entity.dart';
import 'base_ju.dart';
import 'san_yuan_type.dart';

/// 月家局实体
///
/// 月家奇门**恒为阴遁**，干支双驱（值符随月干 / 值使随月支）。
/// 三元由年支孟仲季决定，与起局宫一一对应：
///   寅申巳亥（孟）→ 上元 → 坎 1
///   子午卯酉（仲）→ 中元 → 兑 7
///   辰戌丑未（季）→ 下元 → 巽 4
///
/// 详见 docs/more_qimen/yue_jia_algorithm.md。
class YueJiaJu extends Equatable implements Entity, BaseJu {
  @override
  final String id;

  @override
  final DateTime panDateTime;

  @override
  QiMenJia get jia => QiMenJia.YUE;

  @override
  YinYang get yinYangDun => YinYang.YIN; // 月家恒为阴遁

  @override
  final String fourZhuEightChar;

  /// 年柱（用于决定三元）
  final JiaZi yearJiaZi;

  /// 月柱（驱动柱：月干→值符，月支→值使）
  final JiaZi monthJiaZi;

  /// 当年所在三元（按年支孟仲季）
  final SanYuanType sanYuan;

  /// 起局宫（坎1/兑7/巽4 之一）
  final HouTianGua qiJuGong;

  /// 局数 = 起局宫号
  @override
  int get juNumber => qiJuGong.houTianOrder;

  /// 月支（值使来源）
  DiZhi get monthZhi => monthJiaZi.diZhi;

  /// 月干（值符来源）
  TianGan get monthGan => monthJiaZi.gan;

  YueJiaJu({
    required this.id,
    required this.panDateTime,
    required this.yearJiaZi,
    required this.monthJiaZi,
    required this.sanYuan,
    required this.qiJuGong,
    required this.fourZhuEightChar,
  });

  @override
  List<Object?> get props => [
        id,
        panDateTime,
        yearJiaZi,
        monthJiaZi,
        sanYuan,
        qiJuGong,
        fourZhuEightChar,
      ];

  String get juDescription =>
      '阴遁月家·${qiJuGong.name}${qiJuGong.houTianOrder}局（${sanYuan.name}）';
}
