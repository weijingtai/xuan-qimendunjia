# 年家奇门 — 详细任务清单

> 配套：[`nian_jia_algorithm.md`](./nian_jia_algorithm.md)（算法事实清单）、[`extra_hour_tasks.md`](./extra_hour_tasks.md)（顶层 Phase 4 高层任务）
>
> **权威事实依据**：[`qimen_jia_comparison.md`](./qimen_jia_comparison.md)（用户 2026-04-30 提供的四家终极对照表）。
>
> **2026-04-30 重大修订**：依据对照表，年家正统主流用**北斗九星**（同时家、月家），紫白九星派别**本期不实现**。月家=年家完全同源，年家直接复用 Phase 3 的 `GanZhiDrivenQiMenPan` + `NineStarsEnum`，工作量大幅缩减。
>
> 版本：2026-04-30
> 状态：草稿，待领域人员评审 + 测试 fixture 补全

---

## 0. 前置依赖

| 必备依赖 | 来源 | 说明 |
| --- | --- | --- |
| Phase 1 全部任务 | P1-T1..T8 | |
| `QiMenStar` 接口 | P1-T2.5 | 年家直接复用 `NineStarsEnum`（已 retrofit） |
| **`GanZhiDrivenQiMenPan` 共享排盘器** | **P3-T5** | **强阻塞**：年家直接复用，仅传入不同驱动柱与三元映射 |
| Phase 3 月家全链路通过 | P3-T1..T7 | 共享类已被一家场景验证过，年家是第二家用例 |
| `SanYuanType` 共享枚举 | P3-T2.1 | 月年家共用 |

> 年家**不**依赖 Phase 2 日家成果（独立路径）。
> **本 Phase 大部分代码量是锚点常量与单测**；月家若已落地，Phase 4 真正的工作量约为 1 人日。

---

## P4-T1 算法清单核对（含起算锚点权威性 + 样例补全）

### 当前状态
[`nian_jia_algorithm.md`](./nian_jia_algorithm.md) 算法主体完备，§11 待补充：

- [ ] §11.1 起算锚点的权威依据（不同书籍可能差 60 年）
- [x] ~~§11.2 紫白九星五行属性~~（**主流不用，本期不做**）
- [x] ~~§11.3 紫白九星吉凶完整表~~（**主流不用，本期不做**）
- [ ] §11.4 立春边界处理：年家以立春为年界
- [ ] §11.5 至少 5 个手算样例

### 子任务

#### P4-T1.1 起算锚点权威性确认（**强阻塞**）
- 在三种说法中确定项目选用版本：
  | 方案 | 上元 | 中元 | 下元 | 引用 |
  | --- | --- | --- | --- | --- |
  | **A（推荐）** | 1864 | 1924 | **1984** | 《奇门遁甲秘笈大全》主流 |
  | B | 1804 | 1864 | 1924 | 部分书籍 |
- 决议后写入 `nian_jia_algorithm.md` §4.1，标注引用源
- **影响**：所有年家盘的三元判定，是 P4-T3、P4-T4、P4-T7 的强阻塞

#### P4-T1.2 ~~紫白星五行属性确认~~（**已废弃**）

**原因**：对照表 §二澄清，年家正统主流用**北斗九星**（同时家、月家），紫白九星仅风水派 / 玄空派分支，本期不实现。
原表格保留作为后续扩展参考：

<details>
<summary>展开：紫白九星五行表（仅作未来 Phase 6+ 扩展参考）</summary>

| 紫白星 | 五行 | 配宫 |
| --- | --- | --- |
| 一白 | 水 | 坎 |
| 二黑 | 土 | 坤 |
| 三碧 | 木 | 震 |
| 四绿 | 木 | 巽 |
| 五黄 | 土 | 中宫 |
| 六白 | 金 | 乾 |
| 七赤 | 金 | 兑 |
| 八白 | 土 | 艮 |
| 九紫 | 火 | 离 |
</details>

#### P4-T1.3 fixture 补全（推荐 8 条 — 三元锚点必测）

