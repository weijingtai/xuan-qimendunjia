# 日家奇门 — 详细任务清单

> 配套：[`ri_jia_algorithm.md`](./ri_jia_algorithm.md)（算法事实清单）、[`extra_hour_tasks.md`](./extra_hour_tasks.md)（顶层 Phase 2 高层任务）
>
> **权威事实依据**：[`qimen_jia_comparison.md`](./qimen_jia_comparison.md)（用户 2026-04-30 提供的四家终极对照表）。
>
> **2026-04-30 对照表澄清的关键事实**：
> - 日家是**飞盘**（不是转盘）
> - **不布三奇六仪**（已确认）
> - **不用八神**（改用黄道黑道、喜神、贵神 — 神煞体系）
> - **无值符 / 无值使**，以休门为纲
>
> 版本：2026-04-30
> 状态：草稿，待领域人员评审 + 测试 fixture 补全

---

## 0. 前置依赖

| 必备依赖 | 来源 | 当前状态 |
| --- | --- | --- |
| `QiMenJia` 枚举 | P1-T1 | 未开始 |
| `BaseJu` 接口 | P1-T2 | 未开始 |
| `QiMenStar` 接口 + `NineStarsEnum` retrofit | P1-T2.5 | 未开始 |
| `QiMenStarTheme` 注册表骨架 | P1-T2.6 | 未开始 |
| Repository / UseCase / DI 双维 Map | P1-T3..T6 | 未开始 |
| ViewModel 增加 `jia` 参数 | P1-T7 | 未开始 |
| Phase 1 回归测试通过 | P1-T8 | 未开始 |

> Phase 1 任一项未完成则本 Phase 全部阻塞。本 Phase **不依赖** Phase 3/4。

---

## P2-T1 算法清单核对（含 5-10 样例补全）

### 当前状态
[`ri_jia_algorithm.md`](./ri_jia_algorithm.md) 算法主体完备，§8 仍有"待补充"项；其中已被对照表 §三/§七澄清的项已划掉：

- [ ] §8.1 "九星顺飞不入中 5"的具体跳宫规则（遇 5 跳到 6？还是寄坤 2？）
- [ ] §8.2 节气过渡日（如冬至当日为非甲子日）的边界处理
- [x] ~~§8.3 是否需要排三奇六仪地盘？~~（**对照表 §三：不布**）
- [x] ~~§8.4 是否使用八神？~~（**对照表 §七：不用，改黄道黑道喜神贵神**）
- [ ] §8.5 至少 5 个手算样例

### 子任务

#### P2-T1.1 与领域专家对齐 §8.1-§8.2 待评审项
- 重点：§8.1 跳宫规则（"遇 5 跳到 6" vs "5 寄坤 2"）+ §8.2 节气过渡日归属
- 输出：在 `ri_jia_algorithm.md` §8 每条记录"已评审，结论：xxx + 引用"
- **强阻塞**：P2-T3、P2-T5 都依赖 §8.1 跳宫规则

#### P2-T1.2 补全 fixture（推荐 8 条覆盖）

| # | 输入日期 | 期望日柱 | 阴/阳遁 | 期望休门宫 | 太乙起算 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | TODO | 甲子 | 阳遁 | 坎 1 | d=0, 起坎 1 | 阳遁基准点 |
| 2 | TODO | 乙丑 | 阳遁 | 坎 1 | d=1 | 与甲子同 3 日组 |
| 3 | TODO | 丁卯 | 阳遁 | 坤 2 | d=3 | 跨入下一组 |
| 4 | TODO | 庚午 | 阳遁 | 震 3 | d=6 | 中段验证 |
| 5 | TODO | 甲子 | 阴遁 | 离 9 | d=0, 起离 9 | 阴遁基准点 |
| 6 | TODO | 戊午 | 阴遁 | 兑 7 | TODO | 阴遁中段 |
| 7 | TODO | 庚子 | 阳遁 | 乾 6 | TODO | 第二甲子 |
| 8 | TODO | 节气分界日 | TODO | TODO | TODO | §8.2 边界 |

