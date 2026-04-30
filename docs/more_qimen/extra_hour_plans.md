# 扩展非时家奇门（年/月/日家）的实施计划

> 文件作用：本文是**策略计划文档**。配套的执行清单在 `extra_hour_tasks.md`。
> 范围：在保留时家奇门现有功能不退化的前提下，让代码可以承载「年家」「月家」「日家」三类奇门遁甲的起局与排盘。
> 创建时间：2026-04-30

## 1. 背景与现状

当前代码库**完全围绕「时家奇门」一种维度**展开，命名层、抽象层均无层级（家）这个轴。

### 1.1 时家假设硬编码点

| 位置 | 现状 |
| --- | --- |
| `lib/enums/enum_arrange_plate_type.dart:9` | `ArrangeType { CHAI_BU, ZHI_RUN, MAO_SHAN, YIN_PAN, MANUALLY }` 是**时家内部**的起局法，不是时/日/月/年这条轴 |
| `lib/utils/qi_men_ju_calculator.dart:14` | `abstract class ShiJiaQiMenJuCalculator`，注释「时家奇门，局计算」 |
| `lib/utils/qi_men_ju_calculator.dart:124-178` | 拆补法以 `dayJiaZi → fuTou → threeYuan + 节气` 推局，并对 `dateTime.hour == 23` 做子时换日 — 时家专属 |
| `lib/model/shi_jia_qi_men.dart:90-94` | 旬首与值符干硬绑 `timeJiaZi`：`sixJiaXunHeader = SixJia.getSixJiaByJiaZi(timeJiaZi.xunHeader); zhiFuGan = timeJiaZi.gan;` |
| `lib/model/shi_jia_ju.dart`、`lib/domain/entities/shi_jia_ju.dart` | 数据模型整体以「时家局」命名 |
| `lib/domain/repositories/qimen_calculator_repository.dart:19` | `calculateJu` 入参只有 `dateTime + ArrangeType`，缺「家」维度 |
| `lib/di/service_locator.dart:52-56` | DI 注册仅按 `ArrangeType → CalculatorDataSource` 单维 Map |

### 1.2 已具备的扩展基础

- `ShiJiaQiMen` 构造里 28-35 行已经把 **年/月/日/时** 四柱 JiaZi 都解析出来了，只是排盘逻辑只用 `timeJiaZi`。
- MVVM 分层（domain / data / presentation）清晰，有 Repository、UseCase、ViewModel 三层封装；新增层级抽象不破坏分层结构。
- 已存在 `ArrangeType` 这种"策略 + DI Map"模式，可以复用同一思路再加一维。

## 2. 目标

1. **正交化两个轴**
   - 「家」轴：`QiMenJia { NIAN, YUE, RI, SHI }`（时/日/月/年）
   - 「起局法」轴：保持现有 `ArrangeType`（拆补/置润/茅山/阴盘/手动）
   - 二者交叉决定一种具体的算法实现。
2. **时家既有行为零回归**：所有 `ShiJia*` 既有 API 保留为时家专用入口；不强制重命名（避免大面积 PR）。
3. **新家以增量方式落地**：先打通"日家"作为第二条家，验证抽象正确，再补"月家""年家"。
4. **UI 至少能切换"家"维度**：在已有起局法 UI 旁加一个家级选择，不动主布局。

## 3. 非目标

- 不重写现有时家算法，不替换 `ShiJiaQiMen` 的内部实现。
- 不引入运行时类型擦除（不强求统一的 `BaseJu`/`BaseQiMenPan` 替换 `ShiJiaJu`/`QiMenPan`）；保持类型安全比表面统一更重要。
- 不在本期实现"暗盘""手盘"等更复杂派系。
- 不修改既有 AI Tool（`lib/ai/qimen_agent_tool.dart`）的对外 schema；可选作为后续增量。

## 4. 设计方案

### 4.1 引入 `QiMenJia` 枚举

新文件 `lib/enums/enum_qi_men_jia.dart`：

```dart
enum QiMenJia {
  NIAN("年家"),
  YUE("月家"),
  RI("日家"),
  SHI("时家");
  final String name;
  const QiMenJia(this.name);
}
```

### 4.2 计算器层：双维 Map

**关键决定**：让 `QiMenCalculatorRepository` 的入参从单维 `ArrangeType` 升级为 `(QiMenJia, ArrangeType)` 复合键。

`lib/domain/repositories/qimen_calculator_repository.dart` 新签名（草案）：

```dart
Future<BaseJu> calculateJu({
  required DateTime dateTime,
  required QiMenJia jia,                         // 新增
  required ArrangeType arrangeType,
});
```