| # | 输入年 | 期望年干支 | 三元 | 元内年序 | 起局宫 | 期望值符星 | 期望值使门 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1984 | 甲子 | 下元 | 1 | 兑 7 | TODO | TODO | **下元锚点** |
| 2 | 2024 | 甲辰 | 下元 | 41 | 兑 7 | TODO | TODO | 当代 |
| 3 | 2026 | 丙午 | 下元 | 43 | 兑 7 | TODO | TODO | 今年 |
| 4 | 1864 | 甲子 | 上元 | 1 | 坎 1 | TODO | TODO | **上元锚点** |
| 5 | 1924 | 甲子 | 中元 | 1 | 巽 4 | TODO | TODO | **中元锚点** |
| 6 | 2044 | 甲子 | 上元（新轮） | 1 | 坎 1 | TODO | TODO | **三元滚动** |
| 7 | 1923 | 癸亥 | 上元 | 60 | 坎 1 | TODO | TODO | 中元前一年 |
| 8 | 1983 | 癸亥 | 中元 | 60 | 巽 4 | TODO | TODO | 下元前一年 |

> **强制**：1864/1924/1984/2044 这四个甲子年是三元切换点，必测。

#### P4-T1.4 落地为代码 fixture
- **新建**：`test/fixtures/nian_jia_samples.dart`
  ```dart
  typedef NianJiaSample = ({
    int year,
    String yearJiaZi,
    String sanYuan,
    int yearIndexInYuan,
    int qiJuGong,
    String zhiFuStar,
    String zhiShiDoor,
  });
  
  const List<NianJiaSample> nianJiaSamples = [/* TODO 8 条 */];
  ```

---

## P4-T2 实体 NianJiaJu

### 子任务

#### P4-T2.1 新建 domain 实体
- **新建**：`lib/domain/entities/nian_jia_ju.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'base_entity.dart';
  import 'base_ju.dart';
  import 'qi_men_jia.dart' show QiMenJia;
  import 'san_yuan_type.dart'; // 复用 P3-T2.1 已建
  
  /// 年家局实体
  class NianJiaJu extends Equatable implements Entity, BaseJu {
    @override
    final String id;
    @override
    final DateTime panDateTime;
    @override
    QiMenJia get jia => QiMenJia.NIAN;
    @override
    YinYang get yinYangDun => YinYang.YIN; // 年家恒为阴遁
    @override
    final String fourZhuEightChar;
    
    /// 年柱（驱动柱：年干→值符，年支→值使）
    final JiaZi yearJiaZi;
    /// 三元（上/中/下）
    final SanYuanType sanYuan;
    /// 元内年序（1-60）
    final int yearIndexInYuan;
    /// 起局宫（坎1/巽4/兑7 之一）
    final HouTianGua qiJuGong;
    
    @override
    int get juNumber => qiJuGong.number;
    
    TianGan get yearGan => yearJiaZi.gan;
    DiZhi get yearZhi => yearJiaZi.diZhi;
    
    NianJiaJu({
      required this.id,
      required this.panDateTime,
      required this.yearJiaZi,
      required this.sanYuan,
      required this.yearIndexInYuan,
      required this.qiJuGong,
      required this.fourZhuEightChar,
    });
    
    @override
    List<Object?> get props => [id, yearJiaZi, sanYuan, yearIndexInYuan, qiJuGong];
    
    String get juDescription =>
        '阴遁年家·${qiJuGong.numberName}局（${sanYuan.name}第${yearIndexInYuan}年）';
  }
  ```

### 验收
- [ ] `NianJiaJu.yearJiaZi.gan` 暴露便利，便于排盘器使用
- [ ] `flutter analyze` 通过

---

## ~~P4-T2.5 星集 ZiBaiStarEnum（紫白九星）~~（**已废弃 — 本期不做**）

### 废弃原因
对照表 §二澄清，年家正统主流用**北斗九星**（同时家、月家），紫白九星仅风水派 / 玄空派分支。本期年家**直接复用 `NineStarsEnum`**，无需新建星集枚举。

