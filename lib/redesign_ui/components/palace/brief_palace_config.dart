import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// 宫位主题配置，用于统一管理视觉样式
class BriefPalaceTheme {
  // --- 格局相关 ---
  final double geJuHeight;
  final double geJuFontSize;
  final FontWeight geJuFontWeight;
  final EdgeInsets geJuTagPadding;
  final Color geJuTagBackgroundColor;
  final double geJuTagBorderRadius;

  // --- 状态图标相关 (驿马/空亡) ---
  final double statusIconWidth;
  final double horseIconSize;
  final double emptinessIconSize;
  final Color emptinessIconColor;

  // --- 标记相关 (击刑/遁甲) ---
  final double dunjiaMarkerSize;
  final double jiXingMarkerSize;
  final double markerOpacity;
  final double markerOffset;
  final Color jiXingColor;
  final Color dunjiaColor;
  final double markerThickness; // 层叠偏移厚度

  // --- 旺衰角标相关 ---
  final double wangShuaiFontSize;
  final double wangShuaiBadgeHeight;
  final double wangShuaiBadgeWidth;
  final double wangShuaiBadgeRadius;
  final Color wangShuaiGongBg;
  final Color wangShuaiMonthBg;
  final Color wangShuaiGongTextColor;
  final Color wangShuaiMonthTextColor;

  // --- 基础样式 ---
  final double palacePadding;
  final double primaryFontSize;
  final double secondaryFontSize;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final double columnWidthUnit;

  // --- 关系与神位角标相关 ---
  final double relationBadgeHeight;
  final double relationBadgeWidth;
  final double relationBadgeRadius;
  final double relationFontSize;
  final Color relationMenPoColor;
  final Color relationShouZhiColor;
  final Color relationGoodColor;
  final Color relationFuYinColor;
  final Color relationFanYinColor;
  final double wangShuaiGodSize;
  final double wangShuaiScale;

  const BriefPalaceTheme({
    this.geJuHeight = 34,
    this.geJuFontSize = 10,
    this.geJuFontWeight = FontWeight.w500,
    this.geJuTagPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.geJuTagBackgroundColor = const Color(0x1F607D8B), // Colors.blueGrey.withAlpha(30)
    this.geJuTagBorderRadius = 4,
    this.statusIconWidth = 20,
    this.horseIconSize = 18,
    this.emptinessIconSize = 14,
    this.emptinessIconColor = const Color(0xFFE53935),
    this.dunjiaMarkerSize = 20,
    this.jiXingMarkerSize = 12,
    this.markerOpacity = 0.8,
    this.markerOffset = -2,
    this.jiXingColor = const Color(0xFFF44336), // Colors.red
    this.dunjiaColor = const Color(0xFF4CAF50), // Colors.green
    this.markerThickness = 0.5,
    this.wangShuaiFontSize = 8,
    this.wangShuaiBadgeHeight = 11,
    this.wangShuaiBadgeWidth = 10,
    this.wangShuaiBadgeRadius = 6,
    this.wangShuaiGongBg = Colors.black54,
    this.wangShuaiMonthBg = const Color(0xFFE0E0E0), // Colors.grey[300]
    this.wangShuaiGongTextColor = Colors.white,
    this.wangShuaiMonthTextColor = Colors.black87,
    this.palacePadding = 8,
    this.primaryFontSize = 18,
    this.secondaryFontSize = 16,
    this.primaryTextColor = const Color(0xFF2C2C2C),
    this.secondaryTextColor = const Color(0xFF6B7280),
    this.columnWidthUnit = 24,
    this.relationBadgeHeight = 12,
    this.relationBadgeWidth = 10,
    this.relationBadgeRadius = 4,
    this.relationFontSize = 8,
    this.relationMenPoColor = const Color(0xFFD32F2F),
    this.relationShouZhiColor = const Color(0xFFBF360C),
    this.relationGoodColor = const Color(0xFF2E7D32),
    this.relationFuYinColor = const Color(0xFF455A64),
    this.relationFanYinColor = const Color(0xFF7B1FA2),
    this.wangShuaiGodSize = 12,
    this.wangShuaiScale = 0.8,
    this.wangShuaiMuGongColor = const Color(0xFFFF4D4D),
    this.wangShuaiMuMonthColor = const Color(0xFF8B0000),
    this.wangShuaiLuGongColor = Colors.greenAccent,
    this.wangShuaiLuMonthColor = const Color(0xFF388E3C),
    this.zhifuBadgeColor = const Color(0xFFD32F2F),
    this.xunshouBadgeColor = const Color(0xFF1976D2),
  });

