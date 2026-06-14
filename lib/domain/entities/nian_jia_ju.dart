import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

import 'base_entity.dart';
import 'base_ju.dart';
import 'san_yuan_type.dart';

/// 年家局实体
///
/// 年家奇门**恒为阴遁**，与月家完全同源：星 / 门 / 神 / 排盘规则一致，
/// 仅驱动柱（年柱 vs 月柱）与起局机制不同。
///
/// 详见 docs/more_qimen/nian_jia_algorithm.md。
class NianJiaJu extends Equatable implements Entity, BaseJu {
  @override
  final String id;

  @override
  final DateTime panDateTime;

  @override
  QiMenJia get jia => QiMenJia.NIAN;

  @override
  YinYang get yinYangDun => YinYang.YIN; // 年家恒为阴遁

  @override
  final String fourZhuEightChar;

  /// 年柱（驱动柱：年干→值符，年支→值使）
  final JiaZi yearJiaZi;

  /// 三元
  final SanYuanType sanYuan;

  /// 元内年序（1-60）
  final int yearIndexInYuan;

  /// 起局宫（坎1 / 巽4 / 兑7 之一）
  final HouTianGua qiJuGong;

  /// 局数 = 起局宫号
  @override
  int get juNumber => qiJuGong.houTianOrder;

  /// 年支（值使来源）
  DiZhi get yearZhi => yearJiaZi.diZhi;

  /// 年干（值符来源）
  TianGan get yearGan => yearJiaZi.gan;

  NianJiaJu({
    required this.id,
    required this.panDateTime,
    required this.yearJiaZi,
    required this.sanYuan,
    required this.yearIndexInYuan,
    required this.qiJuGong,
    required this.fourZhuEightChar,
  });

  @override
  List<Object?> get props => [
        id,
        panDateTime,
        yearJiaZi,
        sanYuan,
        yearIndexInYuan,
        qiJuGong,
        fourZhuEightChar,
      ];

  String get juDescription =>
      '阴遁年家·${qiJuGong.name}${qiJuGong.houTianOrder}局（${sanYuan.name}第$yearIndexInYuan年）';
}
