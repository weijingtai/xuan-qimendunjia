# 月家奇门 — 详细任务清单

> 配套：[`yue_jia_algorithm.md`](./yue_jia_algorithm.md)（算法事实清单）、[`extra_hour_tasks.md`](./extra_hour_tasks.md)（顶层 Phase 3 高层任务）
>
> **权威事实依据**：[`qimen_jia_comparison.md`](./qimen_jia_comparison.md)（用户 2026-04-30 提供的四家终极对照表）。
>
> **2026-04-30 对照表澄清的关键事实**：
> - 月家是**飞盘**（不是转盘）
> - **月家 = 年家完全同源**：星 / 门 / 神 / 排盘规则一致，唯一差异是驱动柱与起局机制 → P3-T5 `GanZhiDrivenQiMenPan` 是月年家共享的核心
> - 复用 `NineStarsEnum`（北斗九星，与时家、年家相同）
> - 只用阴遁、八门 / 九星 / 八神均逆飞
>
> 版本：2026-04-30
> 状态：草稿，待领域人员评审 + 测试 fixture 补全

---

## 0. 前置依赖

| 必备依赖 | 来源 | 说明 |
| --- | --- | --- |
| Phase 1 全部任务 | P1-T1..T8 | |
| `QiMenStar` 接口（月家直接复用 `NineStarsEnum`） | P1-T2.5 | **不需新增星集** |

> 月家**不**依赖 Phase 2 日家成果（独立路径）。
> 月家**会**为 Phase 4 年家提供 `GanZhiDrivenQiMenPan` 共享类，是年家的强阻塞前置。

---

## P3-T1 算法清单核对（含 LunarAdapter 桥接 + 样例补全）

### 当前状态
[`yue_jia_algorithm.md`](./yue_jia_algorithm.md) 算法主体完备，§11 待补充：

- [ ] §11.1 五虎遁推月干在节气分界日的归属（属上月还是当月）
- [ ] §11.2 月支 ↔ 月干合成具体月柱时与 `LunarAdapter.getMonthInGanZhi()` 的一致性
- [ ] §11.3 至少 5 个手算样例

### 子任务

#### P3-T1.1 LunarAdapter 桥接验证（强阻塞）
- **新建**：`test/test_lunar_adapter_yue_bridge.dart`
- **测试矩阵**：
  | 场景 | 输入 | 期望（按五虎遁手算） |
  | --- | --- | --- |
  | 立春前 | 2024-02-04 03:00 | 癸年 + 丑月 = 乙丑 |
  | 立春当日 | 2024-02-04 17:00 | 甲年 + 寅月 = 丙寅（立春换年也换月） |
  | 立春后 | 2024-02-05 | 甲年 + 寅月 = 丙寅 |
  | 闰四月 | 2025-05-15（闰四月） | 乙年 + 巳月 = 辛巳 或 闰巳？ |
  | 跨年子月 | 2025-12-22（冬至后大雪） | 乙年 + 子月 = 戊子 |
- **验证**：`LunarAdapter.getMonthInGanZhi()` 是否与上述五虎遁手算一致；如不一致，必须在 P3-T3 内增加修正逻辑

#### P3-T1.2 fixture 补全（推荐 6 条）

| # | 输入(年-月-日) | 期望年柱 | 期望月柱 | 三元 | 起局宫 | 期望值符星 | 期望值使门 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2026-04-15 | 丙午 | 壬辰 | 中元 | 兑 7 | TODO | TODO | 当前月（仲年） |
| 2 | 2024-02-15 | 甲辰 | 丙寅 | 下元 | 巽 4 | TODO | TODO | 季年立春后 |
| 3 | 2024-01-15 | 癸卯 | 乙丑 | 中元 | 兑 7 | TODO | TODO | **立春前**（仲年） |
| 4 | 2025-12-22 | 乙巳 | 戊子 | 上元 | 坎 1 | TODO | TODO | 孟年（巳） |
| 5 | 2027-08-15 | 丁未 | 戊申 | 下元 | 巽 4 | TODO | TODO | 季年（未） |
| 6 | 2023-06-15 | 癸卯 | 戊午 | 中元 | 兑 7 | TODO | TODO | 仲年另一年 |

