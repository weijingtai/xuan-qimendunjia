import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

import 'base_entity.dart';

/// 奇门局基类接口
///
/// 时家 / 日家 / 月家 / 年家共有的最小公共契约。
/// 各家专属字段在自身实现类内部定义；本接口仅暴露排盘上层
/// （Repository / UseCase / ViewModel）通用所需的字段。
///
/// 详见 docs/more_qimen/extra_hour_plans.md §4.4。
abstract class BaseJu implements Entity {
  /// 起盘时间
  DateTime get panDateTime;

  /// 阴阳遁
  YinYang get yinYangDun;

  /// 局数（1-9）
  int get juNumber;

  /// 四柱八字字符串（"年柱 月柱 日柱 时柱" 空格分隔）
  String get fourZhuEightChar;

  /// 所属家
  QiMenJia get jia;
}
