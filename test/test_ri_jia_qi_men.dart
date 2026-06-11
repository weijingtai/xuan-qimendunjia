import 'package:metaphysics_core/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/domain/entities/ri_jia_ju.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/enums/enum_ri_jia_stars.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/model/ri_jia_qi_men.dart';
import 'package:qimendunjia/model/shi_jia_qi_men.dart' show CenterGongJiGongType;
import 'package:qimendunjia/utils/ri_jia_qi_men_ju_calculator.dart';

/// 日家奇门单元测试
///
/// 算法依据：docs/more_qimen/ri_jia_algorithm.md
///         docs/more_qimen/qimen_jia_comparison.md
///
/// 权威 fixture（用户 2026-05-04 提供）：
///   休门兑7 + 太乙中5 ⇔ 阳遁 d=40 (甲辰日) 或 阴遁 d=32 (丙申日)
///   完整 9 宫期望分布见 [_userExample] 常量。
void main() {
  // ─────────────────────────────────────────────────────────
  // §1 RiJiaStarEnum 枚举完整性
  // ─────────────────────────────────────────────────────────
  group('RiJiaStarEnum', () {
    test('9 个枚举值 number 1-9 一一对应', () {
      final numbers = RiJiaStarEnum.values.map((e) => e.number).toList()
        ..sort();
      expect(numbers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('TAI_YI(1), TIAN_YI(9) 名称正确', () {
      expect(RiJiaStarEnum.TAI_YI.name, '太乙');
      expect(RiJiaStarEnum.TIAN_YI.name, '天乙');
      expect(RiJiaStarEnum.TIAN_YI.singleCharName, '天乙'); // 双字单字名
    });

    test('吉凶判定（用户 2026-05-04 校准）', () {
      // 吉星(4): 太乙、青龙、太阴、天乙
      expect(RiJiaStarEnum.TAI_YI.isJi, isTrue);
      expect(RiJiaStarEnum.QING_LONG.isJi, isTrue);
      expect(RiJiaStarEnum.TAI_YIN.isJi, isTrue);
      expect(RiJiaStarEnum.TIAN_YI.isJi, isTrue);

      // 中平(2): 天符、轩辕
      expect(RiJiaStarEnum.TIAN_FU.isPing, isTrue);
      expect(RiJiaStarEnum.XUAN_YUAN.isPing, isTrue);

      // 凶星(3): 摄提、招摇、咸池
      expect(RiJiaStarEnum.SHE_TI.isXiong, isTrue);
      expect(RiJiaStarEnum.ZHAO_YAO.isXiong, isTrue);
      expect(RiJiaStarEnum.XIAN_CHI.isXiong, isTrue);

      // 吉凶平互斥：每颗星恰好属于一类
      for (final star in RiJiaStarEnum.values) {
        final tags = [star.isJi, star.isPing, star.isXiong];
        final trueCount = tags.where((b) => b).length;
        expect(trueCount, 1,
            reason: '${star.name} 应恰好属于吉/中平/凶 一类，实际 isJi=${star.isJi} isPing=${star.isPing} isXiong=${star.isXiong}');
      }

      // 总数验证：9 = 4 + 2 + 3
      final jiCount = RiJiaStarEnum.values.where((s) => s.isJi).length;
      final pingCount = RiJiaStarEnum.values.where((s) => s.isPing).length;
      final xiongCount = RiJiaStarEnum.values.where((s) => s.isXiong).length;
      expect(jiCount, 4);
      expect(pingCount, 2);
      expect(xiongCount, 3);
    });

    test('日家星 originalGong / fiveXing 恒为 null（不参与伏吟反吟）', () {
      for (final star in RiJiaStarEnum.values) {
        expect(star.originalGong, isNull, reason: '${star.name} 应无原宫');
        expect(star.fiveXing, isNull, reason: '${star.name} 应无五行');
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // §2 RiJiaQiMenJuCalculator.calcXiuMenGong: 60 甲子全覆盖自检
  // ─────────────────────────────────────────────────────────
  group('RiJiaQiMenJuCalculator.calcXiuMenGong', () {
    /// 阳遁 §3 表的真值（来自 ri_jia_algorithm.md）
    /// key = 3 日组的首日柱名，value = 期望休门宫号
    const yangDunExpected = {
      // 坎 1
      '甲子': 1, '戊子': 1, '壬子': 1,
      // 坤 2
      '丁卯': 2, '辛卯': 2, '乙卯': 2,
      // 震 3
      '戊午': 3, '庚午': 3, '甲午': 3,
      // 巽 4
      '癸酉': 4, '丁酉': 4, '辛酉': 4,
      // 乾 6
      '庚子': 6, '丙子': 6,
      // 兑 7
      '己卯': 7, '癸卯': 7,
      // 艮 8
      '壬午': 8, '丙午': 8,
      // 离 9
      '乙酉': 9, '己酉': 9,
    };

    /// 阴遁 §3 表的真值
    const yinDunExpected = {
      // 离 9
      '甲子': 9, '戊子': 9, '壬子': 9,
      // 艮 8
      '丁卯': 8, '辛卯': 8, '乙卯': 8,
      // 兑 7
      '戊午': 7, '庚午': 7, '甲午': 7,
      // 乾 6
      '癸酉': 6, '丁酉': 6, '辛酉': 6,
      // 巽 4
      '庚子': 4, '丙子': 4,
      // 震 3
      '己卯': 3, '癸卯': 3,
      // 坤 2
      '壬午': 2, '丙午': 2,
      // 坎 1
      '乙酉': 1, '己酉': 1,
    };

    test('阳遁 20 个组首与文档表完全一致', () {
      yangDunExpected.forEach((name, expectedGong) {
        final jiazi = JiaZi.getFromGanZhiValue(name)!;
        final result = RiJiaQiMenJuCalculator.calcXiuMenGong(
            jiazi, YinYang.YANG);
        expect(result.houTianOrder, expectedGong,
            reason: '阳遁 $name 应落 $expectedGong 宫，实际 ${result.houTianOrder}');
      });
    });

    test('阴遁 20 个组首与文档表完全一致', () {
      yinDunExpected.forEach((name, expectedGong) {
        final jiazi = JiaZi.getFromGanZhiValue(name)!;
        final result = RiJiaQiMenJuCalculator.calcXiuMenGong(
            jiazi, YinYang.YIN);
        expect(result.houTianOrder, expectedGong,
            reason: '阴遁 $name 应落 $expectedGong 宫，实际 ${result.houTianOrder}');
      });
    });

    test('60 甲子日序覆盖率：每 3 日同宫，永不为 5', () {
      for (int n = 1; n <= 60; n++) {
        final jiazi = JiaZi.getByNumber(n);
        final yangGong = RiJiaQiMenJuCalculator.calcXiuMenGong(
            jiazi, YinYang.YANG);
        final yinGong = RiJiaQiMenJuCalculator.calcXiuMenGong(
            jiazi, YinYang.YIN);
        expect(yangGong, isNot(HouTianGua.Center),
            reason: '阳遁 ${jiazi.name} 不应落中5');
        expect(yinGong, isNot(HouTianGua.Center),
            reason: '阴遁 ${jiazi.name} 不应落中5');
      }
    });

    test('3 日同宫语义：同组 3 日同宫', () {
      // 甲子组(d=0,1,2) = 甲子/乙丑/丙寅 同落坎1（阳遁）
      for (final n in [1, 2, 3]) {
        final jiazi = JiaZi.getByNumber(n);
        expect(
            RiJiaQiMenJuCalculator.calcXiuMenGong(jiazi, YinYang.YANG)
                .houTianOrder,
            1);
      }
      // 癸卯组(d=39,40,41) = 癸卯/甲辰/乙巳 同落兑7（阳遁）— 含用户示例 d=40
      for (final n in [40, 41, 42]) {
        final jiazi = JiaZi.getByNumber(n);
        expect(
            RiJiaQiMenJuCalculator.calcXiuMenGong(jiazi, YinYang.YANG)
                .houTianOrder,
            7,
            reason: '癸卯组 $n (${jiazi.name}) 应落兑7');
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // §3 RiJiaQiMen 排盘器 —— 用户权威示例 (2026-05-04 乙丑日阳遁)
  // ─────────────────────────────────────────────────────────
  group('RiJiaQiMen — 用户权威示例 (乙丑日 阳遁)', () {
    /// 默认 PanArrangeSettings
    PanArrangeSettings _settings() => PanArrangeSettings(
          arrangeType: ArrangeType.CHAI_BU,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        );

    /// 构造 RiJiaJu —— 不走 LunarAdapter（绕开真实日期），直接给定核心字段
    RiJiaJu _buildJu({
      required JiaZi dayJiaZi,
      required YinYang yinYangDun,
      required HouTianGua xiuMenGong,
    }) {
      final daysSinceJiaZi = dayJiaZi.number - 1;
      return RiJiaJu(
        id: 'test-${dayJiaZi.name}',
        panDateTime: DateTime(2026, 5, 4),
        yinYangDun: yinYangDun,
        dayJiaZi: dayJiaZi,
        daysSinceJiaZi: daysSinceJiaZi,
        xiuMenGong: xiuMenGong,
        jieQiAt: TwentyFourJieQi.LI_XIA, // 占位
        fourZhuEightChar: '丙午 癸巳 ${dayJiaZi.name} 甲午',
      );
    }

    /// 用户 2026-05-04 权威示例:乙丑日,阳遁
    ///
    /// 引用原文:
    /// "以冬至后阳遁乙丑日九星落局为例:
    ///   离九宫起太乙,坎一宫摄提,坤二宫轩辕,震三宫招摇,巽四宫天符,
    ///   中五宫青龙,乾六宫咸池,兑七宫太阴,艮八宫天乙"
    ///
    /// **九星部分**:乙丑 d=1,n=0,i=1,起宫 = ((7+0+1)%9)+1 = 9(离9)
    /// 9 星顺排:9→1→2→3→4→5→6→7→8
    ///
    /// **八门部分**:乙丑 d=1 在甲子组(d=0,1,2),阳遁休门=坎1
    /// 乙是阴干,逆时针 [1,6,7,2,9,4,3,8],从坎1起:
    ///   1=休 6=生 7=伤 2=杜 9=景 4=死 3=惊 8=开
    ///
    /// gong → (star, door)
    const userExample = {
      1: ('摄提', '休门'),
      2: ('轩辕', '杜门'),
      3: ('招摇', '惊门'),
      4: ('天符', '死门'),
      5: ('青龙', null), // 中5无门
      6: ('咸池', '生门'),
      7: ('太阴', '伤门'),
      8: ('天乙', '开门'),
      9: ('太乙', '景门'),
    };

    test('乙丑日 阳遁 完整 9 宫分布', () {
      final ju = _buildJu(
        dayJiaZi: JiaZi.getFromGanZhiValue('乙丑')!,
        yinYangDun: YinYang.YANG,
        xiuMenGong: HouTianGua.Kan, // 甲子组阳遁休门坎1
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());

      userExample.forEach((gongNum, expected) {
        final gua = HouTianGua.getGua(gongNum);
        final gong = pan.gongMapper[gua]!;
        expect(gong.star.name, expected.$1,
            reason: '乙丑日 宫$gongNum 期望星 ${expected.$1}');
        if (expected.$2 != null) {
          expect(gong.door.name, expected.$2,
              reason: '乙丑日 宫$gongNum 期望门 ${expected.$2}');
        }
      });
    });

    test('占位字段：值符=太乙、值使=休门、伏吟反吟=false', () {
      final ju = _buildJu(
        dayJiaZi: JiaZi.getFromGanZhiValue('乙丑')!,
        yinYangDun: YinYang.YANG,
        xiuMenGong: HouTianGua.Kan,
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());
      expect(pan.zhiFuStar, RiJiaStarEnum.TAI_YI);
      expect(pan.zhiFuStarAtGong, HouTianGua.Li); // 乙丑太乙在离9
      expect(pan.zhiShiDoor, EightDoorEnum.XIU);
      expect(pan.zhiShiDoorAtGong, HouTianGua.Kan);
    });

    test('gongMapper 含完整 9 宫（含中5）', () {
      final ju = _buildJu(
        dayJiaZi: JiaZi.getFromGanZhiValue('甲子')!,
        yinYangDun: YinYang.YANG,
        xiuMenGong: HouTianGua.Kan,
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());
      expect(pan.gongMapper.length, 9);
      expect(pan.gongMapper.keys, contains(HouTianGua.Center));
    });
  });

  // ─────────────────────────────────────────────────────────
  // §4 RiJiaQiMen.九星排布 - 旬头驱动 + 阴阳遁顺逆
  // ─────────────────────────────────────────────────────────
  group('RiJiaQiMen.九星排布', () {
    PanArrangeSettings _settings() => PanArrangeSettings(
          arrangeType: ArrangeType.CHAI_BU,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        );

    test('6 个旬头的太乙起宫(阳遁)', () {
      // 甲子=艮8, 甲戌=离9, 甲申=坎1, 甲午=坤2, 甲辰=震3, 甲寅=巽4
      final cases = {
        '甲子': HouTianGua.Gen,
        '甲戌': HouTianGua.Li,
        '甲申': HouTianGua.Kan,
        '甲午': HouTianGua.Kun,
        '甲辰': HouTianGua.Zhen,
        '甲寅': HouTianGua.Xun,
      };
      cases.forEach((name, expectedGong) {
        final jz = JiaZi.getFromGanZhiValue(name)!;
        expect(RiJiaQiMen.taiYiQiGong(jz, YinYang.YANG), expectedGong,
            reason: '阳遁 $name 期望太乙在 ${expectedGong.name}');
      });
    });

    test('6 个旬头的太乙起宫(阴遁)', () {
      // 甲子=坤2, 甲戌=坎1, 甲申=离9, 甲午=艮8, 甲辰=兑7, 甲寅=乾6
      final cases = {
        '甲子': HouTianGua.Kun,
        '甲戌': HouTianGua.Kan,
        '甲申': HouTianGua.Li,
        '甲午': HouTianGua.Gen,
        '甲辰': HouTianGua.Dui,
        '甲寅': HouTianGua.Qian,
      };
      cases.forEach((name, expectedGong) {
        final jz = JiaZi.getFromGanZhiValue(name)!;
        expect(RiJiaQiMen.taiYiQiGong(jz, YinYang.YIN), expectedGong,
            reason: '阴遁 $name 期望太乙在 ${expectedGong.name}');
      });
    });

    test('阳遁甲子旬旬内每天起宫 +1（顺移）', () {
      // 甲子=8, 乙丑=9, 丙寅=1, 丁卯=2, 戊辰=3, 己巳=4, 庚午=5(中), 辛未=6, 壬申=7, 癸酉=8(旬末同旬头)
      final expected = {
        '甲子': 8, '乙丑': 9, '丙寅': 1, '丁卯': 2, '戊辰': 3,
        '己巳': 4, '庚午': 5, '辛未': 6, '壬申': 7, '癸酉': 8,
      };
      expected.forEach((name, gongNum) {
        final jz = JiaZi.getFromGanZhiValue(name)!;
        expect(RiJiaQiMen.taiYiQiGong(jz, YinYang.YANG).houTianOrder, gongNum,
            reason: '阳遁 $name 期望起宫 $gongNum');
      });
    });

    test('阴遁甲子旬旬内每天起宫 -1（逆移）', () {
      // 甲子=2, 乙丑=1, 丙寅=9, 丁卯=8, 戊辰=7, 己巳=6, 庚午=5(中), 辛未=4, 壬申=3, 癸酉=2(旬末同旬头)
      final expected = {
        '甲子': 2, '乙丑': 1, '丙寅': 9, '丁卯': 8, '戊辰': 7,
        '己巳': 6, '庚午': 5, '辛未': 4, '壬申': 3, '癸酉': 2,
      };
      expected.forEach((name, gongNum) {
        final jz = JiaZi.getFromGanZhiValue(name)!;
        expect(RiJiaQiMen.taiYiQiGong(jz, YinYang.YIN).houTianOrder, gongNum,
            reason: '阴遁 $name 期望起宫 $gongNum');
      });
    });

    test('旬末癸日与旬头甲日同宫,下一旬头再 +1/-1', () {
      // 阳遁:癸酉(d=9)=8 == 甲子(d=0)=8;  甲戌(d=10)=9 (下一宫)
      expect(
          RiJiaQiMen.taiYiQiGong(
                  JiaZi.getFromGanZhiValue('癸酉')!, YinYang.YANG)
              .houTianOrder,
          8);
      expect(
          RiJiaQiMen.taiYiQiGong(
                  JiaZi.getFromGanZhiValue('甲戌')!, YinYang.YANG)
              .houTianOrder,
          9);
      // 阴遁同理
      expect(
          RiJiaQiMen.taiYiQiGong(
                  JiaZi.getFromGanZhiValue('癸酉')!, YinYang.YIN)
              .houTianOrder,
          2);
      expect(
          RiJiaQiMen.taiYiQiGong(
                  JiaZi.getFromGanZhiValue('甲戌')!, YinYang.YIN)
              .houTianOrder,
          1);
    });

    /// 给定日柱与阴阳遁,构造一个最小 ju 并返回 9 星 → 宫号映射
    Map<RiJiaStarEnum, int> _starGongMap({
      required JiaZi dayJiaZi,
      required YinYang yinYangDun,
      required HouTianGua xiuMenGong,
    }) {
      final ju = RiJiaJu(
        id: 'star-test',
        panDateTime: DateTime(2026),
        yinYangDun: yinYangDun,
        dayJiaZi: dayJiaZi,
        daysSinceJiaZi: dayJiaZi.number - 1,
        xiuMenGong: xiuMenGong,
        jieQiAt: TwentyFourJieQi.DONG_ZHI,
        fourZhuEightChar: '甲子 丙子 ${dayJiaZi.name} 甲子',
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());
      return {
        for (final entry in pan.gongMapper.entries)
          entry.value.star as RiJiaStarEnum: entry.value.gongNumber,
      };
    }

    test('阳遁乙丑(spec 主例):太乙在离9,顺排', () {
      final map = _starGongMap(
        dayJiaZi: JiaZi.getFromGanZhiValue('乙丑')!,
        yinYangDun: YinYang.YANG,
        xiuMenGong: HouTianGua.Kan,
      );
      // 太乙=9 摄提=1 轩辕=2 招摇=3 天符=4 青龙=5(中) 咸池=6 太阴=7 天乙=8
      expect(map[RiJiaStarEnum.TAI_YI], 9);
      expect(map[RiJiaStarEnum.SHE_TI], 1);
      expect(map[RiJiaStarEnum.XUAN_YUAN], 2);
      expect(map[RiJiaStarEnum.ZHAO_YAO], 3);
      expect(map[RiJiaStarEnum.TIAN_FU], 4);
      expect(map[RiJiaStarEnum.QING_LONG], 5);
      expect(map[RiJiaStarEnum.XIAN_CHI], 6);
      expect(map[RiJiaStarEnum.TAI_YIN], 7);
      expect(map[RiJiaStarEnum.TIAN_YI], 8);
    });

    test('阴遁甲子(spec 主例):太乙在坤2,逆排', () {
      // spec 引文:"如甲子日坤宫太乙,坎宫摄提,离宫轩辕,艮宫招摇,
      //           兑宫天符,乾宫青龙,中宫咸池,巽宫太阴,震宫天乙"
      final map = _starGongMap(
        dayJiaZi: JiaZi.getFromGanZhiValue('甲子')!,
        yinYangDun: YinYang.YIN,
        xiuMenGong: HouTianGua.Li, // 阴遁甲子组休门离9
      );
      expect(map[RiJiaStarEnum.TAI_YI], 2);
      expect(map[RiJiaStarEnum.SHE_TI], 1);
      expect(map[RiJiaStarEnum.XUAN_YUAN], 9);
      expect(map[RiJiaStarEnum.ZHAO_YAO], 8);
      expect(map[RiJiaStarEnum.TIAN_FU], 7);
      expect(map[RiJiaStarEnum.QING_LONG], 6);
      expect(map[RiJiaStarEnum.XIAN_CHI], 5);
      expect(map[RiJiaStarEnum.TAI_YIN], 4);
      expect(map[RiJiaStarEnum.TIAN_YI], 3);
    });

    test('阳遁庚午(d=6,旬内中位):太乙在中5', () {
      // 公式: ((7+0+6)%9)+1 = 13%9+1 = 4+1 = 5
      final map = _starGongMap(
        dayJiaZi: JiaZi.getFromGanZhiValue('庚午')!,
        yinYangDun: YinYang.YANG,
        xiuMenGong: HouTianGua.Zhen, // 庚午组阳遁休门震3
      );
      expect(map[RiJiaStarEnum.TAI_YI], 5,
          reason: '太乙应在中5(阳遁庚午顺排基准点)');
      expect(map[RiJiaStarEnum.SHE_TI], 6);
      expect(map[RiJiaStarEnum.TIAN_YI], 4); // 9 颗后回到 4
    });
  });

  // ─────────────────────────────────────────────────────────
  // §5 RiJiaQiMen.八门排布 - 阳干 vs 阴干
  // ─────────────────────────────────────────────────────────
  group('RiJiaQiMen.八门排布', () {
    PanArrangeSettings _settings() => PanArrangeSettings(
          arrangeType: ArrangeType.CHAI_BU,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        );

    test('阳干甲辰：从兑7=休出发，顺时针 [7,6,1,8,3,4,9,2]', () {
      final ju = RiJiaJu(
        id: 'test',
        panDateTime: DateTime(2026),
        yinYangDun: YinYang.YANG,
        dayJiaZi: JiaZi.getFromGanZhiValue('甲辰')!,
        daysSinceJiaZi: 40,
        xiuMenGong: HouTianGua.Dui,
        jieQiAt: TwentyFourJieQi.LI_XIA,
        fourZhuEightChar: '丙午 癸巳 甲辰 甲子',
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());
      // 阳干甲辰，path = [1,8,3,4,9,2,7,6] 顺时针，从兑7 起
      // path.indexOf(7)=6，依次填: 7(休) 6(生) 1(伤) 8(杜) 3(景) 4(死) 9(惊) 2(开)
      const expected = {
        7: '休门', 6: '生门', 1: '伤门', 8: '杜门',
        3: '景门', 4: '死门', 9: '惊门', 2: '开门',
      };
      expected.forEach((gongNum, doorName) {
        expect(pan.gongMapper[HouTianGua.getGua(gongNum)]!.door.name, doorName,
            reason: '阳干甲辰 宫$gongNum');
      });
    });

    test('阴干日(乙卯)：八门反向（与阳干对称，逆时针）', () {
      // 乙卯 jiazi.number=52, 阳遁 group_index=17 → cycle[17%8=1]=2 → 坤2
      final dayJiaZi = JiaZi.getFromGanZhiValue('乙卯')!;
      final ju = RiJiaJu(
        id: 'test',
        panDateTime: DateTime(2026),
        yinYangDun: YinYang.YANG,
        dayJiaZi: dayJiaZi,
        daysSinceJiaZi: dayJiaZi.number - 1,
        xiuMenGong: HouTianGua.Kun, // 阳遁乙卯组休门坤2
        jieQiAt: TwentyFourJieQi.LI_XIA,
        fourZhuEightChar: '甲子 丙子 乙卯 甲子',
      );
      final pan = RiJiaQiMen(ju: ju, settings: _settings());
      // 乙是阴干 → path = [1,6,7,2,9,4,3,8] 逆时针
      // path.indexOf(2)=3，从 idx=3 起: 2(休) 9(生) 4(伤) 3(杜) 8(景) 1(死) 6(惊) 7(开)
      const expected = {
        2: '休门', 9: '生门', 4: '伤门', 3: '杜门',
        8: '景门', 1: '死门', 6: '惊门', 7: '开门',
      };
      expected.forEach((gongNum, doorName) {
        expect(pan.gongMapper[HouTianGua.getGua(gongNum)]!.door.name, doorName,
            reason: '阴干乙卯 宫$gongNum');
      });
    });
  });

  // ─────────────────────────────────────────────────────────
  // §6 BaseJu 接口契约
  // ─────────────────────────────────────────────────────────
  group('RiJiaJu BaseJu 契约', () {
    test('jia 恒为 RI', () {
      final ju = RiJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 5, 4),
        yinYangDun: YinYang.YANG,
        dayJiaZi: JiaZi.getByNumber(1),
        daysSinceJiaZi: 0,
        xiuMenGong: HouTianGua.Kan,
        jieQiAt: TwentyFourJieQi.LI_CHUN,
        fourZhuEightChar: '甲子 丙寅 甲子 甲子',
      );
      expect(ju.jia, QiMenJia.RI);
    });

    test('juNumber = xiuMenGong.houTianOrder', () {
      final ju = RiJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 5, 4),
        yinYangDun: YinYang.YANG,
        dayJiaZi: JiaZi.getByNumber(1),
        daysSinceJiaZi: 0,
        xiuMenGong: HouTianGua.Dui,
        jieQiAt: TwentyFourJieQi.LI_CHUN,
        fourZhuEightChar: '甲子 丙寅 甲子 甲子',
      );
      expect(ju.juNumber, 7);
    });

    test('断言：daysSinceJiaZi 必须 [0, 59]', () {
      expect(
          () => RiJiaJu(
                id: 'test',
                panDateTime: DateTime(2026),
                yinYangDun: YinYang.YANG,
                dayJiaZi: JiaZi.getByNumber(1),
                daysSinceJiaZi: 60, // 越界
                xiuMenGong: HouTianGua.Kan,
                jieQiAt: TwentyFourJieQi.DONG_ZHI,
                fourZhuEightChar: '',
              ),
          throwsA(isA<AssertionError>()));
    });

    test('断言：xiuMenGong 不能为中5', () {
      expect(
          () => RiJiaJu(
                id: 'test',
                panDateTime: DateTime(2026),
                yinYangDun: YinYang.YANG,
                dayJiaZi: JiaZi.getByNumber(1),
                daysSinceJiaZi: 0,
                xiuMenGong: HouTianGua.Center, // 中5无休门
                jieQiAt: TwentyFourJieQi.DONG_ZHI,
                fourZhuEightChar: '',
              ),
          throwsA(isA<AssertionError>()));
    });
  });
}
