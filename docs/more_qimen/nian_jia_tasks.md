# 年家奇门 — 详细任务清单

> 配套：[`nian_jia_algorithm.md`](./nian_jia_algorithm.md)（算法事实清单）、[`extra_hour_tasks.md`](./extra_hour_tasks.md)（顶层 Phase 4 高层任务）
> 版本：2026-04-30 初版
> 状态：草稿，待领域人员评审 + 测试 fixture 补全

---

## 0. 前置依赖

| 必备依赖 | 来源 | 说明 |
| --- | --- | --- |
| Phase 1 全部任务 | P1-T1..T8 | |
| `QiMenStar` 接口 | P1-T2.5 | 年家 `ZiBaiStarEnum` 需实现该接口 |
| **`GanZhiDrivenQiMenPan` 共享排盘器** | **P3-T5** | **强阻塞**：年家直接复用，不再新建 |
| Phase 3 月家全链路通过 | P3-T1..T7 | 共享类已被一家场景验证过，年家是第二家用例 |
| `SanYuanType` 共享枚举 | P3-T2.1 | 月年家共用 |

> 年家**不**依赖 Phase 2 日家成果（独立路径）。
> 年家本身代码量小（最多的代码工作量是锚点常量与单测），**认知关键路径**在锚点权威性 + 与月家共享类的回测。

---

## P4-T1 算法清单核对（含起算锚点权威性 + 样例补全）

### 当前状态
[`nian_jia_algorithm.md`](./nian_jia_algorithm.md) 算法主体完备，§10 待补充：

- [ ] §10.1 起算锚点的权威依据（不同书籍可能差 60 年）
- [ ] §10.2 紫白九星五行属性
- [ ] §10.3 紫白九星吉凶完整表
- [ ] §10.4 至少 5 个手算样例

### 子任务

#### P4-T1.1 起算锚点权威性确认（**强阻塞**）
- 在三种说法中确定项目选用版本：
  | 方案 | 上元 | 中元 | 下元 | 引用 |
  | --- | --- | --- | --- | --- |
  | **A（推荐）** | 1864 | 1924 | **1984** | 《奇门遁甲秘笈大全》主流 |
  | B | 1804 | 1864 | 1924 | 部分书籍 |
  | C | 紫白飞星另算 | - | - | 复杂派别 |
- 决议后写入 `nian_jia_algorithm.md` §10.1，标注引用源
- **影响**：所有年家盘的三元判定，是 P4-T3、P4-T4、P4-T7 的强阻塞

#### P4-T1.2 紫白星五行属性确认
项目内**拟用**（依据《沈氏玄空学》紫白派常识）：

| 紫白星 | 五行 | 配宫 | 备注 |
| --- | --- | --- | --- |
| 一白 | 水 | 坎 | 北方 |
| 二黑 | 土 | 坤 | 西南 |
| 三碧 | 木 | 震 | 东方 |
| 四绿 | 木 | 巽 | 东南 |
| 五黄 | 土 | 中宫 | 寄坤艮 |
| 六白 | 金 | 乾 | 西北 |
| 七赤 | 金 | 兑 | 西方 |
| 八白 | 土 | 艮 | 东北 |
| 九紫 | 火 | 离 | 南方 |

- [ ] 与领域参考确认无误
- [ ] 落地到 `ZiBaiStarEnum.fiveXing` 字段（P4-T2.5）

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
  import 'package:common/enums.dart';
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

## P4-T2.5 星集 ZiBaiStarEnum（紫白九星）

### 子任务

#### P4-T2.5.1 新建枚举（含五行 + 配宫）
- **新建**：`lib/enums/enum_zi_bai_stars.dart`
- **代码骨架**：
  ```dart
  import 'package:common/enums.dart';
  import 'package:qimendunjia/domain/entities/qi_men_star.dart';
  
  /// 紫白九星
  /// 顺序：一白(1) → 二黑(2) → 三碧(3) → 四绿(4) → 五黄(5) → 六白(6) → 七赤(7) → 八白(8) → 九紫(9)
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
    
    @override
    final int number;
    @override
    final String name;
    @override
    final String singleCharName;
    @override
    final FiveXing? fiveXing;
    @override
    final HouTianGua? originalGong;
    
    const ZiBaiStarEnum(
        this.number, this.name, this.singleCharName, this.fiveXing, this.originalGong);
    
    /// 紫白吉星（一白/六白/八白/九紫常被列吉）
    bool get isJi => [YI_BAI, LIU_BAI, BA_BAI, JIU_ZI].contains(this);
    /// 紫白凶星（二黑/三碧/五黄/七赤常被列凶）
    bool get isXiong => [ER_HEI, SAN_BI, WU_HUANG, QI_CHI].contains(this);
    
    static ZiBaiStarEnum fromNumber(int n) =>
        values.firstWhere((e) => e.number == n);
  }
  ```

#### P4-T2.5.2 注入 `QiMenStarTheme`
- **修改**：`lib/redesign_ui/core/qi_men_star_theme.dart`
- **建议色板**（按字面色值）：