如未来扩展紫白派别，单独立 Phase 6+ 任务，本任务的代码骨架与色板设计仍可作为起点（折叠保留）。

<details>
<summary>展开：废弃前的 ZiBaiStarEnum 实现骨架（仅作未来 Phase 6+ 扩展参考）</summary>

```dart
// lib/enums/enum_zi_bai_stars.dart（未来扩展才新建）
enum ZiBaiStarEnum implements QiMenStar {
  YI_BAI(1, "一白", "白", FiveXing.SHUI, HouTianGua.Kan),
  ER_HEI(2, "二黑", "黑", FiveXing.TU, HouTianGua.Kun),
  SAN_BI(3, "三碧", "碧", FiveXing.MU, HouTianGua.Zhen),
  SI_LV(4, "四绿", "绿", FiveXing.MU, HouTianGua.Xun),
  WU_HUANG(5, "五黄", "黄", FiveXing.TU, HouTianGua.Center),
  LIU_BAI(6, "六白", "白", FiveXing.JIN, HouTianGua.Qian),
  QI_CHI(7, "七赤", "赤", FiveXing.JIN, HouTianGua.Dui),
  BA_BAI(8, "八白", "白", FiveXing.TU, HouTianGua.Gen),
  JIU_ZI(9, "九紫", "紫", FiveXing.HUO, HouTianGua.Li);
  // 接口字段、五行属性、吉凶判断详见原 P4-T2.5.1 草案
}
```

色板：一白白 / 二黑深灰 / 三碧碧绿 / 四绿草绿 / 五黄明黄 / 六白带金白 /
七赤朱红 / 八白带土黄白 / 九紫紫。`singleCharName` 撞名（白×3）须用 `name` 全名。
</details>

---

## P4-T3 锚点常量 NianJiaSanYuanAnchor（关键）

### 子任务

#### P4-T3.1 锚点类
- **新建**：`lib/utils/nian_jia_san_yuan_anchor.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'package:qimendunjia/domain/entities/san_yuan_type.dart';
  
  /// 年家三元起算锚点
  ///
  /// 算法依据：nian_jia_algorithm.md §3
  /// 锚点（方案 A，主流）：
  /// - 上元第 1 年 = 1864
  /// - 中元第 1 年 = 1924
  /// - 下元第 1 年 = 1984
  /// 周期：60 年/元 × 3 元 = 180 年大循环
  class NianJiaSanYuanAnchor {
    static const int upperYuanStartYear = 1864;
    static const int middleYuanStartYear = 1924;
    static const int lowerYuanStartYear = 1984;
    static const int yearsPerYuan = 60;
    static const int totalCycle = yearsPerYuan * 3; // 180
    
    /// 反查：公历年 → (三元, 元内年序 1-60)
    static (SanYuanType, int) yearToYuanAndIndex(int year) {
      // 把年份归一化到 [upperYuanStartYear, upperYuanStartYear+180) 区间
      final offset = year - upperYuanStartYear;
      final normalized = ((offset % totalCycle) + totalCycle) % totalCycle;
      
      if (normalized < yearsPerYuan) {
        return (SanYuanType.SHANG, normalized + 1);
      } else if (normalized < yearsPerYuan * 2) {
        return (SanYuanType.ZHONG, normalized - yearsPerYuan + 1);
      } else {
        return (SanYuanType.XIA, normalized - yearsPerYuan * 2 + 1);
      }
    }
    
    /// 年家三元 → 起局宫
    /// **不同于月家**：年家中元起巽4，月家中元起兑7
    static HouTianGua sanYuanToQiJuGong(SanYuanType sy) {
      switch (sy) {
        case SanYuanType.SHANG: return HouTianGua.Kan; // 1
        case SanYuanType.ZHONG: return HouTianGua.Xun; // 4（年家）
        case SanYuanType.XIA:   return HouTianGua.Dui; // 7
      }
    }
  }
  ```