> **缺什么**：每条需 (a) 真实公历日期；(b) 节气表确认阴阳遁；(c) 60 甲子日序与距甲子日天数 d。可借助现有的 `LunarAdapter.fromDate()` + `TwentyFourJieQi.fromName()` 批量生成候选，再人工抽检。

#### P2-T1.3 落地为代码 fixture
- **新建**：`test/fixtures/ri_jia_samples.dart`
  ```dart
  typedef RiJiaSample = ({
    DateTime input,
    String dayJiaZi,
    String yinYangDun,
    int xiuMenGong,
    int taiYiStartGong,
  });
  
  const List<RiJiaSample> riJiaSamples = [
    // (input: DateTime(YYYY, M, D), dayJiaZi: '甲子', yinYangDun: 'YANG', xiuMenGong: 1, taiYiStartGong: 1),
    // ... TODO 8 条
  ];
  ```
- **验收**：编译通过；P2-T7 单测可直接 import。

---

## P2-T2 实体 RiJiaJu

### 子任务

#### P2-T2.1 新建 domain 实体
- **新建**：`lib/domain/entities/ri_jia_ju.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'base_entity.dart';
  import 'base_ju.dart';
  import 'qi_men_jia.dart' show QiMenJia;
  
  class RiJiaJu extends Equatable implements Entity, BaseJu {
    @override
    final String id;
    @override
    final DateTime panDateTime;
    @override
    QiMenJia get jia => QiMenJia.RI;
    @override
    final YinYang yinYangDun;
    @override
    final String fourZhuEightChar;
    
    /// 日柱（核心驱动量）
    final JiaZi dayJiaZi;
    /// 距上一甲子日的天数（用于太乙顺飞），范围 0-59
    final int daysSinceJiaZi;
    /// 当日休门所落宫（按 §3 表查得）
    final HouTianGua xiuMenGong;
    /// 当前节气（用于阴阳遁判定 + UI 显示）
    final TwentyFourJieQi jieQiAt;
    
    bool get isYangDayGan => dayJiaZi.gan.yinYang.isYang;
    
    /// 日家"局数" = 休门宫号
    @override
    int get juNumber => xiuMenGong.number;
    
    RiJiaJu({
      required this.id,
      required this.panDateTime,
      required this.yinYangDun,
      required this.dayJiaZi,
      required this.daysSinceJiaZi,
      required this.xiuMenGong,
      required this.jieQiAt,
      required this.fourZhuEightChar,
    });
    
    @override
    List<Object?> get props => [id, panDateTime, dayJiaZi, daysSinceJiaZi, xiuMenGong, jieQiAt];
    
    String get juDescription => '${yinYangDun.name}日家·休门${xiuMenGong.numberName}宫';
  }
  ```

#### P2-T2.2 字段决策（不复用 ShiJiaJu 字段）
| ShiJiaJu 字段 | 日家如何处理 | 理由 |
| --- | --- | --- |
| `fuTouJiaZi` | **舍弃** | 日家无旬首-值符机制 |
| `atThreeYuan` | **舍弃** | 日家无三元概念 |
| `panJuJieQi / juDayNumber` | **舍弃** | 置润法专用 |
| `jieQiAt` | **保留** | 阴阳遁判定 + UI 展示 |
| 新增 `daysSinceJiaZi`、`xiuMenGong` | **新增** | 日家排盘核心驱动量 |

### 验收
- [ ] `RiJiaJu` 可被 `BaseJu` 引用持有
- [ ] `flutter analyze` 通过
- [ ] 类型断言 `ju is RiJiaJu` 工作正常

---

## P2-T2.5 星集 RiJiaStarEnum

### 子任务

