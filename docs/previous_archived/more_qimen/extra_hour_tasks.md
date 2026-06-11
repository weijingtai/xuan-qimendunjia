# 扩展非时家奇门（年/月/日家）— 任务清单

> 配套计划：`extra_hour_plans.md`。本文是该计划的**可执行任务分解**。
> 任务编号 `P{阶段}-T{序号}`。每个任务包含改动文件、产出、验收点。
> 创建时间：2026-04-30

---

## Phase 1 — 抽象骨架（家维度落地，不实现新家算法）

### P1-T1 新增 `QiMenJia` 枚举
- **新建**：`lib/enums/enum_qi_men_jia.dart`
- **内容**：`enum QiMenJia { NIAN("年家"), YUE("月家"), RI("日家"), SHI("时家") }`，含 `name` 字段、`fromName()` 工厂。
- **验收**：能在 IDE 内被任意文件 `import` 并使用。

### P1-T2 抽出 `BaseJu` 接口
- **新建**：`lib/domain/entities/base_ju.dart`
- **内容**：抽象类 `BaseJu`，仅暴露最小公共字段：
  ```dart
  abstract class BaseJu {
    String get id;
    DateTime get panDateTime;
    YinYang get yinYangDun;
    int get juNumber;
    String get fourZhuEightChar;
    QiMenJia get jia;
  }
  ```
- **修改**：`lib/domain/entities/shi_jia_ju.dart` —— `class ShiJiaJu extends Equatable implements Entity, BaseJu`，`jia => QiMenJia.SHI`。
- **验收**：`ShiJiaJu` 能赋给 `BaseJu` 引用；既有调用方仍按 `ShiJiaJu` 编译通过。

### P1-T2.5 抽出 `QiMenStar` 接口并 retrofit `NineStarsEnum`
> 由 D5（plans §7）驱动：日家与年家用各自独立的九星集，必须在 Phase 1 内做接口抽象，避免 Phase 2/4 受阻。
- **新建**：`lib/domain/entities/qi_men_star.dart`
  ```dart
  abstract class QiMenStar {
    String get name;
    String get singleCharName;
    int get number;
    FiveXing? get fiveXing;
    HouTianGua? get originalGong;
  }
  ```
- **修改**：`lib/enums/enum_nine_stars.dart:6` —— `enum NineStarsEnum implements QiMenStar`。已有字段（`name / singleCharName / number / fiveXing / originalGong`）已满足接口，无需改动数据。
- **修改**：以下 4 个入口的字段类型从 `NineStarsEnum` 改为 `QiMenStar`：
  - `lib/domain/entities/each_gong.dart:19` — `final QiMenStar star;`
  - `lib/domain/entities/qimen_pan.dart:38` — `final QiMenStar zhiFuStar;`
  - `lib/model/each_gong.dart:10` — `QiMenStar star;`
  - `lib/redesign_ui/layouts/smart_grid.dart:235,252` — `final QiMenStar starEnum; final QiMenStar? jiStarEnum;`
- **验收**：`flutter analyze` 通过；既有 27 处 `NineStarsEnum` 引用编译不破。

### P1-T2.6 `QiMenStarTheme` 注册表骨架
- **新建**：`lib/redesign_ui/core/qi_men_star_theme.dart`
- **内容**：根据星类型 + 序号查颜色 / 图标的注册表。先把 `lib/redesign_ui/core/design_system.dart:51,337` 的"九星色彩"映射搬过来，键改为 `(NineStarsEnum, int)`。
- **DI**：`service_locator.dart` 注册一个全局 `QiMenStarTheme` 实例。
- **验收**：UI 渲染时家盘的颜色与重构前一致；日家 / 年家在 Phase 2/4 各自补充 ColorMap 即可。

### P1-T3 升级 Repository 接口为双维
- **修改**：`lib/domain/repositories/qimen_calculator_repository.dart:19`
  - `calculateJu` 增加 `required QiMenJia jia` 参数。
  - 返回类型保持 `ShiJiaJu`（Phase 1 仅时家可用），但在文档注释中说明未来会变为 `BaseJu`。
- **新增异常**：在同文件添加 `class UnsupportedJiaArrangeException extends QiMenCalculationException`。
- **验收**：未传 `jia` 的调用点会被编译器全部标红，便于穷举改造点。