> **缺什么**：每条需 (a) `getMonthInGanZhi()` 实测验证；(b) 旬首 → 值符星 / 值使门 的手算（领域知识）。

#### P3-T1.3 落地为代码 fixture
- **新建**：`test/fixtures/yue_jia_samples.dart`
  ```dart
  typedef YueJiaSample = ({
    DateTime input,
    String yearJiaZi,
    String monthJiaZi,
    String sanYuan,
    int qiJuGong,
    String zhiFuStar,
    String zhiShiDoor,
  });
  
  const List<YueJiaSample> yueJiaSamples = [/* TODO 6 条 */];
  ```

---

## P3-T2 实体 YueJiaJu

### 子任务

#### P3-T2.1 新建 domain 实体（含 SanYuanType 共享枚举）
- **新建**：`lib/domain/entities/san_yuan_type.dart`（**月家年家共享**）
  ```dart
  enum SanYuanType {
    SHANG('上元'),
    ZHONG('中元'),
    XIA('下元');
    final String name;
    const SanYuanType(this.name);
  }
  ```

- **新建**：`lib/domain/entities/yue_jia_ju.dart`
  ```dart
  import 'package:common/enums.dart';
  import 'base_entity.dart';
  import 'base_ju.dart';
  import 'qi_men_jia.dart' show QiMenJia;
  import 'san_yuan_type.dart';
  
  /// 月家局实体
  class YueJiaJu extends Equatable implements Entity, BaseJu {
    @override
    final String id;
    @override
    final DateTime panDateTime;
    @override
    QiMenJia get jia => QiMenJia.YUE;
    @override
    YinYang get yinYangDun => YinYang.YIN; // 月家恒为阴遁
    @override
    final String fourZhuEightChar;
    
    /// 年柱（用于决定三元）
    final JiaZi yearJiaZi;
    /// 月柱（驱动柱：月干→值符，月支→值使）
    final JiaZi monthJiaZi;
    /// 当年所在三元（按年支孟仲季）
    final SanYuanType sanYuan;
    /// 起局宫（坎1/兑7/巽4 之一）
    final HouTianGua qiJuGong;
    
    /// 局数 = 起局宫号
    @override
    int get juNumber => qiJuGong.number;
    
    DiZhi get monthZhi => monthJiaZi.diZhi;
    TianGan get monthGan => monthJiaZi.gan;
    
    YueJiaJu({
      required this.id,
      required this.panDateTime,
      required this.yearJiaZi,
      required this.monthJiaZi,
      required this.sanYuan,
      required this.qiJuGong,
      required this.fourZhuEightChar,
    });
    
    @override
    List<Object?> get props => [id, yearJiaZi, monthJiaZi, sanYuan, qiJuGong];
    
    String get juDescription => '阴遁月家·${qiJuGong.numberName}局（${sanYuan.name}）';
  }
  ```

### 验收
- [ ] `YueJiaJu.yinYangDun == YinYang.YIN` 恒成立
- [ ] `flutter analyze` 通过
- [ ] `SanYuanType` 在 `domain/entities/` 而非 `enums/`，便于年家复用

---

## P3-T3 计算器 YueJiaCalculator

### 前置
- P3-T1.1 LunarAdapter 桥接验证通过
- P3-T2 实体就绪

### 子任务

