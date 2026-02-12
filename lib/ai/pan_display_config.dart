/// 盘信息显示配置
///
/// 控制序列化到 AI 上下文时包含哪些可选字段。
/// 必选字段（天地盘干、星、门、神、驿马、四柱八字、局信息、伏吟反吟、值符值使）
/// 始终包含，不受此配置影响。
class PanDisplayConfig {
  /// 暗干（阴盘奇门中的暗干信息）
  final bool showAnGan;

  /// 隐干（特殊流派使用）
  final bool showYinGan;

  /// 格局列表（盘级别的常见格局）
  final bool showGeJuList;

  /// 地盘八神
  final bool showDiGod;

  /// 六甲旬首
  final bool showSixJiaXunHeader;

  /// 寄干（中五宫寄干）
  final bool showJiGan;

  const PanDisplayConfig({
    this.showAnGan = false,
    this.showYinGan = false,
    this.showGeJuList = true,
    this.showDiGod = false,
    this.showSixJiaXunHeader = false,
    this.showJiGan = false,
  });

  const PanDisplayConfig.defaultConfig()
      : showAnGan = false,
        showYinGan = false,
        showGeJuList = true,
        showDiGod = false,
        showSixJiaXunHeader = false,
        showJiGan = false;

  PanDisplayConfig copyWith({
    bool? showAnGan,
    bool? showYinGan,
    bool? showGeJuList,
    bool? showDiGod,
    bool? showSixJiaXunHeader,
    bool? showJiGan,
  }) {
    return PanDisplayConfig(
      showAnGan: showAnGan ?? this.showAnGan,
      showYinGan: showYinGan ?? this.showYinGan,
      showGeJuList: showGeJuList ?? this.showGeJuList,
      showDiGod: showDiGod ?? this.showDiGod,
      showSixJiaXunHeader: showSixJiaXunHeader ?? this.showSixJiaXunHeader,
      showJiGan: showJiGan ?? this.showJiGan,
    );
  }
}
