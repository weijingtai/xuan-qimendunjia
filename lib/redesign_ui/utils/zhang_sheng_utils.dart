import 'package:metaphysics_core/enums.dart';

class ZhangShengUtils {
  ZhangShengUtils._();

  static const Map<String, String> _shortNameMap = {
    '长生': '长',
    '沐浴': '沐',
    '冠带': '冠',
    '临官': '禄',
    '帝旺': '帝',
    '衰': '衰',
    '病': '病',
    '死': '死',
    '墓': '墓',
    '绝': '绝',
    '胎': '胎',
    '养': '养',
  };

  static String toShortName(TwelveZhangSheng zhangSheng) {
    return _shortNameMap[zhangSheng.name] ?? zhangSheng.name;
  }

  static String toShortNameByString(String zhangShengName) {
    return _shortNameMap[zhangShengName] ?? zhangShengName;
  }

  static bool isStrongZhangSheng(TwelveZhangSheng zhangSheng) {
    return zhangSheng.isStrong;
  }

  static bool isStrongZhangShengByString(String zhangShengName) {
    final zhangSheng = TwelveZhangSheng.values.firstWhere(
      (e) => e.name == zhangShengName,
      orElse: () => TwelveZhangSheng.ZHANG_SHEN,
    );
    return zhangSheng.isStrong;
  }
}
