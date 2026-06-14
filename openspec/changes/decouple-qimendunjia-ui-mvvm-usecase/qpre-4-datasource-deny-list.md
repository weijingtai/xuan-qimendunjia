# QPRE-4: QiMenCalculatorDataSource Deny-List Documentation

## Date: 2026-06-13

## 1. Definition Location

**File:** `lib/data/datasources/calculator/qimen_calculator_data_source.dart`

`QiMenCalculatorDataSource` is an abstract class defining the calculator data source
interface. Concrete implementations:

| Class | Purpose |
|-------|---------|
| `ChaiBuCalculatorDataSource` | 拆补法 (时家) |
| `ZhiRunCalculatorDataSource` | 置润法 (时家) |
| `MaoShanCalculatorDataSource` | 茅山法 (时家) |
| `YinPanCalculatorDataSource` | 阴盘法 (时家) |
| `YueJiaCalculatorDataSource` | 月家奇门 |
| `NianJiaCalculatorDataSource` | 年家奇门 |
| `RiJiaCalculatorDataSource` | 日家奇门 |
| `KeJiaCalculatorDataSource` | 刻家奇门 |

## 2. Current Usage in Codebase

Referenced in exactly 2 files:

1. **`lib/di/service_locator.dart`** — DI wiring: creates and registers all DataSource
   instances in a `Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>`.

2. **`lib/data/repositories/qimen_calculator_repository_impl.dart`** — implementation:
   receives the Map and dispatches `calculate()` calls by (jia, arrangeType) key.

## 3. UI Layer References

**None found.** Direct search for `QiMenCalculatorDataSource` and
`qimen_calculator_data_source` in `lib/pages/` returned zero matches.

The UI layer accesses calculators indirectly through:
```
UI → QiMenViewModel → CalculateJuUseCase → QiMenCalculatorRepository
    → QiMenCalculatorRepositoryImpl → QiMenCalculatorDataSource
```

## 4. Why Add to Deny-List

Even though UI does not currently import QiMenCalculatorDataSource directly:

1. **Preventive measure**: As migration proceeds, developers might be tempted to
   shortcut through the DataSource for quick fixes.

2. **Consistency**: The deny-list already blocks `ChaiBuCalculator`, `ZhiRunCalculator`,
   etc. (the model-layer calculators). QiMenCalculatorDataSource wraps these same
   calculators — blocking the wrapper prevents indirect access.

3. **Architecture enforcement**: DataSource is a data-layer concern. UI should only
   interact through ViewModels and UseCases.

## 5. Recommended Deny-List Addition

Add to QPRE-3 boundary scan deny-list for all UI-layer paths:

```
qimen_calculator_data_source
QiMenCalculatorDataSource
ChaiBuCalculatorDataSource
ZhiRunCalculatorDataSource
MaoShanCalculatorDataSource
YinPanCalculatorDataSource
```

Note: The individual DataSource classes (ChaiBuCalculatorDataSource etc.) are
**different** from the legacy model calculators (ChaiBuCalculator etc.) already
in the deny-list. Both should be blocked from UI.