| 紫白星 | 颜色 | 备注 |
| --- | --- | --- |
| 一白 | 白色（带蓝调） | 水 |
| 二黑 | 深灰 / 墨黑 | 凶 |
| 三碧 | 碧绿 | 凶 |
| 四绿 | 草绿 | 木 |
| 五黄 | 明黄 | 极凶 |
| 六白 | 白色（带金调） | 金 |
| 七赤 | 朱红 | 凶 |
| 八白 | 白色（带土黄） | 吉 |
| 九紫 | 紫色 | 火 / 大吉 |

### 边界（重要）

⚠️ **`singleCharName` 撞名**：一白/六白/八白都是"白"。UI **必须用 `name` 全名**而非单字。在 `BriefPalaceLayout` 等组件渲染时增加判断或直接展示双字 `name`。

⚠️ **`originalGong = HouTianGua.Center`** 仅 五黄 有意义；其他星的 `originalGong` 是名义对应宫位，但年家用紫白时**不参与"伏吟反吟"判定**（与时家九星语义不同）。在 enum 文档注释里明确说明。

### 验收
- [ ] `ZiBaiStarEnum.YI_BAI is QiMenStar` 为 `true`
- [ ] `ZiBaiStarEnum.WU_HUANG.fiveXing == FiveXing.TU`
- [ ] UI 渲染年家盘星名为全名而非"白"

---

## P4-T3 锚点常量 NianJiaSanYuanAnchor（关键）

### 子任务

#### P4-T3.1 锚点类
- **新建**：`lib/utils/nian_jia_san_yuan_anchor.dart`
- **代码骨架**：
  ```dart
  import 'package:common/enums.dart';
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
  import 'package:common/enums.dart';
  import 'package:common/adapters/lunar_adapter.dart';
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
          starSet: ZiBaiStarEnum.values
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
- [ ] `NianJiaQiMen.zhiFuStar` 是 `ZiBaiStarEnum` 实例（而非 NineStarsEnum）

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
  - `ZiBaiStarEnum.fiveXing` 全表（9 条）
  - `ZiBaiStarEnum.isJi` / `isXiong` 全表

#### P4-T7.2 GanZhiDrivenQiMenPan 双家覆盖（保险）
- 参数化测试，同一个 `GanZhiDrivenQiMenPan` 跑月家 + 年家两种 `starSet`，断言核心算法步骤无差异（除了星集与起局宫）

### 验收
- [ ] `flutter test test/test_nian_jia_qi_men.dart` 全绿
- [ ] `ZiBaiStarEnum` 100% 覆盖

---

## 整体验收

- [ ] P4-T1..P4-T7 全部完成
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter test` 全绿（含年家 + 时/日/月家回归）
- [ ] 1864/1924/1984/2044 三元切换点全部正确
- [ ] 手工测试：MVVM Page 切换到年家，分别起 1984、2024、2026 三个年盘
- [ ] `ZiBaiStarEnum` UI 显示用全名，无"白"字撞名问题
- [ ] 立春边界（2024-01-15 / 2024-02-15）行为符合预期

---

## 关键风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| **起算锚点书籍差异 60 年** | 全年家盘错位 60 年（三元归属错） | P4-T1.1 强制评审；锚点改为常量便于切换；fixture 必含 1864/1924/1984 三个甲子年作锚点检验 |
| `LunarAdapter.getYearInGanZhi()` 立春边界与公历年不一致 | 立春前后日期年柱错位 | P4-T4 用 `_yearJiaZiToSolarYear` 推导函数；fixture 加 2024-01-15/02-15 边界 |
| `GanZhiDrivenQiMenPan` 在年家失败 | P3-T5 返工，连锁延期 | P4-T5.3 是关键验证点；建议 Phase 3 后期就用 mock 跑年家 fixture（即使 `ZiBaiStarEnum` 还没建） |
| 紫白星与时家九星字形撞名（"白"字 ×3） | UI 显示混乱 | P4-T2.5 边界条款：UI 必须用 `name` 全名 |
| `originalGong` 在年家无伏吟反吟语义 | 复用时家伏吟检测会误判 | `EachGong.isStarFuYin` 等字段在年家盘强制 false；或在 `QiMenPan.jia == NIAN` 时跳过相关检测 |
| 月家与年家 `sanYuanToQiJuGong` 映射不同 | 错用月家映射 | `NianJiaSanYuanAnchor.sanYuanToQiJuGong` 独立实现；不复用 |

---

## 工作量分解

| 子任务 | 估算 |
| --- | --- |
| P4-T1（含锚点权威性确认 + fixture 收集） | 0.4 人日（不含领域评审等待） |
| P4-T2 + P4-T2.5（实体 + 紫白星集 + 五行表） | 0.4 人日 |
| **P4-T3（锚点常量 + 单测）— 关键** | **0.3 人日** |
| P4-T4（计算器，含立春边界） | 0.4 人日 |
| P4-T5（薄壳复用 + 关键回测） | 0.3 人日 |
| P4-T6（Repository/DI 接入） | 0.2 人日 |
| P4-T7（测试） | 0.3 人日 |
| **小计** | **2.3 人日** |

> 关键路径：P4-T1.1（锚点决策）→ P4-T3（锚点常量）→ P4-T5.3（共享类回测）。年家代码量小，但锚点与 LunarAdapter 桥接是认知关键路径，建议先评审再编码。
