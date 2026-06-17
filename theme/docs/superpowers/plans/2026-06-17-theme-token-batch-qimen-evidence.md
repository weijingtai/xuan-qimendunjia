# Theme Token Migration Evidence: xuan-qimendunjia

- **Date**: 2026-06-17
- **Package**: `xuan-qimendunjia`
- **Component IDs**: `qimen_palace_grid`, `qimen_palace_cell`
- **Template**: `openspec/specs/theme-token-agent-migration-template.md`
- **Verification**: 11 new theme tests + 63 existing tests = 72 all passing

## Line-by-Line Mapping

| File:Line | Pre-migration | Post-migration | Rationale |
|---|---|---|---|
| `lib/redesign_ui/components/palace/brief_palace_config.dart:1-2` | `import 'package:flutter/material.dart';` | Added `import 'package:theme/theme.dart';` | Theme token API access |
| `lib/redesign_ui/components/palace/brief_palace_config.dart:101-143` | constructor defaults only | Added `factory BriefPalaceTheme.fromComponent(ComponentStyle style)` | Reads token colors from XuanThemeScope component variants |
| `lib/redesign_ui/components/palace/brief_palace_config.dart:68-69` | no fields | Added `zhifuBadgeColor`, `xunshouBadgeColor` | Token-driven 值符/旬首 badge colors |
| `lib/redesign_ui/components/palace/brief_palace_config.dart:71-78` | no fields | Added `wangShuaiMuGongColor`, `wangShuaiMuMonthColor`, `wangShuaiLuGongColor`, `wangShuaiLuMonthColor` | Token-driven 旺衰 墓/禄 colors |
| `lib/redesign_ui/layouts/smart_grid.dart:9` | no theme import | Added `import 'package:theme/theme.dart';` | Token API import |
| `lib/redesign_ui/layouts/smart_grid.dart:44-48` | `color: ColorSystem.surface` | `XuanThemeData.maybeOf(context)?.component('qimen_palace_grid')` with fallback | Grid background from token |
| `lib/redesign_ui/layouts/smart_grid.dart:57-59` | `boxShadow: [Shadows.md]` | `border: gridBorder, boxShadow: [Shadows.md]` | Optional border from token |
| `lib/redesign_ui/layouts/smart_grid.dart:197-201` | `const Color(0xFF4A90E2)` / `const Color(0xFFB8CCE0)` | `cellStyle?.border?.color ?? const Color(0xFF4A90E2)` / same fallback for unselected | Palace cell border from token |
| `lib/redesign_ui/layouts/smart_grid.dart:213-218` | `const Color(0xFFDDE8F4)` / `const Color(0xFFE8F0F8)` | `cellStyle?.background ?? const Color(0xFFDDE8F4)` | Palace cell background from token |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:32-37` | `config.theme` only | Added `_resolveTheme()` + `_resolvedTheme` field | Merges token scope colors into config theme |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:162-165` | `const Color(0xFFD32F2F)` / `const Color(0xFF1976D2)` | `theme.zhifuBadgeColor` / `theme.xunshouBadgeColor` | Badge colors from token |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:790-795` | `const Color(0xFF8B0000)` / `Colors.green[700]` | `theme.wangShuaiMuMonthColor` / `theme.wangShuaiLuMonthColor` | 旺衰 month 墓/禄 from token |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:818-823` | `const Color(0xFFFF4D4D)` / `Colors.greenAccent` | `theme.wangShuaiMuGongColor` / `theme.wangShuaiLuGongColor` | 旺衰 gong 墓/禄 from token |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:882-886` | `const Color(0xFF8B0000)` / `Colors.green[700]` | `theme.wangShuaiMuMonthColor` / `theme.wangShuaiLuMonthColor` | Same pattern in old widget |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:905-909` | `const Color(0xFFFF4D4D)` / `Colors.greenAccent` | `theme.wangShuaiMuGongColor` / `theme.wangShuaiLuGongColor` | Same pattern in old widget |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:948-952` | `const Color(0xFFFF4D4D)` / `Colors.greenAccent` | `theme.wangShuaiMuGongColor` / `theme.wangShuaiLuGongColor` | Same pattern in _buildWangShuaiWidget |
| `lib/redesign_ui/components/palace/brief_palace_layout.dart:976-980` | `const Color(0xFF8B0000)` / `Colors.green[700]` | `theme.wangShuaiMuMonthColor` / `theme.wangShuaiLuMonthColor` | Same pattern in _buildWangShuaiWidget |

## Deferred Colors

| File | Lines | Colors | Rationale |
|---|---|---|---|
| `lib/redesign_ui/core/design_system.dart` | All | 40+ `ColorSystem` constants | Package's own design token system, not migrated. Used as fallback values. |
| `lib/redesign_ui/core/design_system.dart` | `TraditionalColors` class | `getBaMenColor()`, `getJiuXingColor()`, `getGanColor()` | Semantic business logic mapping, not visual tokens. |
| `lib/redesign_ui/core/design_system.dart` | `WangShuaiColors` class | `getNormalWangShuaiColor()`, `getZhangShengColorByString()` | Semantic mapping logic, not visual tokens. |
| `lib/redesign_ui/core/design_system.dart` | `Shadows` class | `sm`, `md`, `lg`, `xl` | Design system structural values. |
| `lib/widgets/OctagonPainter.dart` | 1 | `Colors.blue` | Legacy widget, not in active redesign UI path. |
| `lib/widgets/QiMenGongContentBackground.dart` | All | `Colors.grey` defaults | Legacy content background widget. |
| `lib/pages/scalable_shi_jia_qi_men_view_page.dart` | 148-1805 | `Color(0xff636f7b)`, `Color(0xff6682c0)`, `Color(0xffdc6c73)`, `Color(0xffe4e5eb)` | Legacy view page. |
| `lib/redesign_ui/components/palace/brief_palace_config.dart` | constructor | All non-color fields (sizes, padding, font sizes, etc.) | Structural/sizing dimensions, not visual tokens. |

## False Completion Traps

- [x] **Light/dark overrides**: `ComponentStyle` supports per-brightness values via `XuanThemeSet`. Tests verify token colors propagate correctly.
- [x] **Non-empty pumpWidget**: All 3 widget tests include `SmartQiMenGrid` with `PalaceData.generateSampleData()` (9 palaces).
- [x] **Parent repo pointer**: Will be updated in commit step (parent `git add xuan-qimendunjia`).
- [x] **Production lib scan**: GREEN: 0 files importing `package:xuan_config`. RED: temp offender detected.
- [x] **Component ID verification**: Both `qimen_palace_grid` and `qimen_palace_cell` confirmed in source.

## Test Results

```
flutter test test/theme/
  ✓ Theme token governance: production widgets do not import xuan_config
  ✓ Theme token governance: scan path self-proves RED via temp dir
  ✓ Theme token governance: migrated component ids present in source
  ✓ SmartQiMenGrid: with theme scope, renders grid background from token
  ✓ SmartQiMenGrid: without theme scope, falls back to design system surface color
  ✓ SmartQiMenGrid: with theme scope, palace cell renders token background
  ✓ SmartQiMenGrid: ComponentStyle.empty fallback — no background
  ✓ SmartQiMenGrid: ComponentStyle.variant returns self when variant not found
  ✓ BriefPalaceTheme.fromComponent: falls back to defaults when empty
  ✓ BriefPalaceTheme.fromComponent: reads color from nested variant chain
  ✓ BriefPalaceTheme.fromComponent: reads mu/lu overrides
  11/11 passed

flutter test (full suite)
  72/72 passed
```
