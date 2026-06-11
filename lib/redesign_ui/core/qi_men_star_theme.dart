import 'package:flutter/material.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'design_system.dart';

/// 奇门九星主题（颜色 / 图标）注册表
///
/// 作用：让时家「天蓬等九星」、日家「太乙等九星」、年家「紫白九星」
/// 各自登记自己的视觉表达，UI 渲染时统一通过 [QiMenStar] 接口查询。
///
/// 见 docs/more_qimen/extra_hour_plans.md §4.6.3。
abstract class QiMenStarTheme {
  /// 查询一颗星的显示色
  Color colorOf(QiMenStar star);

  /// 查询备用图标符号（保留扩展位）
  IconData? iconOf(QiMenStar star) => null;
}

/// 默认实现：使用既有时家配色（来自 [ColorSystem.traditionalColors]）
///
/// 日家 / 年家的星集在对应 Phase 落地时通过 [registerFamilyPalette]
/// 注入自己的颜色映射；未注册的星回退到主色。
class DefaultQiMenStarTheme implements QiMenStarTheme {
  /// 按 (Star runtimeType, star number) 索引的家级配色覆盖。
  /// 命中优先于按名字查 [ColorSystem.traditionalColors]。
  final Map<Type, Map<int, Color>> _familyPalettes = {};

  /// 注入一家的星集配色（建议 Phase 2/Phase 4 在 `service_locator` 启动时调用）
  void registerFamilyPalette<T extends QiMenStar>(Map<int, Color> palette) {
    _familyPalettes[T] = palette;
  }

  @override
  Color colorOf(QiMenStar star) {
    final familyMap = _familyPalettes[star.runtimeType];
    final familyHit = familyMap?[star.number];
    if (familyHit != null) return familyHit;
    // 回退：按名字查既有时家映射（兼容时家九星名）
    return ColorSystem.traditionalColors[star.name] ?? ColorSystem.textPrimary;
  }

  @override
  IconData? iconOf(QiMenStar star) => null;
}