DI 由 `Map<ArrangeType, X>` 升级为 `Map<QiMenJia, Map<ArrangeType, X>>`，未实现的组合在 Repository 层抛 `UnsupportedJiaArrangeException`。

**关键决定**：保留 `ShiJiaJu` 类型不动，但抽出**最小公共接口** `BaseJu`（含 `id / panDateTime / yinYangDun / juNumber / fourZhuEightChar`）。`NianJiaJu / YueJiaJu / RiJiaJu` 各自实现，不强行复用 `ShiJiaJu` 字段（年家无节气三元，复用反而是污染）。

### 4.3 排盘层：起符 / 起使的双驱动机制

> 本节在 2026-04-30 重写：原版本以"单一驱动柱"概括四家，但根据 `ri_jia_algorithm.md` / `yue_jia_algorithm.md` / `nian_jia_algorithm.md` 的算法规范，**月家与年家是干 / 支双驱**，**日家是 day-count 驱动**（与 jiazi-driven 完全异构）。原"单一 drivingJiaZi"过弱。

| 家 | 值符（起符）来源 | 值使来源 | 备注 |
| --- | --- | --- | --- |
| 时家 | `timeJiaZi.gan` 走旬首 | `timeJiaZi.diZhi` | 现有实现，gan/zhi 已隐式分离 |
| 日家 | **距甲子日天数 d** 顺飞太乙 | 由日柱阴阳 + 3 日同宫表得休门宫，再顺/逆布八门 | 不走"旬首-值符"机制，与时家结构不同 |
| 月家 | `monthJiaZi.gan` 走旬首 | `monthJiaZi.diZhi` 决定值使逆数距 | 干 / 支双驱 |
| 年家 | `yearJiaZi.gan` 走旬首 | `yearJiaZi.diZhi` 决定值使逆数距 | 干 / 支双驱 |

**关键决定（修订）**：

1. **不试图把日家塞进时家的"旬首-值符"模板**。日家用 `RiJiaPanArranger` 独立实现，因为算法机制（day-count 顺飞）与其它三家本质不同。
2. **时 / 月 / 年三家可共享一套抽象**：`GanZhiDrivenPanArranger`，参数化为 `(符干, 使支)` 二元组。`ShiJiaQiMen` 暂不动，新建 `MonthYearJiaPanArranger` 共服月家与年家；时家在 Phase 6 再考虑迁移。
3. 共享层最大公约数 = `布地盘三奇六仪 + 由旬首落宫得值符值使 + 天盘九星飞布 + 人盘八门飞布 + 神盘八神逆排`。九星集合（`QiMenStar`）作为参数注入（见 §4.6）。

### 4.4 实体层：保守策略

- `QiMenPan` 暂不动 — 它的字段（值符星 / 值使门 / 伏吟反吟 / 格局列表）在四家通用。
- 新增 `QiMenPan.jia: QiMenJia` 字段（默认 SHI 兼容旧数据）。
- `shiJiaJu` 字段在中长期建议改为 `BaseJu ju`，但本期保持 `shiJiaJu` 名字不变，新家走"包装一个最小 ShiJiaJu 兼容子集"的过渡方案，**避免 mapper / serializer / AI tool 全链路同步爆炸**。这一权衡在 §6 风险点列出。

### 4.5 UI 与状态管理

- `QiMenViewModel.calculateAndArrangePan` 增加 `QiMenJia jia` 参数（可选，默认 SHI）。
- 现有 `lib/pages/scalable_shi_jia_qi_men_view_page.dart` 与 `lib/presentation/pages/qimen_mvvm_page.dart` 在已有"起局法"选择器旁加"家"选择器。
- 不动 `redesign_ui/components/palace/`：宫位组件层级与"家"无关。

### 4.6 星体多态设计（QiMenStar 接口）

> 由用户算法规范确认：日家用**日家九星**（太乙/摄提/轩辕/招摇/天符/青龙/咸池/太阴/天乙），年家用**紫白九星**（一白/二黑/.../九紫），均与时家 `NineStarsEnum`（蓬/任/冲/辅/英/芮/柱/心/禽）名称、五行属性、原宫语义都不同。月家**复用**时家九星。

#### 4.6.1 必须做接口抽象

`lib/enums/enum_nine_stars.dart:6-34` 的 `NineStarsEnum` 当前被 27 个文件直接引用（domain 实体、UI 主题、AI serializer 全链路）。日 / 年家无法借壳复用 `NineStarsEnum`，必须引入接口：

