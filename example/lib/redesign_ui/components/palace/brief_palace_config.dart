/// 宫位简介模式配置
class BriefPalaceConfig {
  /// 是否显示地八神（默认 false）
  final bool showDiGod;

  /// 是否显示隐干（默认 false）
  final bool showYinGan;

  /// 是否显示暗干（默认 false）
  final bool showAnGan;

  /// 是否显示格局（默认 false）
  final bool showGeJu;

  /// 是否显示旺衰信息（全局开关，默认 false）
  final bool showWangShuai;

  /// 是否显示宫位旺衰（星、门、神，默认 false）
  final bool showGongWangShuai;

  /// 是否显示月令旺衰（星、门，默认 false）
  final bool showYueLingWangShuai;

  /// 是否显示十二长生（天盘干、地盘干、隐干、暗干，默认 false）
  final bool showZhangSheng;

  /// 是否显示地神旺衰（默认 false）
  final bool showDiGodWangShuai;

  const BriefPalaceConfig({
    this.showDiGod = false,
    this.showYinGan = false,
    this.showAnGan = false,
    this.showGeJu = false,
    this.showWangShuai = false,
    this.showGongWangShuai = false,
    this.showYueLingWangShuai = false,
    this.showZhangSheng = false,
    this.showDiGodWangShuai = false,
  });

  BriefPalaceConfig copyWith({
    bool? showDiGod,
    bool? showYinGan,
    bool? showAnGan,
    bool? showGeJu,
    bool? showWangShuai,
    bool? showGongWangShuai,
    bool? showYueLingWangShuai,
    bool? showZhangSheng,
    bool? showDiGodWangShuai,
  }) {
    return BriefPalaceConfig(
      showDiGod: showDiGod ?? this.showDiGod,
      showYinGan: showYinGan ?? this.showYinGan,
      showAnGan: showAnGan ?? this.showAnGan,
      showGeJu: showGeJu ?? this.showGeJu,
      showWangShuai: showWangShuai ?? this.showWangShuai,
      showGongWangShuai: showGongWangShuai ?? this.showGongWangShuai,
      showYueLingWangShuai: showYueLingWangShuai ?? this.showYueLingWangShuai,
      showZhangSheng: showZhangSheng ?? this.showZhangSheng,
      showDiGodWangShuai: showDiGodWangShuai ?? this.showDiGodWangShuai,
    );
  }
}
