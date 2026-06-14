# Q0 Baseline Manifest — QiMenDunJia UI-MVVM Decoupling

**Branch:** feature/decouple-ui-mvvm-qpre
**Commit:** b768baf feat(qimendunjia): QPRE-1~4 pre-migration for UI-MVVM decoupling
**Date:** 2026-06-13
**Project root:** /Users/jingtaiwei/Git/Public/xuan-migration/xuan-qimendunjia

---

## Q0.2 Route List

### Registered Routes (from lib/navigator.dart)

| Route | Target | Notes |
|-------|--------|-------|
| `/qimendunjia` | `ScalableShiJiaQiMenViewPage()` via `ChangeNotifierProvider<ShiJiaQiMenViewModel>` | Legacy (traditional architecture) |
| `/qimendunjia/mvvm` | `QiMenMvvmPage()` via `serviceLocator.createQiMenViewModel()` | New MVVM + UseCase architecture |
| `/qimendunjia/multi_jia` | `MultiJiaQiMenPage()` via `serviceLocator.createQiMenViewModel()` | Multi-jia (shi/yue/nian) |
| `/redesign_ui/smart_grid_demo` | `SmartGridDemo()` | UI redesign demo |
| `/qimendunjia/primary` (in `generateRoute1`) | `PrimaryPage()` | Legacy slide-transition route |

### Legacy UI Scope (lib/pages/)

| File | Lines | Size (bytes) | Description |
|------|-------|-------------|-------------|
| `beatiful_page.dart` | 3,958 | 176,749 | Original "beautiful" page (legacy) |
| `scalable_beatiful_page.dart` | 3,977 | 177,779 | Scalable version of beautiful page |
| `scalable_shi_jia_qi_men_view_page.dart` | 3,708 | 158,598 | Scalable shi-jia view page |
| `shi_jia_qi_men_view_page.dart` | 3,520 | 151,614 | Original shi-jia view page |
| `shi_jia_qi_men_view_model.dart` | 592 | — | Legacy ViewModel (ChangeNotifier) |
| `primary_page.dart` | — | — | Legacy primary page |
| `primary_page.bak.dart` | — | — | Backup of primary page |

### New MVVM Scope (lib/presentation/)

| File | Description |
|------|-------------|
| `presentation/pages/qimen_mvvm_page.dart` | New MVVM page |
| `presentation/pages/multi_jia_qimen_page.dart` | Multi-jia page |
| `presentation/viewmodels/qimen_viewmodel.dart` | New ViewModel |

### Legacy Widgets (lib/widgets/)

| File | Description |
|------|-------------|
| `each_gong_widget.dart` | Gong widget (imports `shi_jia_qi_men.dart`) |
| `gong_widget.dart` | Gong widget (imports `shi_jia_qi_men.dart`, uses `officialRuleReader`) |
| `new_each_gong_widget.dart` | New gong widget (imports `shi_jia_qi_men.dart`) |
| `resizable_gong_widget.dart` | Resizable gong widget |
| `qi_yi_wang_shuai.dart` | Qi Yi Wang Shuai widget |
| `ten_gan_ke_ying_yin_zhang.dart` | Ten Gan Ke Ying Yin Zhang |
| `ten_gan_ke_ying_ge_ju_detail.dart` | Ge Ju detail widget |
| `QiMenGongContentBackground.dart` | Gong content background |

### Redesign UI (lib/redesign_ui/)

| File | Description |
|------|-------------|
| `core/design_system.dart` | Design system tokens |
| `core/qi_men_star_theme.dart` | Star theme |
| `layouts/smart_grid.dart` | Smart grid layout |
| `components/palace/brief_palace_layout.dart` | Brief palace layout |
| `components/palace/brief_palace_config.dart` | Brief palace config |
| `demo/smart_grid_demo.dart` | Smart grid demo page |

### Clean Architecture Layers (from QPRE-1~4)