#### P2-T2.5.1 新建枚举
- **新建**：`lib/enums/enum_ri_jia_stars.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'package:qimendunjia/domain/entities/qi_men_star.dart';
  
  /// 日家九星
  /// 顺序：太乙(1) → 摄提(2) → 轩辕(3) → 招摇(4) → 天符(5) → 青龙(6) → 咸池(7) → 太阴(8) → 天乙(9)
  enum RiJiaStarEnum implements QiMenStar {
    TAI_YI(1, "太乙", "乙"),
    SHE_TI(2, "摄提", "摄"),
    XUAN_YUAN(3, "轩辕", "轩"),
    ZHAO_YAO(4, "招摇", "招"),
    TIAN_FU(5, "天符", "符"),
    QING_LONG(6, "青龙", "青"),
    XIAN_CHI(7, "咸池", "咸"),
    TAI_YIN(8, "太阴", "阴"),
    TIAN_YI(9, "天乙", "天乙"); // 双字单字名
    
    @override
    final int number;
    @override
    final String name;
    @override
    final String singleCharName;
    @override
    FiveXing? get fiveXing => null;       // 日家不强调五行
    @override
    HouTianGua? get originalGong => null; // 日家无"原宫"
    
    const RiJiaStarEnum(this.number, this.name, this.singleCharName);
    
    bool get isJi => [TAI_YI, QING_LONG, TAI_YIN].contains(this);
    bool get isXiong => [XIAN_CHI, TIAN_FU].contains(this);
    
    static RiJiaStarEnum fromNumber(int n) =>
        values.firstWhere((e) => e.number == n);
  }
  ```

#### P2-T2.5.2 注入 `QiMenStarTheme`
- **修改**：`lib/redesign_ui/core/qi_men_star_theme.dart`（P1-T2.6 创建的注册表）
- **新增**：日家专属配色映射，按宫号 1-9 → Color
- **建议色板**：吉星偏暖（太乙金黄、青龙青、太阴紫罗兰），凶星偏冷（咸池墨黑、天符暗灰），中性星灰白

### 边界
- ⚠️ "天乙"是**双字单字名**（不能简化为单个汉字），UI 渲染需以 `name` 全名为准；`singleCharName` 字段在此星上保留 "天乙" 字符串
- 与 `NineStarsEnum.QIN`（天禽，单字"禽"）字形不冲突，但视觉密度需注意

### 验收
- [ ] `RiJiaStarEnum.TAI_YI is QiMenStar` 为 `true`
- [ ] 9 个枚举值的 `number` 与 `originalGong` 满足契约（即使 `originalGong` 是 null 也要被允许）

---

## P2-T3 计算器 RiJiaCalculator

### 前置
- **强阻塞**：P2-T1.1 已对齐 §8.1 跳宫规则
- P2-T2 实体就绪

### 子任务

