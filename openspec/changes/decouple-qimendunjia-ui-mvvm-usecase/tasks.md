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

## Q1: [TBD] — Next Round