  factory BriefPalaceTheme.fromComponent(ComponentStyle style) {
    final wangShuaiMonth = style.variant('wang_shuai_month');
    final wangShuaiGong = style.variant('wang_shuai_gong');
    final wangShuaiMuGong = wangShuaiGong.variant('mu');
    final wangShuaiMuMonth = wangShuaiMonth.variant('mu');
    final wangShuaiLuGong = wangShuaiGong.variant('lu');
    final wangShuaiLuMonth = wangShuaiMonth.variant('lu');
    final relation = style.variant('relation');
    final badge = style.variant('badge');
    return BriefPalaceTheme(
      geJuTagBackgroundColor: style.variant('geju_tag').background ?? const Color(0x1F607D8B),
      emptinessIconColor: style.variant('status_icon').background ?? const Color(0xFFE53935),
      jiXingColor: style.variant('marker').variant('ji_xing').background ?? const Color(0xFFF44336),
      dunjiaColor: style.variant('marker').variant('dunjia').background ?? const Color(0xFF4CAF50),
      wangShuaiMonthBg: wangShuaiMonth.background ?? const Color(0xFFE0E0E0),
      wangShuaiGongBg: wangShuaiGong.background ?? Colors.black54,
      wangShuaiGongTextColor: wangShuaiGong.variant('text').background ?? Colors.white,
      wangShuaiMonthTextColor: wangShuaiMonth.variant('text').background ?? Colors.black87,
      primaryTextColor: style.variant('text').variant('primary').background ?? const Color(0xFF2C2C2C),
      secondaryTextColor: style.variant('text').variant('secondary').background ?? const Color(0xFF6B7280),
      relationMenPoColor: relation.variant('men_po').background ?? const Color(0xFFD32F2F),
      relationShouZhiColor: relation.variant('shou_zhi').background ?? const Color(0xFFBF360C),
      relationGoodColor: relation.variant('good').background ?? const Color(0xFF2E7D32),
      relationFuYinColor: relation.variant('fu_yin').background ?? const Color(0xFF455A64),
      relationFanYinColor: relation.variant('fan_yin').background ?? const Color(0xFF7B1FA2),
      wangShuaiMuGongColor: wangShuaiMuGong.background ?? const Color(0xFFFF4D4D),
      wangShuaiMuMonthColor: wangShuaiMuMonth.background ?? const Color(0xFF8B0000),
      wangShuaiLuGongColor: wangShuaiLuGong.background ?? Colors.greenAccent,
      wangShuaiLuMonthColor: wangShuaiLuMonth.background ?? const Color(0xFF388E3C),
      zhifuBadgeColor: badge.variant('zhifu').background ?? const Color(0xFFD32F2F),
      xunshouBadgeColor: badge.variant('xunshou').background ?? const Color(0xFF1976D2),
    );
  }

  /// 旺衰 - 墓 — 宫底色（暗底上文字）
  final Color wangShuaiMuGongColor;
  /// 旺衰 - 墓 — 月底色（浅底上文字）
  final Color wangShuaiMuMonthColor;
  /// 旺衰 - 禄 — 宫底色
  final Color wangShuaiLuGongColor;
  /// 旺衰 - 禄 — 月底色
  final Color wangShuaiLuMonthColor;
  /// 值符角标底色
  final Color zhifuBadgeColor;
  /// 旬首角标底色
  final Color xunshouBadgeColor;
}

/// 宫位简介模式配置
class BriefPalaceConfig {
  /// 是否显示地八神（默认 false）
  final bool showDiGod;

  /// 是否显示隐干（默认 false）
  final bool showYinGan;

  /// 是否显示暗干（默认 false）
  final bool showAnGan;

  final bool showGeJu;

  final bool showWangShuai;

  final bool showSimpleLayout;

  /// 是否是飞盘（默认 false, 即转盘）
  final bool isFeipan;

  /// 是否显示天地盘干（默认 true）
  ///
  /// 日家不布三奇六仪，干字段全为占位（戊），UI 上隐藏更清爽。
  /// 设为 false 时，右侧天地盘干列折叠（rightColWidth = 0），
  /// 中间列（星 / 门 / 神）享有更多渲染空间。
  final bool showGan;

  /// 宫位主题
  final BriefPalaceTheme theme;

  const BriefPalaceConfig({
    this.showDiGod = false,
    this.showYinGan = false,
    this.showAnGan = false,
    this.showGeJu = false,
    this.showWangShuai = false,
    this.showSimpleLayout = false,
    this.isFeipan = false,
    this.showGan = true,
    this.theme = const BriefPalaceTheme(),
  });
}