| Layer | Directory | Files |
|-------|-----------|-------|
| Domain Entities | `lib/domain/entities/` | 10 files (base_entity, base_ju, each_gong, ke_jia_ju, nian_jia_ju, qi_men_star, qimen_pan, ri_jia_day_analysis, ri_jia_ju, san_yuan_type, shi_jia_ju, yue_jia_ju) |
| Domain Repositories | `lib/domain/repositories/` | 2 files (qimen_calculator_repository, qimen_data_repository) |
| Domain UseCases | `lib/domain/usecases/` | 4 files (base_usecase, arrange_pan_usecase, calculate_ju_usecase, select_gong_usecase) |
| Data Sources | `lib/data/datasources/` | 3 files + 1 subfolder |
| Data Mappers | `lib/data/models/mappers/` | 3 files (each_gong_mapper, qimen_pan_mapper, shi_jia_ju_mapper) |
| Data Repositories | `lib/data/repositories/` | 2 files (qimen_calculator_repository_impl, qimen_data_repository_impl) |
| DI | `lib/di/` | service_locator.dart |

---

## Q0.3 Analyzer Results

**Command:** `dart analyze lib`

```
Total issues: 895
  - errors:   0
  - warnings: 178
  - info:     717 (715 counted by grep, 717 by analyzer -- minor grep artifact)
```

### Warning Categories (sample):
- `deprecated_member_use` — `withOpacity` deprecation in widgets
- `override_on_non_overriding_member` — ai/qimen_ai_action.dart
- `unreachable_switch_default` — various enum files
- `unused_import` — multiple files
- `unused_local_variable` — multiple files
- `must_be_immutable` — beatiful_page.dart, primary_page.bak.dart
- `dead_code` — beatiful_page.dart
- `unused_element` — ten_gan_ke_ying.g.dart (generated)

---

## Q0.4 Test Results

**Command:** `flutter test`

```
Result: 48 passed, 1 failed (compilation error in boundary test)
```

### Failing Test:
- `test/architecture/import_boundary_test.dart` — **Compilation error**: `package:test/test.dart` not resolved
  - Root cause: boundary test uses `package:test` directly, but dev_dependencies only has `flutter_test`. The test should use `flutter_test` instead of `test`.
  - This is NOT a logic failure — the test structure is correct but the import is wrong.

### Passing Test Files:
- check_day_test.dart
- read_data_utils_fake_test.dart
- qimendunjia_test.dart (many sub-tests for 置润法, 阴盘, 茅山法, etc.)
- repro_shen_ke_bug_test.dart
- Architecture boundary test: FAILED TO COMPILE (import issue)

---

## Q0.5 Boundary Scans