### P1-T4 升级 DataSource 与 Repository 实现
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
  - 新增抽象类 `JiaScopedCalculatorDataSource`（或在现有抽象上加 `QiMenJia get supportedJia`）。
  - 现有 4 个 `*CalculatorDataSource` 都返回 `QiMenJia.SHI`。
- **修改**：`lib/data/repositories/qimen_calculator_repository_impl.dart:14-38`
  - 把 `Map<ArrangeType, QiMenCalculatorDataSource>` 改为 `Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>`。
  - `calculateJu` 实现按 `(jia, arrangeType)` 二维查找，未命中抛 `UnsupportedJiaArrangeException`。
- **验收**：单测 `test_qi_men_ju_calculator.dart` 仍通过；新增测试覆盖"传 `QiMenJia.RI` 但仅注册了 SHI 时抛指定异常"。

### P1-T5 升级 UseCase
- **修改**：`lib/domain/usecases/calculate_ju_usecase.dart`
  - `CalculateJuParams` 增加 `final QiMenJia jia;`，构造默认值 `QiMenJia.SHI` 以保持 ViewModel 旧调用兼容。
  - `execute` 透传 `jia`。
- **验收**：MVVM 路径既有调用无需改动。

### P1-T6 升级 DI 注册
- **修改**：`lib/di/service_locator.dart:52-71`
  - `_registerDataSources` 中改为：
    ```dart
    _services[Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>] = {
      QiMenJia.SHI: {
        ArrangeType.CHAI_BU: ChaiBuCalculatorDataSource(),
        ArrangeType.ZHI_RUN: ZhiRunCalculatorDataSource(),
        ArrangeType.MAO_SHAN: MaoShanCalculatorDataSource(),
        ArrangeType.YIN_PAN: YinPanCalculatorDataSource(),
      },
    };
    ```
  - `_registerRepositories` 同步升级 generic key。
- **验收**：`serviceLocator.init()` 后 `serviceLocator.get<QiMenCalculatorRepository>()` 能正常工作。

### P1-T7 ViewModel 接入家维度
- **修改**：`lib/presentation/viewmodels/qimen_viewmodel.dart:127-167`
  - `calculateAndArrangePan` 增加 `QiMenJia jia = QiMenJia.SHI` 参数。
  - 透传给 `CalculateJuParams`。
- **验收**：现有页面调用未传 `jia` 仍编译通过，行为不变。

### P1-T8 Phase 1 回归测试
- **运行**：`flutter analyze && flutter test`
- **手工**：起一个固定时间（如 2026-04-30 14:00）的盘，与 Phase 1 之前的输出 diff，应字节级一致。
- **验收**：以上两条全过。

---

## Phase 2 — 日家奇门

### P2-T1 算法事实清单 ✅ 已落地
- **文件**：[`docs/more_qimen/ri_jia_algorithm.md`](./ri_jia_algorithm.md)（2026-04-30 由用户提供完整规范）
- **当前状态**：算法机制完备；待补 5 个手算样例（见该文档 §8 待补充清单）
- **验收**：在样例补全后，评审人可凭此文档复算样例。

### P2-T2 新增 `RiJiaJu` 实体
- **新建**：`lib/domain/entities/ri_jia_ju.dart`
- **内容**：`class RiJiaJu extends Equatable implements BaseJu`
  - 核心字段：`id, panDateTime, yinYangDun, juNumber(1-9), fourZhuEightChar, dayJiaZi, xiuMenAtGong, jieQiAt, daysSinceLastJiaZi`
  - **不复用** `ShiJiaJu` 的 `fuTouJiaZi / atThreeYuan / panJuJieQi / juDayNumber` 字段（日家无三元概念）
- **新建（可选）**：`lib/data/models/ri_jia_ju_model.dart`
- **验收**：可被 `BaseJu` 引用持有；类型断言 `ju is RiJiaJu` 工作正常。

### P2-T2.5 新增 `RiJiaStarEnum`
> 算法文档 §1 列出日家九星与时家完全不同。
- **新建**：`lib/enums/enum_ri_jia_stars.dart`
- **内容**：
  ```dart
  enum RiJiaStarEnum implements QiMenStar {
    TAI_YI(1, "太乙", "乙"),
    SHE_TI(2, "摄提", "摄"),
    XUAN_YUAN(3, "轩辕", "轩"),
    ZHAO_YAO(4, "招摇", "招"),
    TIAN_FU(5, "天符", "符"),
    QING_LONG(6, "青龙", "青"),
    XIAN_CHI(7, "咸池", "咸"),
    TAI_YIN(8, "太阴", "阴"),
    TIAN_YI(9, "天乙", "天乙");
    // 五行 / originalGong 暂返回 null（日家不依赖此语义）
  }
  ```