> **重要差异**：年家与月家虽都用 `SanYuanType`，但**起局宫映射不同**：
> - 月家：上元坎 1 / 中元兑 7 / 下元巽 4（按年支孟仲季）
> - 年家：上元坎 1 / 中元巽 4 / 下元兑 7（按 60 年三元）
>
> **不能复用** `YueJiaQiMenJuCalculator.sanYuanToQiJuGong`！

#### P4-T3.2 单元测试（强阻塞）
- **新建**：`test/test_nian_jia_san_yuan_anchor.dart`
- **必测样例**：

| 输入年 | 期望 (三元, 序号) | 期望起局宫 | 备注 |
| --- | --- | --- | --- |
| 1864 | (上元, 1) | 坎 1 | 上元锚点 |
| 1923 | (上元, 60) | 坎 1 | 上元末年 |
| 1924 | (中元, 1) | 巽 4 | 中元锚点 |
| 1983 | (中元, 60) | 巽 4 | 中元末年 |
| 1984 | (下元, 1) | 兑 7 | 下元锚点 |
| 2026 | (下元, 43) | 兑 7 | 当代 |
| 2043 | (下元, 60) | 兑 7 | 下元末年 |
| 2044 | (上元, 1) | 坎 1 | **新轮上元** |
| 1804 | (上元, 1) | 坎 1 | 前一轮上元 |

### 验收
- [ ] 上述全部 9 条断言通过
- [ ] 锚点常量与 `nian_jia_algorithm.md` §3 一致

---

## P4-T4 计算器 NianJiaCalculator

### 前置
- P4-T1.1 锚点决策完成
- P4-T2 + P4-T3 就绪

### 子任务

#### P4-T4.1 主实现
- **新建**：`lib/utils/nian_jia_qi_men_ju_calculator.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'package:xuan_common/adapters/lunar_adapter.dart';
  import 'package:qimendunjia/domain/entities/nian_jia_ju.dart';
  import 'package:qimendunjia/utils/nian_jia_san_yuan_anchor.dart';
  
  class NianJiaQiMenJuCalculator {
    final DateTime dateTime;
    
    NianJiaQiMenJuCalculator({required this.dateTime});
    
    NianJiaJu calculate() {
      final lunar = LunarAdapter.fromDate(dateTime);
      final yearJiaZi = JiaZi.getFromGanZhiValue(lunar.getYearInGanZhi())!;
      // 用与 yearJiaZi 一致的"立春纪年"年份
      final solarYear = lunar.getSolarYear();
      // 注意：lunar.getSolarYear() 是否在立春前返回 prev year？需 P3-T1.1 同样的桥接验证
      final (sanYuan, indexInYuan) =
          NianJiaSanYuanAnchor.yearToYuanAndIndex(solarYear);
      final qiJuGong = NianJiaSanYuanAnchor.sanYuanToQiJuGong(sanYuan);
      return NianJiaJu(
        id: 'nianjia-${solarYear}',
        panDateTime: dateTime,
        yearJiaZi: yearJiaZi,
        sanYuan: sanYuan,
        yearIndexInYuan: indexInYuan,
        qiJuGong: qiJuGong,
        fourZhuEightChar: [
          lunar.getYearInGanZhi(),
          lunar.getMonthInGanZhi(),
          lunar.getDayInGanZhi(),
          lunar.getTimeInGanZhi(),
        ].join(' '),
      );
    }
  }
  ```

### 边界（重要）
- **立春纪年 vs 公历年**：年家通常以**立春**为年界
  - 2024-01-15 仍属"癸卯年"（上一年），公历年 2024
  - 2024-02-15 已属"甲辰年"，公历年 2024
  - 二者的 `yearJiaZi` 不同，但传给 `NianJiaSanYuanAnchor` 的"公历年"应当与 `yearJiaZi` 对应才能保证三元正确