#### P2-T3.1 主实现
- **新建**：`lib/utils/ri_jia_qi_men_ju_calculator.dart`
- **代码骨架**：
  ```dart
  import 'package:xuan_common/enums.dart';
  import 'package:xuan_common/adapters/lunar_adapter.dart';
  import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
  
  /// 日家局计算器
  /// 算法依据：docs/more_qimen/ri_jia_algorithm.md
  class RiJiaQiMenJuCalculator {
    final DateTime dateTime;
    
    RiJiaQiMenJuCalculator({required this.dateTime});
    
    /// 阳遁 3 日同宫起休门表（§3）
    static const Map<String, int> _yangDunXiuMenMap = {
      // 每行 3 个 jiazi-name → gong-number；20 个 entry 总计
      '甲子': 1, '戊子': 1, '壬子': 1, // 坎1
      '丁卯': 2, '辛卯': 2, '乙卯': 2, // 坤2
      '戊午': 3, '庚午': 3, '甲午': 3, // 震3
      '癸酉': 4, '丁酉': 4, '辛酉': 4, // 巽4
      '庚子': 6, '丙子': 6,            // 乾6
      '己卯': 7, '癸卯': 7,            // 兑7
      '壬午': 8, '丙午': 8,            // 艮8
      '乙酉': 9, '己酉': 9,            // 离9
    };
    
    /// 阴遁 3 日同宫起休门表（§3）
    static const Map<String, int> _yinDunXiuMenMap = {
      '甲子': 9, '戊子': 9, '壬子': 9, // 离9
      '丁卯': 8, '辛卯': 8, '乙卯': 8, // 艮8
      '戊午': 7, '庚午': 7, '甲午': 7, // 兑7
      '癸酉': 6, '丁酉': 6, '辛酉': 6, // 乾6
      '庚子': 4, '丙子': 4,            // 巽4
      '己卯': 3, '癸卯': 3,            // 震3
      '壬午': 2, '丙午': 2,            // 坤2
      '乙酉': 1, '己酉': 1,            // 坎1
    };
    
    RiJiaJu calculate() {
      final lunar = LunarAdapter.fromDate(dateTime);
      final dayJiaZi = JiaZi.getFromGanZhiValue(lunar.getDayInGanZhi())!;
      
      // 1. 阴阳遁判定（按节气）
      final jieQi = TwentyFourJieQi.fromName(
        lunar.getCurrentJieQi()?.getName() ?? lunar.getPrevJieQi().getName());
      final yinYang = jieQi.yinYangDun;
      
      // 2. 起休门：3 日同宫查表
      final groupStartIndex = ((dayJiaZi.number - 1) ~/ 3) * 3 + 1;
      final groupKey = JiaZi.getByNumber(groupStartIndex);
      final table = yinYang.isYang ? _yangDunXiuMenMap : _yinDunXiuMenMap;
      final xiuMenGongNumber = table[groupKey.name]!;
      
      // 3. 距甲子日天数（用于太乙顺飞，由排盘器消费）
      final daysSinceJiaZi = (dayJiaZi.number - 1) % 60;
      
      return RiJiaJu(
        id: 'rijia-${dateTime.millisecondsSinceEpoch}',
        panDateTime: dateTime,
        yinYangDun: yinYang,
        dayJiaZi: dayJiaZi,
        daysSinceJiaZi: daysSinceJiaZi,
        xiuMenGong: HouTianGua.getGua(xiuMenGongNumber),
        jieQiAt: jieQi,
        fourZhuEightChar: [
          lunar.getYearInGanZhi(),
          lunar.getMonthInGanZhi(),
          dayJiaZi.name,
          lunar.getTimeInGanZhi(),
        ].join(' '),
      );
    }
  }
  ```

#### P2-T3.2 查表完整性自检
- 单测：`_yangDunXiuMenMap.length == 20 && _yinDunXiuMenMap.length == 20`
- 单测：每张表覆盖 60 甲子日序的 20 个 3-日组首

### 边界
- 节气过渡日阴阳遁归属（§8.2）：先按"节气当日属新节气"实现，加 TODO 注释
- 子时换日（dateTime.hour == 23）：日家是否需要？参考时家做法但**不强求一致**（§8 待评审）

### 验收
- [ ] 输入 P2-T1.2 全部 fixture，`xiuMenGongNumber` 字段全部命中
- [ ] 表大小自检通过

---

## P2-T4 DataSource

### 子任务

#### P2-T4.1
- **修改**：`lib/data/datasources/calculator/qimen_calculator_data_source.dart`
- **新增**：
  ```dart
  /// 日家计算器数据源
  class RiJiaCalculatorDataSource implements JiaScopedCalculatorDataSource {
    @override
    QiMenJia get supportedJia => QiMenJia.RI;
    
    @override
    Future<BaseJu> calculate(DateTime dateTime) async {
      return RiJiaQiMenJuCalculator(dateTime: dateTime).calculate();
    }
    
    @override
    String get name => '日家奇门';
  }
  ```
- 日家不分拆补/置润，所有 `ArrangeType` 同映射到此 DataSource

### 验收
- [ ] DI 注册不报错（见 P2-T6）

---

## P2-T5 排盘器 RiJiaPanArranger（独立实现）

### 关键决策
**不复用** `ShiJiaQiMen / GanZhiDrivenQiMenPan` —— 日家用 day-count 顺飞机制（§5），与时/月/年家"旬首-值符"机制不同构。

### 子任务