- **新建**：日家专属配色映射，注入到 `P1-T2.6` 的 `QiMenStarTheme`。
- **验收**：`RiJiaStarEnum.TAI_YI is QiMenStar` 为真；UI 渲染日家盘星名不显示乱码。

### P2-T3 新增 `RiJiaCalculator`
- **新建**：`lib/utils/ri_jia_qi_men_ju_calculator.dart`
- **内容**：实现 [`ri_jia_algorithm.md`](./ri_jia_algorithm.md) §3-§5：
  - 阴阳遁判定（按节气，与时家共用 `TwentyFourJieQi.yinYangDun`）
  - 3 日同宫休门表（两张静态 Map：`yangDunXiuMenMap` / `yinDunXiuMenMap`）
  - 日干阴阳决定八门顺逆方向
  - 距甲子日天数 `d` 顺飞日家九星
- **验收**：单测覆盖文档 §8 列出的所有手算样例。

### P2-T4 新增日家 DataSource
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
- **新增**：`RiJiaCalculatorDataSource implements JiaScopedCalculatorDataSource`
  - `supportedJia => QiMenJia.RI`
  - 日家不分拆补 / 置润，注册到 `ArrangeType.CHAI_BU` 占位。
- **验收**：可被 DI 注册。

### P2-T5 新增 `RiJiaPanArranger`（独立排盘器）
> 修订 D3：日家走 day-count 顺飞机制，**不**借用 `ShiJiaQiMen` 的旬首-值符模板。
- **新建**：`lib/model/ri_jia_qi_men.dart`
- **内容**：独立类 `RiJiaQiMen`，**不继承** `ShiJiaQiMen`：
  - 输入：`RiJiaJu ju, PanArrangeSettings settings`
  - 排盘三步：
    1. 按文档 §3 查表得休门落宫
    2. 按文档 §4 顺/逆布八门
    3. 按文档 §5 起太乙顺飞，分配 9 星到 9 宫（不含中 5 寄坤 2）
  - 输出 `Map<HouTianGua, EachGong>`，每个 `EachGong.star` 类型为 `QiMenStar`（实际是 `RiJiaStarEnum`）
  - **不实现**三奇六仪地盘（除非文档 §8 评审后明确需要）
  - 不存在"23 时换日"的边界
- **验收**：能产出 `QiMenPan` 实例；与文档样例的 8 门 + 9 星宫位分布一致。

### P2-T6 Repository 接入日家
- **修改**：`lib/data/repositories/qimen_calculator_repository_impl.dart:41-73`
  - `arrangePan` 按 `ju.jia` 派发：`SHI -> ShiJiaQiMen`，`RI -> RiJiaQiMen`。
- **修改**：`lib/di/service_locator.dart`
  - 注册 `QiMenJia.RI -> {ArrangeType.CHAI_BU: RiJiaCalculatorDataSource()}`。
- **验收**：传 `(QiMenJia.RI, CHAI_BU)` 起盘成功。

### P2-T7 日家测试
- **新建**：`test/test_ri_jia_qi_men.dart`
- **内容**：覆盖 `ri_jia_algorithm.md` §8 所有手算样例。
- **验收**：`flutter test` 全绿。

---

## Phase 3 — 月家奇门

### P3-T1 算法事实清单 ✅ 已落地
- **文件**：[`docs/more_qimen/yue_jia_algorithm.md`](./yue_jia_algorithm.md)
- **当前状态**：算法机制完备；待补 5 个手算样例（文档 §11）
- **关键事实**：复用 `NineStarsEnum`，**无需新增星集**；干 / 支双驱（值符随月干、值使随月支）；只用阴遁。

### P3-T2 新增 `YueJiaJu` 实体
- **新建**：`lib/domain/entities/yue_jia_ju.dart`
- **内容**：`class YueJiaJu extends Equatable implements BaseJu`
  - 核心字段：`id, panDateTime, yinYangDun(恒为 YIN), juNumber(1-9), fourZhuEightChar, monthJiaZi, yearZhiYuanType(上/中/下元)`
- **验收**：同 P2-T2。

