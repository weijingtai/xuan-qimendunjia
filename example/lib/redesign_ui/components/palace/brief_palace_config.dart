/// 宫位简介模式配置
class BriefPalaceConfig {
  /// 是否显示地八神（默认 false）
  final bool showDiGod;

  /// 是否显示隐干/暗干（默认 false）
  final bool showYinAnGan;

  const BriefPalaceConfig({
    this.showDiGod = false,
    this.showYinAnGan = false,
  });
}
