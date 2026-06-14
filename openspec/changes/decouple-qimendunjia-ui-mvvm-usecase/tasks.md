# QPRE/Q Tasks — decouple-qimendunjia-ui-mvvm-usecase

## QPRE-1: Clean Architecture Skeleton ✅
- [x] Domain entities (base_entity, base_ju, each_gong, etc.)
- [x] Domain repositories interfaces
- [x] Domain usecases (base_usecase, arrange_pan, calculate_ju, select_gong)

## QPRE-2: Calculator & Repository Assessment ✅
- [x] Assessment document: `qpre-2-calculator-repo-assessment.md`

## QPRE-3: Boundary Test Harness ✅
- [x] Import boundary test: `test/architecture/import_boundary_test.dart`
- NOTE: test has compilation error (uses `package:test` instead of `flutter_test`) — fix deferred to Q0 or later

## QPRE-4: DataSource Deny-List ✅
- [x] Deny-list document: `qpre-4-datasource-deny-list.md`

---

## Q0: Baseline & Golden Equivalence Freeze ✅

- [x] Q0.1 Create baseline-manifest.md
- [x] Q0.2 Record route list (4 routes + legacy UI scope identified)
- [x] Q0.3 Run and record analyzer (895 issues: 0 errors, 178 warnings, 717 info)
- [x] Q0.4 Run and record tests (48 passed, 1 failed — boundary test compile error)
- [x] Q0.5 Run boundary scans (4 scans completed)
  - Scan 1 (UI deny-list): 73 matches in 8 files — ALL in legacy layer
  - Scan 2 (ViewModel deny-list): 12 matches in 1 file — legacy ViewModel only
  - Scan 3 (UseCase deny-list): 0 matches — CLEAN
  - Scan 4 (Repository reverse dep): 0 matches — CLEAN
- [x] Q0.6 Record existing violations as baseline allow-list (in baseline-manifest.md)
- [x] Q0.7 Create golden fixture inventory (8 fixtures: 4 arrange x 2 plate)
- [x] Q0.8 Verify negative dependency tests (exists, has compile error noted)
- [x] Q0.9 Update tasks.md (this file)
- [x] Q0.10 Freeze golden baseline with field-level note (in baseline-manifest.md)

---

## Q1: Introduce Legacy Facade Without Business Calculation ✅

- [x] Q1.1 Create legacy-compatible facade (`lib/presentation/viewmodels/qimen_legacy_facade.dart`)
  - Accepts old UI intent calls (calculateAndArrangePan, selectGong)
  - Delegates to CalculateJuUseCase, ArrangePanUseCase, SelectGongUseCase
  - Exposes legacy-shaped state (QiMenPan, EachGong, GongDetailInfo)
  - No direct calculator imports, no ShiJiaQiMen construction, no officialRuleReader
- [x] Q1.2 Verify facade has no direct calculator imports (0 matches)
- [x] Q1.3 Create facade tests (`test/presentation/qimen_legacy_facade_test.dart`)
  - Compiles without calculator imports
  - Initial state verification
- [x] Q1.4 Update tasks.md (this file)
- [x] Q1.5 Commit

---

## Q4: Unify QiMen UI State And Intent Contract ✅

- [x] Q4.1 Define QiMenInputState (`lib/presentation/models/qimen_input_state.dart`)
  - Fields: dateTime, arrangeType, plateType, family (QiMenJia)
  - Derived: validationErrors (Map<String,String>), isReadyToSubmit (bool)
  - Methods: copyWith, empty constructor, defaults factory
  - Note: uses `QiMenJia` (domain enum) rather than a separate `QiMenFamily` alias
- [x] Q4.2 Define QiMenDisplayState (`lib/presentation/models/qimen_display_state.dart`)
  - Ju metadata: panDateTime, jia, yinYangDun, juNumber, jieQi, fourZhuEightChar, plateType
  - ZhiFu/ZhiShi: zhiShiDoor, zhiFuStar, zhiFuGan, zhiFuStarAtGong, zhiShiDoorAtGong
  - XunKong: xunHeaderTianGan, timeXunKong, dayXunKong, monthXunKong, yearXunKong
  - Horse: horseLocation
  - LiuJia: sixJiaXunHeader, isSixJiXing, monthToken, dayJiaZi, timeJiaZi
  - Fu/FanYin: isStarFuYin, isStarFanYin, isDoorFuYin, isDoorFanYin, isGanFuYin, isGanFanYin
  - Palaces: gongMapper (Map<HouTianGua, EachGong>), panGeJuList
  - Selection: selectedGongGua, gongDetailInfo (GongDetailInfo)
  - Derived: hasAnyFuYin, hasAnyFanYin, getGong(), brief
  - Methods: copyWith
  - Mirrors all fields from LegacyQiMenDisplayState + QiMenPan + EachGong + GongDetailInfo
- [x] Q4.3 Define QiMenUiState (`lib/presentation/models/qimen_ui_state.dart`)
  - Sealed class with 4 subtypes: empty, loading, success(QiMenDisplayState), error(String)
  - Pattern-matching: when() helper for pages not using Dart 3 switch expressions
  - Convenience: isEmpty, isLoading, isSuccess, isError
- [x] Q4.4 Bind routes — route/state mapping documented:
  - `/qimendunjia` (legacy) → ScalableShiJiaQiMenViewPage + ShiJiaQiMenViewModel
    - State: uses internal _state enum + nullable fields; will migrate to QiMenUiState in Q5
    - Input: local page state (_selectedDateTime, _plateTypeNotifer); will migrate to QiMenInputState
  - `/qimendunjia/mvvm` (MVVM) → QiMenMvvmPage + QiMenViewModel
    - State: QiMenViewState enum; will migrate to QiMenUiState
    - Input: local page state (_selectedDateTime, _arrangeType, _plateType); will migrate to QiMenInputState
  - `/qimendunjia/multi_jia` (multi-jia) → MultiJiaQiMenPage + QiMenViewModel
    - State: same QiMenViewModel; will migrate to QiMenUiState
    - Input: local page state (_jia, _arrangeType, _plateType, _selectedDateTime); will migrate to QiMenInputState
  - `/redesign_ui/smart_grid_demo` → SmartGridDemo (standalone demo, no state contract needed)
  - Actual binding of QiMenUiState/QiMenInputState to pages deferred to Q5 (page modification phase)
- [x] Q4.5 Update tasks.md (this file)
- [x] Q4.6 Commit