### P3-T3 新增 `YueJiaCalculator`
- **新建**：`lib/utils/yue_jia_qi_men_ju_calculator.dart`
- **内容**：实现 [`yue_jia_algorithm.md`](./yue_jia_algorithm.md) §3-§4：
  - 五虎遁推月干（已有 `LunarAdapter.getMonthInGanZhi()` 可桥接，需写适配测试）
  - 年支孟仲季 → 三元 → 起局宫（坎 1 / 兑 7 / 巽 4）
  - 局数 = 起局宫号
- **验收**：单测覆盖文档 §11 样例。

### P3-T4 新增月家 DataSource
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
- **新增**：`YueJiaCalculatorDataSource implements JiaScopedCalculatorDataSource`，`supportedJia => QiMenJia.YUE`。

### P3-T5 新增 `GanZhiDrivenPanArranger`（月家 + 年家共用）
> 由 D3（修订）驱动：时 / 月 / 年三家旬首-值符机制同构，可共享一个排盘器；先在 Phase 3 实现，Phase 4 复用。
- **新建**：`lib/model/gan_zhi_driven_qi_men_pan.dart`
- **内容**：参数化排盘器，签名近似：
  ```dart
  class GanZhiDrivenQiMenPan {
    GanZhiDrivenQiMenPan({
      required BaseJu ju,
      required JiaZi drivingJiaZi,        // 月柱 / 年柱
      required QiMenStarSet starSet,      // NineStarsEnum.values 或 ZiBaiStarEnum.values
      required PanArrangeSettings settings,
    });
  }
  ```
  - 实现：地盘三奇六仪逆布 → 旬首得值符值使 → 天盘九星逆飞 → 人盘八门逆飞 → 神盘八神逆排
  - 月家用 `monthJiaZi` 注入，星集 = `NineStarsEnum`
- **验收**：月家样例输出与文档 §6-§9 一致。

### P3-T6 Repository / DI 接入月家
- **修改**：`qimen_calculator_repository_impl.dart` —— `arrangePan` 派发 `YUE -> GanZhiDrivenQiMenPan(drivingJiaZi: monthJiaZi, starSet: ...)`。
- **修改**：`service_locator.dart` —— 注册 `QiMenJia.YUE`。

### P3-T7 月家测试
- **新建**：`test/test_yue_jia_qi_men.dart`
- **验收**：`flutter test` 全绿。

---

## Phase 4 — 年家奇门

### P4-T1 算法事实清单 ✅ 已落地
- **文件**：[`docs/more_qimen/nian_jia_algorithm.md`](./nian_jia_algorithm.md)
- **关键事实**：紫白九星独立集；只用阴遁；起算锚点（推荐 1864 上元 / 1924 中元 / 1984 下元）需固化为常量。

### P4-T2 新增 `NianJiaJu` 实体
- **新建**：`lib/domain/entities/nian_jia_ju.dart`
- **核心字段**：`id, panDateTime, yinYangDun(恒为 YIN), juNumber(1/4/7), fourZhuEightChar, yearJiaZi, sanYuan(上/中/下)`。

### ~~P4-T2.5 新增 `ZiBaiStarEnum`~~（**已废弃 — 本期不做**）
按 [`qimen_jia_comparison.md`](./qimen_jia_comparison.md) §二，年家正统主流用**北斗九星**（与时家、月家相同），紫白九星仅风水派 / 玄空派分支。本期年家直接复用 `NineStarsEnum`，无需新建星集。详见 `nian_jia_tasks.md` P4-T2.5 废弃说明。

### P4-T3 新建年家锚点常量
- **新建**：`lib/utils/nian_jia_san_yuan_anchor.dart`
- **内容**：
  ```dart
  class NianJiaSanYuanAnchor {
    static const int upperYuanStartYear = 1864;
    static const int middleYuanStartYear = 1924;
    static const int lowerYuanStartYear = 1984;
    static (SanYuan, int) yearToYuanAndIndex(int year) { ... }
  }
  ```
- **验收**：单测验证 1984 → (下元, 1)、2026 → (下元, 43)。

### P4-T4 新增 `NianJiaCalculator`
- **新建**：`lib/utils/nian_jia_qi_men_ju_calculator.dart`
- **内容**：实现 [`nian_jia_algorithm.md`](./nian_jia_algorithm.md) §3：
  - 用 `NianJiaSanYuanAnchor` 定三元
  - 起局：上元阴遁 1 局、中元 4 局、下元 7 局
- **验收**：单测覆盖文档 §10 样例。