```dart
// lib/domain/entities/qi_men_star.dart（新建）
abstract class QiMenStar {
  String get name;          // 显示名（"天蓬" / "太乙" / "一白"）
  String get singleCharName;// 单字简写（"蓬" / "乙" / "白"）
  int get number;           // 1-9 序号
  FiveXing? get fiveXing;   // 五行属性，紫白星可空
  HouTianGua? get originalGong; // 原宫，日家 day-count 体系下可空
}
```

时家 `NineStarsEnum implements QiMenStar`（retrofit，无破坏性变更）；日家新建 `RiJiaStarEnum`、年家新建 `ZiBaiStarEnum`。

#### 4.6.2 受影响的入口

将 `final NineStarsEnum star` 改为 `final QiMenStar star`：

- `lib/domain/entities/each_gong.dart:19`
- `lib/domain/entities/qimen_pan.dart:38`（`zhiFuStar`）
- `lib/model/each_gong.dart:10`（model 层，与 entity 同步）
- `lib/redesign_ui/layouts/smart_grid.dart:235,252`（`starEnum / jiStarEnum`）

#### 4.6.3 UI 主题解耦

`lib/redesign_ui/core/design_system.dart:51,337` 中"九星色彩"是按 `NineStarsEnum` 写死的 switch。新建 `QiMenStarTheme` 注册表：

```dart
class QiMenStarTheme {
  Color colorOf(QiMenStar star) => _registry[star.runtimeType]?[star.number] ?? Colors.grey;
}
```

每家在 `service_locator` 注册自己的 ColorMap。**该注册表本期可只支持时家配色，日 / 年家在对应 Phase 内补**。

#### 4.6.4 工作量影响

- Phase 1 增加 0.5 人日（接口 + retrofit + 主题注册表骨架）。
- Phase 2（日家）+ Phase 4（年家）各增加 0.5 人日（专属星集枚举 + 配色映射）。
- Phase 3（月家）**不增加**，复用 `NineStarsEnum`。

## 5. 分阶段实施

### Phase 1: 抽象骨架（不动算法）
建 `QiMenJia` 枚举、`BaseJu` 接口，把 Repository / UseCase / DI 升级为双维 Map；时家走默认值 SHI；所有现有测试通过即视为完成。

### Phase 2: 日家
- 算法依据：[`ri_jia_algorithm.md`](./ri_jia_algorithm.md)（用户 2026-04-30 提供完整规范）。
- 新增 `RiJiaJu`、`RiJiaQiMenCalculator`、`RiJiaPanArranger`。
- **新增 `RiJiaStarEnum`**（太乙/摄提/轩辕/招摇/天符/青龙/咸池/太阴/天乙），实现 `QiMenStar`。
- 起符机制特殊：**距甲子日天数 d 顺飞太乙**，与时 / 月 / 年家"旬首-值符"机制不共享。
- 起局法支持：日家不分拆补 / 置润，按 `ArrangeType.CHAI_BU` 默认占位即可（领域上日家无此细分）。
- 加日家专属测试，复用 `test_shi_jia_*` 的测试结构。

### Phase 3: 月家
- 算法依据：[`yue_jia_algorithm.md`](./yue_jia_algorithm.md)。
- **复用 `NineStarsEnum`**（月家用九星与时家完全相同），无需新增星集。
- 仅用阴遁；起局机制 = 五虎遁推月干 + 年支孟仲季三元定起局宫。
- 干 / 支双驱：值符随月干、值使随月支。
- 共享 `MonthYearJiaPanArranger`（与年家共用，见 §4.3）。

### Phase 4: 年家
- 算法依据：[`nian_jia_algorithm.md`](./nian_jia_algorithm.md)。
- **新增 `ZiBaiStarEnum`**（一白/二黑/.../九紫），实现 `QiMenStar`。
- 仅用阴遁；起局机制 = 60×3=180 年三元 + 三元局（上元 1 局 / 中元 4 局 / 下元 7 局）。
- 干 / 支双驱：值符随年干、值使随年支。
- 复用 Phase 3 的 `MonthYearJiaPanArranger`。
- **必需固化"上元起算锚点"为常量**（参考 1864 / 1924 / 1984），不同书籍可能差 60 年。

### Phase 5: UI 接入
- ViewModel + 两个页面接入家选择器。
- 不支持的 (家, 起局法) 组合在 UI 上灰显。

### Phase 6（可选，后置）: 命名收敛与合并
- 评估是否将 `ShiJiaJu / ShiJiaQiMen` 重命名为 `QiMenJu / QiMenPanModel`；将 4 家排盘合并为单类配 `drivingJiaZi`。
- 此阶段单独立项，本期不做。

