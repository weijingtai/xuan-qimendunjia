import 'package:common/enums.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';

import 'base_entity.dart';
import 'base_ju.dart';

/// 刻家局实体
///
/// 刻家奇门是在时家奇门基础上发展起来的。当前支持两种刻制方案
/// （由 [keScheme] 字段标记，UI 可切换）：
/// - 十刻五子建元：一时辰 10 刻、每刻 12 分钟
/// - 八刻五马遁：一时辰 8 刻、每刻 15 分钟
///
/// 刻家奇门起局规则：
/// - **初局**沿用本时辰的时家奇门起局
/// - **刻干阳干**（甲丙戊庚壬）→ 八门顺行；二局起甲子戊宫位顺移
/// - **刻干阴干**（乙丁己辛癸）→ 八门逆行；二局起甲子戊宫位逆移
/// - 阳遁示例：初局甲子戊在坎一，二局坤二，三局震三，四局巽四 …
/// - 阴遁示例：初局坎一，二局离九，三局艮八，四局兑七 …
///
/// 排盘机制：
/// - 与时家结构相同（转盘 + 三奇六仪 + 北斗九星 + 八神 + 旬首-值符）
/// - 用**刻干支**替代时干支：旬首随刻干、值使随刻支
/// - **刻家阴阳遁** = 刻干阴阳（决定三奇六仪 / 八门 / 八神顺逆 + 局推移方向）
/// - 节气信息保留（用于 ShiJiaQiMen 内部副功能）
class KeJiaJu extends Equatable implements Entity, BaseJu {
  @override
  final String id;

  @override
  final DateTime panDateTime;

  @override
  QiMenJia get jia => QiMenJia.KE;

  /// 刻家阴阳遁 = 刻干阴阳（甲丙戊庚壬→YANG / 乙丁己辛癸→YIN）
  ///
  /// 用户 spec：八门顺/逆由刻干决定；二局起阳顺阴逆。
  /// 实现上等同于把刻干阴阳作为整盘的 yinYangDun 注入 ShiJiaQiMen。
  @override
  final YinYang yinYangDun;

  /// 推移后的局数（1-9）
  ///
  /// 由初局（本时辰时家局）+ 刻局序号（1..[totalKeCount]）+ 刻干阴阳推得：
  ///   阳：juNumber = ((initJu - 1 + (keIndex - 1)) % 9) + 1
  ///   阴：juNumber = ((initJu - 1 - (keIndex - 1)) mod 9) + 1
  @override
  final int juNumber;

  /// 四柱八字 = 年柱 月柱 日柱 **刻柱**（注意第四柱替换为刻干支，便于复用 ShiJiaQiMen）
  @override
  final String fourZhuEightChar;

  // ==================== 刻家专属字段 ====================

  /// 刻干支（核心驱动量）
  final JiaZi keJiaZi;

  /// 刻局序号 1..keScheme.totalKeCount（一时辰内的第几刻）
  final int keIndex;

  /// 刻制方案（10刻五子建元 / 8刻五马遁）
  ///
  /// 决定一时辰刻数与每刻分钟数；不影响阴阳遁与局推移规则。
  final KeSchemeType keScheme;

  /// 时辰干支（保留以便展示与调试）
  final JiaZi shiJiaZi;

  /// 本时辰的时家初局（推移基准）
  final int initJuNumber;

  /// 时辰起始时间（用于校验 keIndex）
  final DateTime shiChenStartAt;

  // ==================== 节气与三元（保留以构造伪 ShiJiaJu） ====================

  /// 时家符头甲子
  final JiaZi fuTouJiaZi;

  /// 当前节气
  final TwentyFourJieQi jieQiAt;

  /// 当前节气开始时间
  final DateTime jieQiStartAt;

  /// 下一节气
  final TwentyFourJieQi jieQiEnd;

  /// 下一节气开始时间
  final DateTime jieQiEndAt;

  /// 三元
  final EnumThreeYuan atThreeYuan;

  KeJiaJu({
    required this.id,
    required this.panDateTime,
    required this.yinYangDun,
    required this.juNumber,
    required this.fourZhuEightChar,
    required this.keJiaZi,
    required this.keIndex,
    this.keScheme = KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
    required this.shiJiaZi,
    required this.initJuNumber,
    required this.shiChenStartAt,
    required this.fuTouJiaZi,
    required this.jieQiAt,
    required this.jieQiStartAt,
    required this.jieQiEnd,
    required this.jieQiEndAt,
    required this.atThreeYuan,
  })  : assert(keIndex >= 1 && keIndex <= keScheme.totalKeCount,
            'keIndex 必须在 [1, ${keScheme.totalKeCount}]，实际 $keIndex'),
        assert(juNumber >= 1 && juNumber <= 9,
            'juNumber 必须在 [1, 9]，实际 $juNumber'),
        assert(initJuNumber >= 1 && initJuNumber <= 9,
            'initJuNumber 必须在 [1, 9]，实际 $initJuNumber');

  @override
  List<Object?> get props => [
        id,
        panDateTime,
        yinYangDun,
        juNumber,
        fourZhuEightChar,
        keJiaZi,
        keIndex,
        keScheme,
        shiJiaZi,
        initJuNumber,
        shiChenStartAt,
        fuTouJiaZi,
        jieQiAt,
        jieQiStartAt,
        jieQiEnd,
        jieQiEndAt,
        atThreeYuan,
      ];

  /// 一时辰总刻数（来自当前刻制方案）
  int get totalKeCount => keScheme.totalKeCount;

  /// 是否阳遁（按刻干阴阳）
  bool get isYangDun => yinYangDun.isYang;

  /// 是否阴遁（按刻干阴阳）
  bool get isYinDun => yinYangDun.isYin;

  /// 局描述
  String get juDescription =>
      '${yinYangDun.name}遁刻家·${keJiaZi.name}·第$keIndex刻·$juNumber局';
}