#### P2-T5.1 主类骨架
- **新建**：`lib/model/ri_jia_qi_men.dart`
- **代码骨架**：
  ```dart
  /// 日家奇门排盘器（独立实现）
  /// 算法依据：ri_jia_algorithm.md §3-§6
  class RiJiaQiMen {
    final RiJiaJu ju;
    final PanArrangeSettings settings;
    late final Map<HouTianGua, EachGong> gongMapper;
    /// 日家"主星"（当日太乙落点），用于 QiMenPan.zhiFuStar 的占位
    late final RiJiaStarEnum dayMainStar;
    late final HouTianGua dayMainStarGong;
    
    RiJiaQiMen({required this.ju, required this.settings}) {
      _arrange();
    }
    
    void _arrange() {
      final eightDoorByGong = _arrangeEightDoors(ju.xiuMenGong, ju.isYangDayGan);
      final nineStarByGong = _arrangeRiJiaStars(ju.yinYangDun, ju.daysSinceJiaZi);
      
      // 取太乙落点作为 dayMainStar（用于 QiMenPan.zhiFuStar 占位）
      final taiYiGong = nineStarByGong.entries
          .firstWhere((e) => e.value == RiJiaStarEnum.TAI_YI).key;
      dayMainStar = RiJiaStarEnum.TAI_YI;
      dayMainStarGong = HouTianGua.getGua(taiYiGong);
      
      // 组装 EachGong
      final result = <HouTianGua, EachGong>{};
      for (int i = 1; i <= 9; i++) {
        if (i == 5) continue; // 中宫无门
        final gua = HouTianGua.getGua(i);
        result[gua] = EachGong(
          gongGua: gua,
          star: nineStarByGong[i] as QiMenStar?,
          door: eightDoorByGong[i],
          // 日家不布三奇六仪（对照表 §三），地盘干字段恒为 null
          tianPanGan: null,
          diPanGan: null,
        );
      }
      gongMapper = result;
    }
    
    /// 八门排布：从休门起，阳干顺时针、阴干逆时针，按后天八卦顺序绕
    Map<int, EightDoorEnum> _arrangeEightDoors(HouTianGua xiuMenGong, bool isYangGan) {
      // 后天八卦顺时针：1坎→8艮→3震→4巽→9离→2坤→7兑→6乾
      const clockwiseSeq = [1, 8, 3, 4, 9, 2, 7, 6];
      final order = isYangGan
          ? [EightDoorEnum.XIU, EightDoorEnum.SHENG, EightDoorEnum.SHANG,
             EightDoorEnum.DU, EightDoorEnum.JING, EightDoorEnum.SI,
             EightDoorEnum.JING_S /* 惊 */, EightDoorEnum.KAI]
          : [EightDoorEnum.XIU, EightDoorEnum.KAI, EightDoorEnum.JING_S,
             EightDoorEnum.SI, EightDoorEnum.JING, EightDoorEnum.DU,
             EightDoorEnum.SHANG, EightDoorEnum.SHENG];
      final startIdx = clockwiseSeq.indexOf(xiuMenGong.number);
      final result = <int, EightDoorEnum>{};
      for (int i = 0; i < 8; i++) {
        final gongIdx = clockwiseSeq[(startIdx + i) % 8];
        result[gongIdx] = order[i];
      }
      return result;
    }
    
    /// 九星顺飞：从太乙起，阳遁起坎1、阴遁起离9，按 d 偏移
    /// §8.1 跳宫规则待评审，**默认方案 A**：跳过 5（即 sequence = [1,2,3,4,6,7,8,9]）
    Map<int, RiJiaStarEnum> _arrangeRiJiaStars(YinYang yinYang, int d) {
      const skipFive = [1, 2, 3, 4, 6, 7, 8, 9]; // TODO #ri-jia-skip-5
      final startIdx = yinYang.isYang
          ? skipFive.indexOf(1)  // 阳遁太乙起坎1
          : skipFive.indexOf(9); // 阴遁太乙起离9
      final result = <int, RiJiaStarEnum>{};
      for (int starIdx = 0; starIdx < 9; starIdx++) {
        // d 决定起算位置；星按 1-9 序填入
        final gongIdx = skipFive[(startIdx + d + starIdx) % 8];
        result[gongIdx] = RiJiaStarEnum.fromNumber(starIdx + 1);
      }
      // 9 个星填到 8 个非中宫，必有 1 个落到与某个其他星相同的宫 — 取决于 §8.1 决策
      // TODO 评审后调整：方案 A 下星与宫一一映射可能需要 mod 9 而非 8
      return result;
    }
  }
  ```

