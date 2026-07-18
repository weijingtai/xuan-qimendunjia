// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get qimendunjia => '奇门遁甲';

  @override
  String get xianTian => '先天';

  @override
  String get houTian => '后天';

  @override
  String get jiaZi => '甲子';

  @override
  String get aiContextSettings => 'AI 上下文设置';

  @override
  String get showHint => '显示提示';

  @override
  String get repositoryInterfaceDesc => '• Repository接口: 定义数据操作契约';

  @override
  String get repositoryImplDesc => '• Repository实现: 实现数据操作';
}