#### P3-T3.1 主实现
- **新建**：`lib/utils/yue_jia_qi_men_ju_calculator.dart`
- **代码骨架**：
  ```dart
  import 'package:common/enums.dart';
  import 'package:common/adapters/lunar_adapter.dart';
  import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';
  import 'package:qimendunjia/domain/entities/san_yuan_type.dart';
  
  class YueJiaQiMenJuCalculator {
    final DateTime dateTime;
    
    YueJiaQiMenJuCalculator({required this.dateTime});
    
    /// 年支 → 三元映射（按孟仲季）
    static SanYuanType yearZhiToSanYuan(DiZhi yearZhi) {
      const meng = {DiZhi.YIN, DiZhi.SHEN, DiZhi.SI, DiZhi.HAI};
      const zhong = {DiZhi.ZI, DiZhi.WU, DiZhi.MAO, DiZhi.YOU};
      // const ji = {DiZhi.CHEN, DiZhi.XU, DiZhi.CHOU, DiZhi.WEI};
      if (meng.contains(yearZhi)) return SanYuanType.SHANG;
      if (zhong.contains(yearZhi)) return SanYuanType.ZHONG;
      return SanYuanType.XIA;
    }
    
    /// 月家三元 → 起局宫
    /// 注意与年家映射不同！
    static HouTianGua sanYuanToQiJuGong(SanYuanType sy) {
      switch (sy) {
        case SanYuanType.SHANG: return HouTianGua.Kan;  // 1（孟年）
        case SanYuanType.ZHONG: return HouTianGua.Dui;  // 7（仲年）
        case SanYuanType.XIA:   return HouTianGua.Xun;  // 4（季年）
      }
    }
    
    YueJiaJu calculate() {
      final lunar = LunarAdapter.fromDate(dateTime);
      final yearJiaZi = JiaZi.getFromGanZhiValue(lunar.getYearInGanZhi())!;
      final monthJiaZi = JiaZi.getFromGanZhiValue(lunar.getMonthInGanZhi())!;
      final sanYuan = yearZhiToSanYuan(yearJiaZi.diZhi);
      final qiJuGong = sanYuanToQiJuGong(sanYuan);
      return YueJiaJu(
        id: 'yuejia-${dateTime.millisecondsSinceEpoch}',
        panDateTime: dateTime,
        yearJiaZi: yearJiaZi,
        monthJiaZi: monthJiaZi,
        sanYuan: sanYuan,
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

### 边界
- 五虎遁推月干已由 `LunarAdapter` 处理，但**节气分界日**仍需 P3-T1.1 验证一致性
- 闰月：LunarAdapter 是否能正确处理？P3-T1.1 中加专项 fixture
- **不要混淆**：月家 `sanYuanToQiJuGong` 与年家映射不同（年家中元→巽 4，月家中元→兑 7）

### 验收
- [ ] P3-T1.2 全部 fixture 的 `(yearJiaZi, monthJiaZi, sanYuan, qiJuGong)` 命中

---

## P3-T4 DataSource

### 子任务

#### P3-T4.1
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
- **新增**：
  ```dart
  class YueJiaCalculatorDataSource implements JiaScopedCalculatorDataSource {
    @override
    QiMenJia get supportedJia => QiMenJia.YUE;
    
    @override
    Future<BaseJu> calculate(DateTime dateTime) async {
      return YueJiaQiMenJuCalculator(dateTime: dateTime).calculate();
    }
    
    @override
    String get name => '月家奇门';
  }
  ```

### 验收
- [ ] DI 注册不报错（见 P3-T6）

---

## P3-T5 排盘器 GanZhiDrivenQiMenPan（共享，关键路径）

> **本任务为 Phase 3 的核心**：月家在此首次实现共享排盘器，年家 Phase 4 直接复用。设计时必须容纳两家差异。

### 设计目标

`GanZhiDrivenQiMenPan` 必须可参数化容纳：

| 入参 | 月家值 | 年家值 |
| --- | --- | --- |
| `drivingGan` | `monthGan` | `yearGan` |
| `drivingZhi` | `monthZhi` | `yearZhi` |
| `starSet` | `NineStarsEnum.values` | `ZiBaiStarEnum.values` |
| `qiJuGong` | 月家 sanYuanToQiJuGong | 年家 sanYuanToQiJuGong（不同映射） |
| `isYinDun` | true（恒） | true（恒） |

共享算法（按 `yue_jia_algorithm.md` §5-§9）：
1. 布地盘三奇六仪（阴遁逆布）
2. 由 `drivingGan` 找旬首，旬首落宫的本位星 = 值符，本位门 = 值使
3. 天盘九星逆飞：值符跟 `drivingGan` 落宫，其余按 `starSet` 顺序逆排
4. 人盘八门逆飞：值使从本宫起，逆数到 `drivingZhi` 宫
5. 神盘八神逆排

### 子任务

#### P3-T5.1 设计构造签名
- **新建**：`lib/model/gan_zhi_driven_qi_men_pan.dart`
- **代码骨架**：
  ```dart
  import 'package:common/enums.dart';
  import 'package:qimendunjia/domain/entities/base_ju.dart';
  import 'package:qimendunjia/domain/entities/qi_men_star.dart';
  import 'package:qimendunjia/domain/entities/each_gong.dart';
  
  /// 干支双驱奇门排盘器（月家 + 年家共享）
  /// 算法依据：yue_jia_algorithm.md §5-§9（与 nian_jia_algorithm.md §4-§8 同构）
  class GanZhiDrivenQiMenPan {
    final BaseJu ju;
    final TianGan drivingGan;
    final DiZhi drivingZhi;
    /// 9 个星按宫号 1-9 顺序排列
    final List<QiMenStar> starSet;
    final HouTianGua qiJuGong;
    final PanArrangeSettings settings;
    
    late final Map<HouTianGua, EachGong> gongMapper;
    late final QiMenStar zhiFuStar;
    late final EightDoorEnum zhiShiDoor;
    late final HouTianGua zhiFuStarAtGong;
    late final HouTianGua zhiShiDoorAtGong;
    
    GanZhiDrivenQiMenPan({
      required this.ju,
      required this.drivingGan,
      required this.drivingZhi,
      required this.starSet,
      required this.qiJuGong,
      required this.settings,
    }) {
      assert(starSet.length == 9, '星集长度必须为 9');
      assert(_starsAlignedToGong(), '星集必须按宫号 1-9 顺序排列');
      _arrange();
    }
    
    bool _starsAlignedToGong() {
      for (int i = 0; i < 9; i++) {
        if (starSet[i].number != i + 1) return false;
      }
      return true;
    }
    
    void _arrange() {
      // 1. 阴遁地盘三奇六仪逆布
      final diPanGan = _placeDiPanGan();
      
      // 2. 由 drivingGan 找旬首，旬首落宫定值符值使
      final drivingJiaZi = JiaZi.fromGanZhi(drivingGan, drivingZhi);
      final xunHeader = SixJia.getSixJiaByJiaZi(drivingJiaZi.xunHeader);
      final xunHeaderGongNumber = diPanGan.entries
          .firstWhere((e) => e.value == xunHeader.gan).key;
      zhiFuStar = starSet[xunHeaderGongNumber - 1];
      zhiShiDoor = EightDoorEnum.mapNumberToEnum[xunHeaderGongNumber]!;
      
      // 3. 天盘九星逆飞：值符跟 drivingGan 落宫
      final drivingGanGong = diPanGan.entries
          .firstWhere((e) => e.value == drivingGan).key;
      zhiFuStarAtGong = HouTianGua.getGua(drivingGanGong);
      final tianPanStars = _arrangeTianPanStars(drivingGanGong);
      
      // 4. 人盘八门逆飞：值使从本宫起，逆数到 drivingZhi 宫
      final drivingZhiGongNumber = _diZhiToGong(drivingZhi);
      zhiShiDoorAtGong = HouTianGua.getGua(drivingZhiGongNumber);
      final renPanDoors = _arrangeRenPanDoors(xunHeaderGongNumber, drivingZhiGongNumber);
      
      // 5. 神盘八神逆排
      final shenPanGods = _arrangeShenPanGods(drivingGanGong);
      
      // 组装
      gongMapper = _assemble(diPanGan, tianPanStars, renPanDoors, shenPanGods);
    }
    
    /// 阴遁地盘三奇六仪逆布：戊→己→庚→辛→壬→癸→丁→丙→乙
    /// 起局宫放戊，按九宫逆飞分配，中5寄坤2
    Map<int, TianGan> _placeDiPanGan() {
      const sequence = [TianGan.WU, TianGan.JI, TianGan.GENG, TianGan.XIN,
                        TianGan.REN, TianGan.GUI, TianGan.DING,
                        TianGan.BING, TianGan.YI];
      // 阴遁九宫逆序：从 qiJuGong 起递减，跳中5寄坤2
      // ... 利用现有 lib/utils/change_sequence_utils.dart
      throw UnimplementedError('TODO 实现，参考 ShiJiaQiMen.calculateZhuanPan');
    }
    
    /// 月支/年支 → 落宫
    int _diZhiToGong(DiZhi zhi) {
      // 后天八卦地支配宫：子坎1, 丑寅艮8, 卯震3, 辰巳巽4, 午离9, 未申坤2, 酉兑7, 戌亥乾6
      // 中5无地支
      // 复用既有工具
      throw UnimplementedError('TODO');
    }
    
    Map<int, QiMenStar> _arrangeTianPanStars(int targetGong) {
      // 值符 zhiFuStar 飞至 targetGong，其余九星按 starSet 顺序逆排
      throw UnimplementedError('TODO');
    }
    
    Map<int, EightDoorEnum> _arrangeRenPanDoors(int xunHeaderGong, int targetGong) {
      // 值使从 xunHeaderGong 起，逆数到 targetGong；其余八门逆排
      throw UnimplementedError('TODO');
    }
    
    Map<int, EightGodsEnum> _arrangeShenPanGods(int zhiFuGong) {
      // 八神：值符、螣蛇、太阴、六合、白虎、玄武、九地、九天 逆排
      throw UnimplementedError('TODO');
    }
    
    Map<HouTianGua, EachGong> _assemble(...) {
      throw UnimplementedError('TODO');
    }
  }
  ```

#### P3-T5.2 复用既有工具
- 参考 `lib/utils/change_sequence_utils.dart` 的 `changeNumberSeq` 与 `changeNineStarsSeq`，避免重复实现
- 参考 `lib/model/shi_jia_qi_men.dart:90-280`（旬首/值符/天地盘部分），但**不直接继承**：
  - 时家用阳遁/阴遁双向；月年家恒阴遁，可裁剪
  - 时家用 `timeJiaZi` 单驱；月年家用 gan/zhi 双驱

#### P3-T5.3 月家适配器（薄壳）
- **新建**：`lib/model/yue_jia_qi_men.dart`
  ```dart
  import 'package:qimendunjia/enums/enum_nine_stars.dart';
  import 'gan_zhi_driven_qi_men_pan.dart';
  
  class YueJiaQiMen {
    final GanZhiDrivenQiMenPan _delegate;
    
    YueJiaQiMen({required YueJiaJu ju, required PanArrangeSettings settings})
      : _delegate = GanZhiDrivenQiMenPan(
          ju: ju,
          drivingGan: ju.monthGan,
          drivingZhi: ju.monthZhi,
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

### 边界
- `starSet` 长度必须为 9，按宫号 1-9 顺序对应；构造时强 assert 拒绝错配
- 月家与年家的 `starSet` 来源不同 enum，但通过 `QiMenStar` 接口统一
- 中宫（5）寄坤（2）：与时家保持一致

### 验收（关键）
- [ ] 月家 fixture（P3-T1.2）排盘输出与算法文档 §6-§9 全部一致
- [ ] **同一份 `GanZhiDrivenQiMenPan` 在 mock 年家场景（传入 `ZiBaiStarEnum + yearGan/yearZhi`）能正常排盘** — 即使 `ZiBaiStarEnum` 还没建，可用 placeholder 验证签名
- [ ] `flutter analyze` 通过

---

## P3-T6 Repository / DI 接入

### 子任务

#### P3-T6.1 Repository 派发
- **修改**：`lib/data/repositories/qimen_calculator_repository_impl.dart`
- 在 `arrangePan` 派发增加 `case QiMenJia.YUE` → 走 `YueJiaQiMen` → `YueJiaPanMapper`

#### P3-T6.2 Mapper
- **新建**：`lib/data/models/mappers/yue_jia_pan_mapper.dart`

#### P3-T6.3 DI 注册
- **修改**：`lib/di/service_locator.dart`
- 注册 `QiMenJia.YUE -> {ArrangeType.CHAI_BU: YueJiaCalculatorDataSource()}`

### 验收
- [ ] `(QiMenJia.YUE, CHAI_BU)` 全链路可用

---

## P3-T7 测试

### 子任务

#### P3-T7.1 单元测试
- **新建**：`test/test_yue_jia_qi_men.dart`
- 覆盖：
  - `YueJiaQiMenJuCalculator.yearZhiToSanYuan`：12 个地支全覆盖
  - `YueJiaQiMenJuCalculator` × P3-T1.2 fixtures
  - `GanZhiDrivenQiMenPan`（月家场景）× 同 fixtures
  - LunarAdapter 桥接边界（节气分界、闰月）

#### P3-T7.2 共享类双家覆盖（防御性）
- 参数化测试：用 mock 数据让 `GanZhiDrivenQiMenPan` 跑一次"模拟年家"输入（不依赖 Phase 4 实现），验证 `starSet` 切换正确
- 这是 D3（修订）的关键验证点 — 确保年家 Phase 4 能无修改复用

### 验收
- [ ] `flutter test test/test_yue_jia_qi_men.dart` 全绿
- [ ] `GanZhiDrivenQiMenPan` 单测覆盖率 ≥ 85%

---

## 整体验收

- [ ] P3-T1..P3-T7 全部完成
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter test` 全绿（含月家 + 既有时家 + 日家回归）
- [ ] `GanZhiDrivenQiMenPan` 已封装好，年家 Phase 4 可直接复用
- [ ] 手工测试：MVVM Page 切换到月家，能起 2026-04 月盘
- [ ] 月家盘 brief 文案包含 "月家·" 前缀（依赖 P5-T3）

---

## 关键风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| `GanZhiDrivenQiMenPan` 参数化设计不当导致年家 P4-T5 难复用 | Phase 4 重构成本爆炸 | P3-T5 完成后立即用 mock 跑年家 fixture（即使 `ZiBaiStarEnum` 未建） |
| `LunarAdapter.getMonthInGanZhi()` 与五虎遁手算不一致 | 月柱错位，全月家盘错 | P3-T1.1 桥接测试是强阻塞 |
| 闰月行为未定义 | 罕见日期排盘错误 | P3-T1.1 加专项 fixture |
| `starSet` 排序约定（按宫号 vs 按枚举顺序）混淆 | 排盘错位但不报错，难调 | 构造时 assert `starSet[i].number == i+1`，从源头拒绝错配 |
| 月家与年家 `sanYuanToQiJuGong` 映射不同 | 年家复用时误用月家映射 | 不共享该方法；年家在 `NianJiaSanYuanAnchor` 中独立实现 |

---

## 工作量分解

| 子任务 | 估算 |
| --- | --- |
| P3-T1（算法核对 + LunarAdapter 桥接 + fixture） | 0.5 人日 |
| P3-T2（实体 + SanYuanType 共享枚举） | 0.2 人日 |
| P3-T3（计算器） | 0.3 人日 |
| P3-T4 + P3-T6（DataSource + Repo + DI） | 0.3 人日 |
| **P3-T5（共享排盘器 — 关键路径）** | **1 人日** |
| P3-T7（测试） | 0.4 人日 |
| **小计** | **2.7 人日** |

> 关键路径：P3-T1.1 → P3-T5。P3-T5 的设计直接决定 Phase 4 工作量，建议**先评审设计再编码**。