#### P2-T5.2 八门顺序常量参考既有代码
- 复用 `lib/model/shi_jia_qi_men.dart:114` 的 `zhuanPanSeq = [1,8,3,4,9,2,7,6]`
- 八门顺序对照：参考 `lib/enums/enum_eight_door.dart`

#### P2-T5.3 九星顺飞跳宫规则（§8.1 强阻塞）
| 候选方案 | 实现 | 行为差异 |
| --- | --- | --- |
| **A：跳过 5 → 6**（默认，先实现） | sequence = [1,2,3,4,6,7,8,9]；9 星映射到 8 宫 | 必有 1 宫双星，需在 EachGong 用 List<QiMenStar> 或裁掉 1 星 |
| **B：5 寄坤 2** | 与八门一致：5 的星寄到 2 宫 | 坤 2 宫含双星，类时家"天禽寄坤" |

实现时用 const flag `_RI_JIA_SKIP_5_STRATEGY` 切换；P2-T1.1 评审后定型。

#### P2-T5.4 适配 `QiMenPan`
- `QiMenPan.zhiFuStar` 在日家无意义，**填占位**：`dayMainStar`（当日太乙落点星，即 `RiJiaStarEnum.TAI_YI`）
- `QiMenPan.zhiShiDoor` 同理：填**休门**
- `QiMenPan.zhiFuStarAtGong / zhiShiDoorAtGong`：填日家计算结果
- `QiMenPan.panGeJuList`：暂为空 List（§8.4 评审后再填日家专属格局）
- `QiMenPan.isStarFuYin / isStarFanYin / isDoorFuYin / isDoorFanYin / isGanFuYin / isGanFanYin`：日家全部 false（伏吟反吟语义不适用）
- `QiMenPan.horseLocation`：日家照样可由 `dayJiaZi.diZhi` 推驿马，保留

### 验收
- [ ] P2-T1.2 fixture 全部样例的 `(休门宫, 8 门分布, 9 星分布)` 与期望一致
- [ ] 中 5 宫不出现在 `gongMapper` 键集中
- [ ] `flutter analyze` 通过

---

## P2-T6 Repository 接入

### 子任务

#### P2-T6.1 派发逻辑
- **修改**：`lib/data/repositories/qimen_calculator_repository_impl.dart:41-73`
  ```dart
  Future<QiMenPan> arrangePan({...}) async {
    final modelSettings = PanArrangeSettings(...);
    switch (ju.jia) {
      case QiMenJia.SHI:
        final modelJu = ShiJiaJuMapper.toModel(ju as ShiJiaJu);
        return QiMenPanMapper.fromModel(model.ShiJiaQiMen(
          plateType: plateType,
          shiJiaJu: modelJu,
          settings: modelSettings,
        ));
      case QiMenJia.RI:
        final riJu = ju as RiJiaJu;
        return RiJiaPanMapper.fromModel(RiJiaQiMen(ju: riJu, settings: modelSettings));
      case QiMenJia.YUE:
      case QiMenJia.NIAN:
        throw UnsupportedJiaArrangeException('Phase 3/4 未完成');
    }
  }
  ```

#### P2-T6.2 Mapper
- **新建**：`lib/data/models/mappers/ri_jia_pan_mapper.dart`
- 输出 `QiMenPan`，按 P2-T5.4 的占位策略填充缺失字段

#### P2-T6.3 DI 注册
- **修改**：`lib/di/service_locator.dart:52-58`
  ```dart
  _services[Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>] = {
    QiMenJia.SHI: { /* 4 种起局法 */ },
    QiMenJia.RI: {
      ArrangeType.CHAI_BU: RiJiaCalculatorDataSource(),
    },
  };
  ```

### 验收
- [ ] `await repository.calculateJu(jia: QiMenJia.RI, arrangeType: CHAI_BU, dateTime: ...)` 返回 `RiJiaJu`
- [ ] `await repository.arrangePan(...)` 返回完整 `QiMenPan`，无 `Unsupported` 抛出