### P4-T5 新增年家 DataSource + 复用 `GanZhiDrivenQiMenPan`
- **新增**：`NianJiaCalculatorDataSource`，`supportedJia => QiMenJia.NIAN`
- **复用**：P3-T5 的 `GanZhiDrivenQiMenPan`，传入 `drivingGan/drivingZhi: yearGan/yearZhi, starSet: NineStarsEnum.values`（**北斗九星**，与月家相同）。
- **验收**：年家盘输出符合文档 §6-§8 算法。

### P4-T6 Repository / DI 接入年家
- 同 P2-T6 / P3-T6 模式。

### P4-T7 年家测试
- **新建**：`test/test_nian_jia_qi_men.dart`
- **验收**：`flutter test` 全绿。

---

## Phase 5 — UI 接入家选择器

### P5-T1 MVVM 页接入
- **修改**：`lib/presentation/pages/qimen_mvvm_page.dart`
  - 在已有 `ArrangeType` 选择器旁加 `QiMenJia` 选择器（按钮组或下拉）。
  - 切换时调用 `viewModel.calculateAndArrangePan(jia: ..., ...)`。
- **修改**：`lib/presentation/viewmodels/qimen_viewmodel.dart`
  - 暴露 `QiMenJia _currentJia` 状态字段，用于持久化用户选择。
- **验收**：手工切换 4 家，盘内容随之刷新；不支持的组合 UI 显示禁用。

### P5-T2 传统页保持时家
- **不改**：`lib/pages/scalable_shi_jia_qi_men_view_page.dart` / `lib/pages/beatiful_page.dart`。
- **验收**：传统页仍只能起时家盘，符合 `ARCHITECTURE.md` 中"双架构独立"约定。

### P5-T3 Brief 文案适配
- **修改**：`lib/domain/entities/qimen_pan.dart:152-155` 的 `brief` getter
  - 在描述前增加家前缀：`'${jia.name} ${shiJiaJu.juDescription} ...'`
  - `QiMenPan` 增加 `final QiMenJia jia` 字段，构造 / `copyWith` / `props` 同步更新。
- **修改**：`lib/data/models/mappers/qimen_pan_mapper.dart`，把 `jia` 透传。
- **验收**：AI 上下文 / UI 描述均能看到家信息。

---

## Phase 6（可选，本期不做）

- **P6-T1**：评估将 `ShiJiaJu` 重命名为 `QiMenJu`、`ShiJiaQiMen` 重命名为 `QiMenPanModel` 的影响范围（grep 应有 50+ 文件）
- **P6-T2**：评估将 `ShiJiaQiMen / RiJiaQiMen / YueJiaQiMen / NianJiaQiMen` 合并为单类 `QiMenPanArranger(drivingJiaZi: ...)` 的可行性
- **P6-T3**：AI Tool（`lib/ai/qimen_agent_tool.dart`）新增 `jia` 入参

---

## 总验收

- [ ] Phase 1-5 各阶段验收点全部通过
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter test` 全绿（含 4 家专项测试）
- [ ] 4 家各起 1 个固定时间样例盘，输出与算法事实清单一致
- [ ] 切换家与起局法在 UI 上稳定可用，不支持组合明确禁用而非崩溃

## 工作量估算

| 阶段 | 估算 | 说明 |
| --- | --- | --- |
| Phase 1 | **1.5-2 人日** | 含新增 P1-T2.5（QiMenStar 接口 + retrofit）+ P1-T2.6（StarTheme 注册表骨架） |
| Phase 2 | 2-3 人日 | 日家走独立 `RiJiaPanArranger`；含 `RiJiaStarEnum` 实现 + 配色 |
| Phase 3 | 2 人日 | 月家**复用** `NineStarsEnum` 与新建的 `GanZhiDrivenQiMenPan` |
| Phase 4 | 1-1.5 人日 | 年家**纯参数差异 + 锚点常量**；ZiBaiStarEnum 废弃后大幅缩减 |
| Phase 5 | 1 人日 | UI 接入家选择器 + brief 文案 |
| **合计** | **7.5-9.5 人日** | ZiBaiStarEnum 废弃 + 月年家完全同源，年家工作量再降 0.5-1 人日 |

> 关键路径：算法事实清单已落地（`ri_jia_algorithm.md` / `yue_jia_algorithm.md` / `nian_jia_algorithm.md`），仅剩各家 5 个手算样例待补。建议在 Phase 1 期间并行收集样例，不阻塞 Phase 2-4 启动。
