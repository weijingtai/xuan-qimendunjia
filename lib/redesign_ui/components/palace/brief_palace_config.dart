/// 宫位简介模式配置
class BriefPalaceConfig {
  /// 是否显示地八神（默认 false）
  final bool showDiGod;

  /// 是否显示隐干（默认 false）
  final bool showYinGan;

  /// 是否显示暗干（默认 false）
  final bool showAnGan;

  final bool showGeJu;

  const BriefPalaceConfig({
    this.showDiGod = false,
    this.showYinGan = false,
    this.showAnGan = false,
    this.showGeJu = false,
  });
}