---

## P2-T7 测试

### 子任务

#### P2-T7.1 单元测试
- **新建**：`test/test_ri_jia_qi_men.dart`
- 覆盖：
  - `RiJiaQiMenJuCalculator` × P2-T1.2 fixtures（每条断言 `xiuMenGong / yinYangDun / daysSinceJiaZi`）
  - `RiJiaQiMen._arrangeEightDoors`：阳干样例 + 阴干样例
  - `RiJiaQiMen._arrangeRiJiaStars`：阳遁 + 阴遁，d=0 / d=29 / d=58
  - 边界：节气分界日、阴阳遁过渡

#### P2-T7.2 集成测试
- 通过 Repository 走全链路：
  ```dart
  test('日家全链路', () async {
    final ju = await repo.calculateJu(
      jia: QiMenJia.RI, arrangeType: ArrangeType.CHAI_BU,
      dateTime: DateTime(2026, 4, 30));
    expect(ju, isA<RiJiaJu>());
    final pan = await repo.arrangePan(
      ju: ju, plateType: PlateType.ZHUAN_PAN,
      settings: PanSettings.defaultSettings());
    expect(pan.gongMapper, hasLength(8)); // 中宫无门，仅 8 宫
    expect(pan.zhiFuStar, isA<QiMenStar>());
  });
  ```

### 验收
- [ ] `flutter test test/test_ri_jia_qi_men.dart` 全绿
- [ ] `RiJiaQiMen` 类覆盖率 ≥ 80%

---

## 整体验收

- [ ] P2-T1..P2-T7 全部子任务完成
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter test` 全绿（含日家专项 + 既有时家回归）
- [ ] 手工测试：MVVM Page 切换到日家，能起一个 2026-04-30 的盘
- [ ] 切换日家后再切回时家，状态正确重置
- [ ] AI Tool 暂可不接入；调用时若传 `jia: RI` 也能正常工作
- [ ] 日家盘的 brief 文案包含 "日家·" 前缀（依赖 P5-T3）

---

## 关键风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| §8.1 跳宫规则未定，方案 A/B 行为差异 | P2-T3, P2-T5 行为分歧 | TODO + 配置开关，P2-T1.1 评审后切换 |
| 八神字段在日家无意义（对照表 §七） | 复用时家伏吟反吟检测会误判 | `EachGong.god/diGod` 在日家盘填占位或在 `QiMenPan.jia == RI` 时跳过相关检测；完整黄道黑道喜神贵神留 Phase 6+ |
| 节气过渡日阴阳遁归属（§8.2） | 个别日盘错位 | 先按"节气当日属新节气"，标 TODO；fixture 必含 1 个边界用例 |
| 测试 fixture 缺真实日期 | P2-T7 无法验证 | P2-T1.2 是 P2-T7 强阻塞；建议先用 LunarAdapter 工具脚本批量生成候选 |
| `zhiFuStar` 字段在日家无意义 | `QiMenPan` 字段语义被污染 | 本期填占位（太乙）；Phase 6 再考虑改为 `QiMenStar?` |
| 9 星 → 8 宫的双星处理 | UI 渲染冲突 | 跳宫策略决定后落地，UI 在该宫位 stack 渲染 |

---

## 工作量分解

| 子任务 | 估算 |
| --- | --- |
| P2-T1（算法核对 + fixture 收集） | 0.5 人日（不含领域评审等待） |
| P2-T2 + P2-T2.5（实体 + 星集） | 0.3 人日 |
| P2-T3（计算器） | 0.5 人日 |
| P2-T4 + P2-T6（DataSource + Repo 接入） | 0.3 人日 |
| **P2-T5（独立排盘器，关键路径）** | **1 人日** |
| P2-T7（测试） | 0.4 人日 |
| **小计** | **3 人日** |

> 关键路径：P2-T1.1（领域评审） → P2-T3 → P2-T5。建议先启动 P2-T1.1 与领域专家对话，并行做 P2-T2/T2.5/T4 这些不依赖评审的工作。