- **解决**：用一个推导函数 `_yearJiaZiToSolarYear(JiaZi yearJiaZi, DateTime around)`，返回该年柱对应的实际公历年
  - 对 2024-01-15 → yearJiaZi = 癸卯 → 公历年 = 2023
  - 对 2024-02-15 → yearJiaZi = 甲辰 → 公历年 = 2024
- **fixture 必须包含**：2024-01-15 与 2024-02-15 各一条

### 验收
- [ ] P4-T1.3 全部 fixture 的 `(yearJiaZi, sanYuan, qiJuGong)` 命中
- [ ] 立春边界用例（2024-01-15 vs 2024-02-15）的三元归属正确

---

## P4-T5 复用 GanZhiDrivenQiMenPan（DataSource + 适配）

### 子任务

#### P4-T5.1 DataSource
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
- **新增**：
  ```dart
  class NianJiaCalculatorDataSource implements JiaScopedCalculatorDataSource {
    @override
    QiMenJia get supportedJia => QiMenJia.NIAN;
    
    @override
    Future<BaseJu> calculate(DateTime dateTime) async {
      return NianJiaQiMenJuCalculator(dateTime: dateTime).calculate();
    }
    
    @override
    String get name => '年家奇门';
  }
  ```

#### P4-T5.2 排盘器适配（薄壳）
- **新建**：`lib/model/nian_jia_qi_men.dart`
  ```dart
  import 'package:qimendunjia/enums/enum_zi_bai_stars.dart';
  import 'package:qimendunjia/domain/entities/qi_men_star.dart';
  import 'gan_zhi_driven_qi_men_pan.dart';
  
  class NianJiaQiMen {
    final GanZhiDrivenQiMenPan _delegate;
    
    NianJiaQiMen({required NianJiaJu ju, required PanArrangeSettings settings})
      : _delegate = GanZhiDrivenQiMenPan(
          ju: ju,
          drivingGan: ju.yearGan,
          drivingZhi: ju.yearZhi,
          // 年家正统主流复用北斗九星（同时家、月家）；紫白派本期不实现
          starSet: NineStarsEnum.values
              .map<QiMenStar>((e) => e)
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number)),
          qiJuGong: ju.qiJuGong,
          settings: settings,
        );
    
    Map<HouTianGua, EachGong> get gongMapper => _delegate.gongMapper;
    QiMenStar get zhiFuStar => _delegate.zhiFuStar;
    EightDoorEnum get zhiShiDoor => _delegate.zhiShiDoor;
    HouTianGua get zhiFuStarAtGong => _delegate.zhiFuStarAtGong;
    HouTianGua get zhiShiDoorAtGong => _delegate.zhiShiDoorAtGong;
  }
  ```

#### P4-T5.3 P3-T5 设计回测（**关键验证点**）
- 用年家 fixture（P4-T1.3）通过 `NianJiaQiMen` 跑一次完整排盘
- 若 `GanZhiDrivenQiMenPan` 在月家通过但在年家失败 → P3-T5 设计有缺陷，需回到 P3-T5 重做
- **这是 D3（修订）的最关键验证点**

### 验收
- [ ] 年家 fixture 全部样例通过
- [ ] `GanZhiDrivenQiMenPan` 单测无需修改即可同时支撑月/年家
- [ ] `NianJiaQiMen.zhiFuStar` 是 `NineStarsEnum` 实例（与月家、时家相同的北斗九星）

---

## P4-T6 Repository / DI 接入

### 子任务

#### P4-T6.1 Repository 派发
- **修改**：`lib/data/repositories/qimen_calculator_repository_impl.dart`
- 增加 `case QiMenJia.NIAN` → 走 `NianJiaQiMen` → `NianJiaPanMapper`

#### P4-T6.2 Mapper
- **新建**：`lib/data/models/mappers/nian_jia_pan_mapper.dart`

#### P4-T6.3 DI 注册
- **修改**：`lib/di/service_locator.dart`
- 注册 `QiMenJia.NIAN -> {ArrangeType.CHAI_BU: NianJiaCalculatorDataSource()}`