## 6. 风险与权衡

| 风险 | 应对 |
| --- | --- |
| 算法实现需要奇门遁甲领域知识 | 三家算法事实清单（`ri_jia_algorithm.md` / `yue_jia_algorithm.md` / `nian_jia_algorithm.md`）已落地为权威依据；评审与样例核对仍需领域人员介入 |
| `NineStarsEnum` 被 27 个文件硬编码使用，多态化为 `QiMenStar` 影响范围大 | Phase 1 内一次性 retrofit `NineStarsEnum implements QiMenStar`；UI 主题改用 `QiMenStarTheme` 注册表（§4.6） |
| 日家起符机制（day-count 顺飞）与其它三家不同构 | 不强行抽象；日家走独立 `RiJiaPanArranger`，时 / 月 / 年共用 `GanZhiDrivenPanArranger`（D3 修订） |
| 年家三元起算锚点书籍差异 60 年 | `nian_jia_algorithm.md` §3 已标注；实现时锚点放常量文件，便于校正 |
| `QiMenPan.shiJiaJu` 字段名长期不准确 | 接受短期不一致，标注 TODO；进入 Phase 6 再统一 |
| `qimen_agent_tool.dart` 暴露给 AI 的 schema 不含家字段 | Phase 5 完成后在 AI tool 增加可选 `jia` 参数，向下兼容（缺省 SHI） |
| 双架构（传统 `pages/` + MVVM `presentation/`）需同步 | 本期**只在 MVVM 路径上接入新家**；传统 `pages/scalable_shi_jia_qi_men_view_page.dart` 维持仅时家 |
| `BaseJu` / `QiMenStar` 抽象不当导致后续 Phase 6 难合并 | Phase 1 接口仅暴露最小集，不预留"未来可能用到"字段 |

## 7. 决策记录

- **D1**: "家" 与 "起局法" 是两个独立的轴 — 不合并为一个 `enum`。理由：起局法（拆补/置润/茅山/阴盘）在时家内部本就有 4 种，组合到家轴会成 16 项扁平枚举，难维护。
- **D2**: 不在本期重命名 `ShiJiaQiMen / ShiJiaJu`。理由：影响 `lib/pages/`、`lib/ai/`、`test/`、`docs/`、`redesign_ui/` 数十处；与本期目标解耦。
- **D3（修订 2026-04-30）**: 排盘抽象按"机制是否同构"分两组：
  - **GanZhiDrivenPanArranger**（时家 + 月家 + 年家共享）：旬首-值符机制相同，参数化 `(符干源, 使支源)` 二元组。
  - **RiJiaPanArranger**（日家独立）：day-count 顺飞机制与上面三家不同构。
  - 不试图为四家做统一父类。理由：日家与其它三家差异过大，强行抽象只会让公共父类变成 untyped bag。
- **D4**: Phase 1 不引入新 UI；先打通后端管线。理由：在算法未实现前接 UI 容易让 ViewModel 状态变得难以回退。
- **D5（新增 2026-04-30）**: 必须引入 `QiMenStar` 接口而非保留 `NineStarsEnum`。理由：日家（太乙等九星）与年家（紫白九星）名称、五行、原宫语义都与时家不同，无法借壳；月家虽可复用 `NineStarsEnum`，但单为月家保留单态会阻塞 Phase 2/4。Retrofit `NineStarsEnum implements QiMenStar` 在 Phase 1 内一次性完成，避免后续返工。

## 8. 验收标准

- [ ] `flutter analyze` 通过，无新增 warning。
- [ ] `flutter test` 全绿，包括既有时家测试与新家测试。
- [ ] 时家 UI 行为与重构前像素级一致（人工对比 1 个固定时间点的盘）。
- [ ] 日家 / 月家 / 年家各能起出至少 1 个固定时间点的盘，且与权威书籍排盘一致。
- [ ] DI 切换家/起局法不会泄漏单例状态（`ServiceLocator.reset()` 后行为不变）。

## 9. 参考

- 算法事实清单（本期权威依据）：
  - [`ri_jia_algorithm.md`](./ri_jia_algorithm.md) — 日家奇门
  - [`yue_jia_algorithm.md`](./yue_jia_algorithm.md) — 月家奇门
  - [`nian_jia_algorithm.md`](./nian_jia_algorithm.md) — 年家奇门
- 既有架构：`ARCHITECTURE.md`、`docs/REFACTORING_PLAN.md`。
- 后续待补：《奇门遁甲秘笈大全》《奇门法窍》《奇门旨归》对应篇目页码（评审时落地到三个 algorithm 文档的 §11/§12 参考节）。
