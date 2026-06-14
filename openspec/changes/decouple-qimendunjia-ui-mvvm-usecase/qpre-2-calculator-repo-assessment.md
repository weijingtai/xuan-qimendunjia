# QPRE-2: QiMenCalculatorRepository Refactor Assessment

## Date: 2026-06-13

## 1. Current API Surface

### QiMenCalculatorRepository (abstract interface)
**File:** `lib/domain/repositories/qimen_calculator_repository.dart`

```dart
abstract class QiMenCalculatorRepository {
  Future<BaseJu> calculateJu({
    required DateTime dateTime,
    required QiMenJia jia,
    required ArrangeType arrangeType,
    KeSchemeType? keScheme,
    FuTouSchemeType? fuTouScheme,
  });

  Future<QiMenPan> arrangePan({
    required BaseJu ju,
    required PlateType plateType,
    required PanSettings settings,
  });
}
```

Also co-located in the same file:
- `PanSettings` (value class) — used by ViewModel, UseCases, and implementation
- `QiMenCalculationException` / `UnsupportedJiaArrangeException`

### QiMenDataRepository (abstract interface)
**File:** `lib/domain/repositories/qimen_data_repository.dart`

```dart
abstract class QiMenDataRepository {
  Future<TenGanKeYing> getTenGanKeYing({...});
  Future<DoorStarKeYing?> getDoorStarKeYing({...});
  Future<Map<YinYang, EightDoorKeYing>?> getEightDoorKeYing({...});
  Future<QiYiRuGong?> getQiYiRuGong({...});
  Future<TenGanKeYingGeJu> getTenGanKeYingGeJu({...});
  Future<String?> getEightDoorGanKeYing({...});
  Future<String?> getTianGanRuGongDisease({...});
  Future<void> clearCache();
}
```

## 2. What Leaks

### 2.1 Unused legacy import in abstract interface
`qimen_calculator_repository.dart` line 7 imports `model/shi_jia_qi_men.dart` — **not used** in the abstract class, PanSettings, or exception types. This is a stale import.

### 2.2 Implementation uses legacy fat models
`QiMenCalculatorRepositoryImpl` (data layer) is deeply coupled:
- Imports `model/shi_jia_qi_men.dart` (as `model.ShiJiaQiMen`)
- Imports `model/gan_zhi_driven_qi_men_pan.dart`
- Imports `model/ke_jia_qi_men_pan.dart`
- Imports `model/ri_jia_qi_men.dart`
- Imports `model/shen_ke_qi_men_pan.dart`
- Imports `model/pan_arrange_settings.dart`

This is **expected** — the impl bridges domain entities ↔ legacy models.

### 2.3 Domain entity types used (CLEAN)
The abstract interface uses only domain-layer types:
- `BaseJu`, `ShiJiaJu` (domain entities)
- `QiMenPan` (domain entity)
- Enums from `enums/` (shared)
- `PanSettings` (co-located value class)

### 2.4 QiMenViewModel dependency
`QiMenViewModel` imports `qimen_calculator_repository.dart` **solely** for the `PanSettings` class (line 18). It does NOT call the repository directly — it goes through UseCases.

## 3. UseCase Dependencies

| UseCase | Repository Used | Purpose |
|---------|----------------|---------|
| `CalculateJuUseCase` | `QiMenCalculatorRepository` | Calculate ju number |
| `ArrangePanUseCase` | `QiMenCalculatorRepository` | Arrange pan from ju |
| `SelectGongUseCase` | `QiMenDataRepository` | Load gong detail data |

## 4. Recommended Approach

### Can QiMenCalculatorRepository be deprecated?
**No.** It serves a distinct purpose from QiMenDataRepository:
- `QiMenCalculatorRepository` = calculation (ju + pan arrangement)
- `QiMenDataRepository` = static data lookup (ke ying, ge ju, etc.)

They are complementary, not overlapping.

### Recommended refactoring steps:

1. **Extract PanSettings** to its own file `lib/domain/entities/pan_settings.dart`
   - Removes ViewModel's need to import the repository file
   - Small effort, high clarity gain

2. **Remove stale import** of `model/shi_jia_qi_men.dart` from the abstract interface
   - Trivial fix

3. **Keep QiMenCalculatorRepositoryImpl** as-is in data layer
   - Its coupling to legacy models is the whole point — it's the adapter
   - The boundary test (QPRE-3) will ensure UI doesn't reach through to it

4. **Long-term**: Once all legacy calculators are reimplemented in domain layer,
   QiMenCalculatorRepositoryImpl can be simplified. Not urgent.

## 5. Estimated Migration Effort

| Task | Effort | Priority |
|------|--------|----------|
| Extract PanSettings to own file | 0.5 day | P0 (blocks clean ViewModel) |
| Remove stale import | 5 min | P0 |
| Add boundary tests | 1 day | P0 (QPRE-3) |
| Refactor QiMenCalculatorRepositoryImpl | 3-5 days | P2 (post-migration) |

## 6. Verdict

QiMenCalculatorRepository is architecturally sound. The abstract interface is clean
(uses domain primitives). The implementation couples to legacy models by design.
The main action item is extracting PanSettings and removing the stale import.
No need to deprecate or merge with QiMenDataRepository.