### Scan 1: UI Deny-List
**Targets:** `lib/pages/`, `lib/widgets/`, `lib/presentation/pages/`, `lib/redesign_ui/`
**Patterns:** ChaiBuCalculator, ZhiRunCalculator, MaoShanCalculator, YinPanCalculator, QiMenCalculatorRepository, QimendunjiaOfficialRuleRepository, repository_interface_qimendunjia, serviceLocator, ReadDataUtils, officialRuleReader, model/shi_jia_qi_men.dart, model/shi_jia_ju.dart, ShiJiaQiMen(, qimen_calculator_data_source, QiMenCalculatorDataSource, *CalculatorDataSource

**Result: 73 matches in 8 files**

```
lib/pages/beatiful_page.dart:33:import '../model/shi_jia_ju.dart';
lib/pages/beatiful_page.dart:37:import '../model/shi_jia_qi_men.dart';
lib/pages/beatiful_page.dart:1049://     ReadDataUtils.readDoorStarKeYing(),   (commented out)
lib/pages/beatiful_page.dart:1050://     ReadDataUtils.readDoorGanKeYing(),   (commented out)
lib/pages/beatiful_page.dart:1051://     ReadDataUtils.readTenGanKeYing(),    (commented out)
lib/pages/beatiful_page.dart:1052://     ReadDataUtils.readEightDoorKeYing()  (commented out)
lib/pages/beatiful_page.dart:1063:await serviceLocator.officialRuleReader.readTenGanKeYingGeJu();
lib/pages/beatiful_page.dart:1152:await serviceLocator.officialRuleReader.readDoorStarKeYing();
lib/pages/beatiful_page.dart:1159:await serviceLocator.officialRuleReader.readDoorGanKeYing();
lib/pages/beatiful_page.dart:1166:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/beatiful_page.dart:1179:loadResult = await serviceLocator.officialRuleReader.readEightDoorKeYing();
lib/pages/beatiful_page.dart:1192:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/beatiful_page.dart:1201:await serviceLocator.officialRuleReader.readQiYiRuGongDisease();
lib/pages/beatiful_page.dart:3829:shiJiaJu = ChaiBuCalculator(dateTime: panDatetime).calculate();
lib/pages/beatiful_page.dart:3832:shiJiaJu = ZhiRunCalculator(dateTime: panDatetime).calculate();
lib/pages/beatiful_page.dart:3835:shiJiaJu = MaoShanCalculator(dateTime: panDatetime).calculate();
lib/pages/beatiful_page.dart:3838:shiJiaJu = YinPanCalculator(dateTime: panDatetime).calculate();
lib/pages/beatiful_page.dart:3841:JiaZi fuTou = ChaiBuCalculator.getFuTouByDayJiaZi(dayJiaZi!);
lib/pages/beatiful_page.dart:3864:var shiJiaQiMen = ShiJiaQiMen(
lib/pages/scalable_beatiful_page.dart:33:import '../model/shi_jia_ju.dart';
lib/pages/scalable_beatiful_page.dart:37:import '../model/shi_jia_qi_men.dart';
lib/pages/scalable_beatiful_page.dart:1050://     ReadDataUtils.readDoorStarKeYing(),  (commented)
lib/pages/scalable_beatiful_page.dart:1051://     ReadDataUtils.readDoorGanKeYing(),   (commented)
lib/pages/scalable_beatiful_page.dart:1052://     ReadDataUtils.readTenGanKeYing(),    (commented)
lib/pages/scalable_beatiful_page.dart:1053://     ReadDataUtils.readEightDoorKeYing()  (commented)
lib/pages/scalable_beatiful_page.dart:1064:await serviceLocator.officialRuleReader.readTenGanKeYingGeJu();
lib/pages/scalable_beatiful_page.dart:1153:await serviceLocator.officialRuleReader.readDoorStarKeYing();
lib/pages/scalable_beatiful_page.dart:1160:await serviceLocator.officialRuleReader.readDoorGanKeYing();
lib/pages/scalable_beatiful_page.dart:1167:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/scalable_beatiful_page.dart:1180:loadResult = await serviceLocator.officialRuleReader.readEightDoorKeYing();
lib/pages/scalable_beatiful_page.dart:1193:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/scalable_beatiful_page.dart:1202:await serviceLocator.officialRuleReader.readQiYiRuGongDisease();
lib/pages/scalable_beatiful_page.dart:3831:shiJiaJu = ChaiBuCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_beatiful_page.dart:3834:shiJiaJu = ZhiRunCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_beatiful_page.dart:3837:shiJiaJu = MaoShanCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_beatiful_page.dart:3840:shiJiaJu = YinPanCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_beatiful_page.dart:3843:JiaZi fuTou = ChaiBuCalculator.getFuTouByDayJiaZi(dayJiaZi!);
lib/pages/scalable_beatiful_page.dart:3866:var shiJiaQiMen = ShiJiaQiMen(
lib/pages/scalable_shi_jia_qi_men_view_page.dart:44:import '../model/shi_jia_ju.dart';
lib/pages/scalable_shi_jia_qi_men_view_page.dart:48:import '../model/shi_jia_qi_men.dart';
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3593:shiJiaJu = ChaiBuCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3596:shiJiaJu = ZhiRunCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3599:shiJiaJu = MaoShanCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3602:shiJiaJu = YinPanCalculator(dateTime: panDatetime).calculate();
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3605:JiaZi fuTou = ChaiBuCalculator.getFuTouByDayJiaZi(dayJiaZi!);
lib/pages/scalable_shi_jia_qi_men_view_page.dart:3633:Provider.of<ShiJiaQiMenViewModel>(context, listen: false).createShiJiaQiMen(
lib/pages/shi_jia_qi_men_view_model.dart:23:import '../model/shi_jia_ju.dart';
lib/pages/shi_jia_qi_men_view_model.dart:24:import '../model/shi_jia_qi_men.dart';
lib/pages/shi_jia_qi_men_view_model.dart:117:createShiJiaQiMen(
lib/pages/shi_jia_qi_men_view_model.dart:260:void createShiJiaQiMen(PlateType plateType, DateTime dateTime,
lib/pages/shi_jia_qi_men_view_model.dart:264:var shiJiaQiMen = ShiJiaQiMen(
lib/pages/shi_jia_qi_men_view_model.dart:324:await serviceLocator.officialRuleReader.readDoorStarKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:331:await serviceLocator.officialRuleReader.readDoorGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:348:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:396:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:409:loadResult = await serviceLocator.officialRuleReader.readEightDoorKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:422:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/shi_jia_qi_men_view_model.dart:431:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/shi_jia_qi_men_view_model.dart:450:await serviceLocator.officialRuleReader.readQiYiRuGongDisease();
lib/pages/shi_jia_qi_men_view_model.dart:459:await serviceLocator.officialRuleReader.readTenGanKeYingGeJu();
lib/pages/shi_jia_qi_men_view_page.dart:44:import '../model/shi_jia_ju.dart';
lib/pages/shi_jia_qi_men_view_page.dart:48:import '../model/shi_jia_qi_men.dart';
lib/pages/shi_jia_qi_men_view_page.dart:3415:shiJiaJu = ChaiBuCalculator(dateTime: panDatetime).calculate();
lib/pages/shi_jia_qi_men_view_page.dart:3418:shiJiaJu = ZhiRunCalculator(dateTime: panDatetime).calculate();
lib/pages/shi_jia_qi_men_view_page.dart:3421:shiJiaJu = MaoShanCalculator(dateTime: panDatetime).calculate();
lib/pages/shi_jia_qi_men_view_page.dart:3424:shiJiaJu = YinPanCalculator(dateTime: panDatetime).calculate();
lib/pages/shi_jia_qi_men_view_page.dart:3427:JiaZi fuTou = ChaiBuCalculator.getFuTouByDayJiaZi(dayJiaZi!);
lib/pages/shi_jia_qi_men_view_page.dart:3455:Provider.of<ShiJiaQiMenViewModel>(context, listen: false).createShiJiaQiMen(
lib/widgets/each_gong_widget.dart:22:import '../model/shi_jia_qi_men.dart';
lib/widgets/gong_widget.dart:19:import '../model/shi_jia_qi_men.dart';
lib/widgets/gong_widget.dart:713:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/widgets/gong_widget.dart:719:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/widgets/new_each_gong_widget.dart:24:import '../model/shi_jia_qi_men.dart';
```

**Summary:** All violations are in legacy pages (beatiful_page, scalable_beatiful_page, scalable_shi_jia_qi_men_view_page, shi_jia_qi_men_view_page, shi_jia_qi_men_view_model) and legacy widgets (gong_widget, each_gong_widget, new_each_gong_widget). The new presentation/ and redesign_ui/ layers are CLEAN.

---

### Scan 2: ViewModel/Facade Deny-List
**Targets:** `lib/presentation/viewmodels/`, `lib/pages/shi_jia_qi_men_view_model.dart`
**Patterns:** ChaiBuCalculator, ZhiRunCalculator, MaoShanCalculator, YinPanCalculator, ReadDataUtils, officialRuleReader, rootBundle, QimendunjiaOfficialRuleRepository, QiMenCalculatorRepositoryImpl, ShiJiaQiMen(, DataSource patterns

**Result: 12 matches in 1 file**

All 12 matches are in the LEGACY `lib/pages/shi_jia_qi_men_view_model.dart` (not in the new `lib/presentation/viewmodels/`):

```
lib/pages/shi_jia_qi_men_view_model.dart:117:createShiJiaQiMen(
lib/pages/shi_jia_qi_men_view_model.dart:260:void createShiJiaQiMen(PlateType plateType, DateTime dateTime,
lib/pages/shi_jia_qi_men_view_model.dart:264:var shiJiaQiMen = ShiJiaQiMen(
lib/pages/shi_jia_qi_men_view_model.dart:324:await serviceLocator.officialRuleReader.readDoorStarKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:331:await serviceLocator.officialRuleReader.readDoorGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:348:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:396:await serviceLocator.officialRuleReader.readTenGanKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:409:loadResult = await serviceLocator.officialRuleReader.readEightDoorKeYing();
lib/pages/shi_jia_qi_men_view_model.dart:422:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/shi_jia_qi_men_view_model.dart:431:await serviceLocator.officialRuleReader.readQiYiRuGong();
lib/pages/shi_jia_qi_men_view_model.dart:450:await serviceLocator.officialRuleReader.readQiYiRuGongDisease();
lib/pages/shi_jia_qi_men_view_model.dart:459:await serviceLocator.officialRuleReader.readTenGanKeYingGeJu();
```

**New `lib/presentation/viewmodels/qimen_viewmodel.dart` is CLEAN — zero violations.**

---

### Scan 3: UseCase Deny-List
**Target:** `lib/domain/usecases/`
**Patterns:** imports from lib/pages, lib/widgets, lib/presentation, lib/redesign_ui

**Result: 0 matches** — UseCase layer is CLEAN.

---

### Scan 4: Repository Reverse Dependency
**Targets:** `lib/data/`, `lib/domain/repositories/`
**Patterns:** imports from lib/pages, lib/widgets, lib/presentation, lib/redesign_ui, lib/utils, lib/model, lib/ui_models

**Result: 0 matches** — Data and Repository layers are CLEAN.

---

## Q0.6 Baseline Allow-List (Existing Violations)

The following violations are acknowledged as EXISTING BASELINE and will be progressively resolved:

### UI Layer Violations (73 matches in 8 files):
- `lib/pages/beatiful_page.dart` — 18 violations (imports + calculator/serviceLocator/officialRuleReader usage)
- `lib/pages/scalable_beatiful_page.dart` — 18 violations (same pattern as beatiful_page)
- `lib/pages/scalable_shi_jia_qi_men_view_page.dart` — 8 violations
- `lib/pages/shi_jia_qi_men_view_page.dart` — 8 violations
- `lib/pages/shi_jia_qi_men_view_model.dart` — 12 violations (treated as legacy ViewModel)
- `lib/widgets/each_gong_widget.dart` — 1 violation (import shi_jia_qi_men.dart)
- `lib/widgets/gong_widget.dart` — 3 violations (import + officialRuleReader)
- `lib/widgets/new_each_gong_widget.dart` — 1 violation (import shi_jia_qi_men.dart)

### New Layers — ZERO Violations:
- `lib/presentation/pages/` — CLEAN
- `lib/presentation/viewmodels/` — CLEAN
- `lib/domain/usecases/` — CLEAN
- `lib/domain/entities/` — CLEAN
- `lib/domain/repositories/` — CLEAN
- `lib/data/` — CLEAN
- `lib/redesign_ui/` — CLEAN
- `lib/di/` — (not scanned; infra layer)

---

## Q0.7 Golden Fixture Inventory

**File:** `test/golden/fixtures/qimendunjia_decoupling_cases.json`

8 fixtures covering 4 arrange types x 2 plate types:
- CHAI_BU x ZHUAN_PAN, FEI_PAN
- ZHI_RUN x ZHUAN_PAN, FEI_PAN
- MAO_SHAN x ZHUAN_PAN, FEI_PAN
- YIN_PAN x ZHUAN_PAN, FEI_PAN

**Expected file:** `test/golden/expected/qimendunjia_decoupling_expected.json` (stub)

---

## Q0.8 Negative Dependency Test Verification

**File:** `test/architecture/import_boundary_test.dart`
**Status:** EXISTS but COMPILE ERROR — uses `package:test/test.dart` instead of `package:flutter_test/flutter_test.dart`

The boundary test structure is correct (4 test cases covering lib/pages, lib/widgets, lib/presentation/pages, lib/presentation/viewmodels). The only issue is the import.

---

## Q0.10 Golden Baseline Freeze

### Freeze Declaration

The golden baseline is hereby FROZEN as of 2026-06-13 on branch `feature/decouple-ui-mvvm-qpre`.

**Freeze scope:**
- **Field-level equivalence** — golden fixtures assert structured field values (ju number, plate type, gong contents, star/door/shen assignments), NOT screenshots or pixel-level rendering.
- **8 fixture cases** in `test/golden/fixtures/qimendunjia_decoupling_cases.json` define the minimum regression surface.
- **Expected values** are stubbed in `test/golden/expected/qimendunjia_decoupling_expected.json` and must be populated before any Round 1 changes.

**What is frozen:**
1. All existing test assertions (48 passing tests)
2. Analyzer baseline (895 issues: 0 errors, 178 warnings, 717 info)
3. Boundary scan allow-list (73 UI-layer violations in 8 files)
4. Golden fixture input parameters (datetime, arrangeType, plateType)

**What is NOT frozen (may change per round):**
- Expected values in `qimendunjia_decoupling_expected.json` (to be populated)
- Boundary test import fix (test → flutter_test)
- Any files outside `lib/` production code

**Baseline commit hash:** b768baf