### 验收
- [ ] `(QiMenJia.NIAN, CHAI_BU)` 全链路可用

---

## P4-T7 测试

### 子任务

#### P4-T7.1 单元测试
- **新建**：`test/test_nian_jia_qi_men.dart`
- 覆盖：
  - `NianJiaSanYuanAnchor` 边界（1864/1924/1984/2044/1804，已在 P4-T3.2 覆盖，本处可引用）
  - `NianJiaQiMenJuCalculator` × P4-T1.3 fixture
  - **立春边界**（2024-01-15 vs 2024-02-15）
  - 月家 / 年家共用同一 `NineStarsEnum` 的回归断言

#### P4-T7.2 GanZhiDrivenQiMenPan 双家覆盖（保险）
- 参数化测试，同一个 `GanZhiDrivenQiMenPan` 用月家 / 年家两种驱动柱配置，断言核心算法步骤一致（除起局宫与三元映射）

### 验收
- [ ] `flutter test test/test_nian_jia_qi_men.dart` 全绿
- [ ] 锚点常量边界（1864/1924/1984/2044/1804）100% 覆盖

---

## 整体验收

- [ ] P4-T1..P4-T7 全部完成（注意 P4-T2.5 已废弃）
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter test` 全绿（含年家 + 时/日/月家回归）
- [ ] 1864/1924/1984/2044 三元切换点全部正确
- [ ] 手工测试：MVVM Page 切换到年家，分别起 1984、2024、2026 三个年盘
- [ ] 年家盘 UI 显示北斗九星（与月家、时家一致）
- [ ] 立春边界（2024-01-15 / 2024-02-15）行为符合预期

---

## 关键风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| **起算锚点书籍差异 60 年** | 全年家盘错位 60 年（三元归属错） | P4-T1.1 强制评审；锚点改为常量便于切换；fixture 必含 1864/1924/1984 三个甲子年作锚点检验 |
| `LunarAdapter.getYearInGanZhi()` 立春边界与公历年不一致 | 立春前后日期年柱错位 | P4-T4 用 `_yearJiaZiToSolarYear` 推导函数；fixture 加 2024-01-15/02-15 边界 |
| `GanZhiDrivenQiMenPan` 在年家失败 | P3-T5 返工，连锁延期 | P4-T5.3 是关键验证点；建议 Phase 3 后期就用 mock 跑年家 fixture |
| 月家与年家 `sanYuanToQiJuGong` 映射不同 | 错用月家映射 | `NianJiaSanYuanAnchor.sanYuanToQiJuGong` 独立实现；不复用 |
| 未来扩展紫白派别 | 用户提出风水派需求时需返工 | 已折叠保留 ZiBaiStarEnum 草案，作为 Phase 6+ 起点 |

---

## 工作量分解

| 子任务 | 估算 |
| --- | --- |
| P4-T1（含锚点权威性确认 + fixture 收集） | 0.4 人日（不含领域评审等待） |
| P4-T2（实体） | 0.2 人日 |
| ~~P4-T2.5（紫白星集）~~ | **0 人日（已废弃）** |
| **P4-T3（锚点常量 + 单测）— 关键** | **0.3 人日** |
| P4-T4（计算器，含立春边界） | 0.4 人日 |
| P4-T5（薄壳复用 + 关键回测） | 0.2 人日（无需新建星集） |
| P4-T6（Repository/DI 接入） | 0.2 人日 |
| P4-T7（测试） | 0.2 人日（无需 ZiBai 全表覆盖） |
| **小计** | **1.9 人日** |

> 较修订前节省约 **0.4 人日**（紫白星集废弃）。年家在 Phase 3 月家完整落地后变成"参数差异 + 锚点常量"，是 4 个 Phase 中最轻的一个。

> 关键路径：P4-T1.1（锚点决策）→ P4-T3（锚点常量）→ P4-T5.3（共享类回测）。年家代码量小，但锚点与 LunarAdapter 桥接是认知关键路径，建议先评审再编码。
