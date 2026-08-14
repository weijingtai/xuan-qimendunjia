import 'package:provider/single_child_widget.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

import '../../di/service_locator.dart';

/// 奇门遁甲模块清单。
///
/// 供宿主 [xuan-shell] 模块图装配使用，暴露模块元信息与 provider 装配入口。
/// provider 装配复用既有 [ServiceLocator.init]（命令式副作用），
/// 与梅花/大六壬的声明式 `buildAllProviders` 不同——奇门既有架构即
/// 全局 [serviceLocator] 单例，本清单不另写一套装配逻辑。
final class QimendunjiaModuleManifest {
  const QimendunjiaModuleManifest._();

  static const String id = 'qimendunjia';
  static const String displayNameKey = 'module_qimendunjia_name';
  static const String version = '0.1.0';
  static const String minShellVersion = '0.1.0-a3';

  /// 装配奇门模块依赖。
  ///
  /// [officialRules] 由 host 装配层注入的官方规则资源仓储（assets 后端实现）。
  /// [recordRepository] 由 host 注入的占卜记录仓储。
  /// [timezoneProvider] 宿主解析的当前时区（用户偏好 > 地点 > 中国默认）。
  /// 实际装配在 [ServiceLocator.init] 内以副作用完成，此处返回空 provider 列表
  /// （奇门页面内部通过 [serviceLocator.get] 取依赖，不依赖 widget 树注入）。
  static List<SingleChildWidget> createProviders(
    QimendunjiaOfficialRuleRepository officialRules,
    QimenRecordRepository recordRepository, {
    String Function()? timezoneProvider,
  }) {
    serviceLocator.init(
      officialRules,
      recordRepository,
      timezoneProvider: timezoneProvider,
    );
    return const <SingleChildWidget>[];
  }
}
