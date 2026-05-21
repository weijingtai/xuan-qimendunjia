import 'package:common/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';
import 'package:qimendunjia/model/ke_jia_qi_men_pan.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/model/shi_jia_qi_men.dart';
import 'package:qimendunjia/utils/ke_jia_qi_men_ju_calculator.dart';

/// 刻家奇门单元测试
///
/// 算法依据：用户 spec 2026-05-05
/// - 刻家奇门以 12 分钟为一局，一时辰 10 局
/// - 初局沿用本时辰时家局；二局起阳顺阴逆
/// - 刻干阳干（甲丙戊庚壬）→ 阳遁；阴干（乙丁己辛癸）→ 阴遁
/// - 阳遁示例：初局甲子戊在坎一(1) → 二局坤二(2) → 三局震三(3) → 四局巽四(4)
/// - 阴遁示例：初局坎一(1) → 二局离九(9) → 三局艮八(8) → 四局兑七(7)
void main() {
  // ─────────────────────────────────────────────────────────
  // §1 calcShiChenStart: 时辰起始时间计算
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenJuCalculator.calcShiChenStart', () {
    test('子时（h=23）→ 当日 23:00', () {
      final dt = DateTime(2026, 5, 5, 23, 30);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 23, 0));
    });

    test('子时（h=0）→ 前日 23:00', () {
      final dt = DateTime(2026, 5, 5, 0, 30);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 4, 23, 0));
    });

    test('丑时（h=1）→ 当日 01:00', () {
      final dt = DateTime(2026, 5, 5, 1, 0);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 1, 0));
    });

    test('丑时（h=2）→ 当日 01:00', () {
      final dt = DateTime(2026, 5, 5, 2, 30);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 1, 0));
    });

    test('午时（h=11）→ 当日 11:00', () {
      final dt = DateTime(2026, 5, 5, 11, 0);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 11, 0));
    });

    test('午时（h=12）→ 当日 11:00', () {
      final dt = DateTime(2026, 5, 5, 12, 59);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 11, 0));
    });

    test('亥时（h=22）→ 当日 21:00', () {
      final dt = DateTime(2026, 5, 5, 22, 30);
      final start = KeJiaQiMenJuCalculator.calcShiChenStart(dt);
      expect(start, DateTime(2026, 5, 5, 21, 0));
    });
  });

  // ─────────────────────────────────────────────────────────
  // §2 calcKeIndex: 刻局序号
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenJuCalculator.calcKeIndex', () {
    test('时辰起始 → 第 1 刻', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(KeJiaQiMenJuCalculator.calcKeIndex(start, start), 1);
    });

    test('起始 + 11 min → 第 1 刻', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            start.add(const Duration(minutes: 11)), start),
        1,
      );
    });

    test('起始 + 12 min → 第 2 刻', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            start.add(const Duration(minutes: 12)), start),
        2,
      );
    });

    test('起始 + 60 min → 第 6 刻', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            start.add(const Duration(minutes: 60)), start),
        6,
      );
    });

    test('起始 + 119 min → 第 10 刻', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            start.add(const Duration(minutes: 119)), start),
        10,
      );
    });

    test('超出 120 min 抛错', () {
      final start = DateTime(2026, 5, 5, 11);
      expect(
        () => KeJiaQiMenJuCalculator.calcKeIndex(
            start.add(const Duration(minutes: 120)), start),
        throwsStateError,
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // §3 calcKeJiaZi: 刻干支推算
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenJuCalculator.calcKeJiaZi', () {
    test('子时 JIA_ZI + 第1刻 → JIA_ZI', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(JiaZi.JIA_ZI, 1),
        JiaZi.JIA_ZI,
      );
    });

    test('子时 JIA_ZI + 第10刻 → GUI_YOU', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(JiaZi.JIA_ZI, 10),
        JiaZi.GUI_YOU,
      );
    });

    test('丑时 YI_CHOU + 第1刻 → JIA_XU', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(JiaZi.YI_CHOU, 1),
        JiaZi.JIA_XU,
      );
    });

    test('丑时 YI_CHOU + 第10刻 → GUI_WEI', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(JiaZi.YI_CHOU, 10),
        JiaZi.GUI_WEI,
      );
    });

    test('循环：60 时辰 × 10 刻 = 600 = 10 个甲子周期', () {
      // 第 60 时辰 + 第 10 刻 应回到 GUI_HAI
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(JiaZi.GUI_HAI, 10),
        // (59 * 10 + 9) mod 60 + 1 = 599 mod 60 + 1 = 59 + 1 = 60 → GUI_HAI
        JiaZi.GUI_HAI,
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // §4 calcShiftedJuNumber: 局推移
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenJuCalculator.calcShiftedJuNumber', () {
    test('阳遁初局（initJu=1, k=1）→ 1（坎一）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 1, YinYang.YANG),
        1,
      );
    });

    test('阳遁二局（initJu=1, k=2）→ 2（坤二）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 2, YinYang.YANG),
        2,
      );
    });

    test('阳遁三局（initJu=1, k=3）→ 3（震三）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 3, YinYang.YANG),
        3,
      );
    });

    test('阳遁四局（initJu=1, k=4）→ 4（巽四）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 4, YinYang.YANG),
        4,
      );
    });

    test('阳遁全周（initJu=1, k=10）→ 1（绕回坎一）', () {
      // (1-1+9) mod 9 + 1 = 0 + 1 = 1
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 10, YinYang.YANG),
        1,
      );
    });

    test('阴遁初局（initJu=1, k=1）→ 1（坎一）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 1, YinYang.YIN),
        1,
      );
    });

    test('阴遁二局（initJu=1, k=2）→ 9（离九）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 2, YinYang.YIN),
        9,
      );
    });

    test('阴遁三局（initJu=1, k=3）→ 8（艮八）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 3, YinYang.YIN),
        8,
      );
    });

    test('阴遁四局（initJu=1, k=4）→ 7（兑七）', () {
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(1, 4, YinYang.YIN),
        7,
      );
    });

    test('阳遁不同初局：initJu=5, k=2 → 6', () {
      // (5-1+1) mod 9 + 1 = 5 + 1 = 6
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(5, 2, YinYang.YANG),
        6,
      );
    });

    test('阳遁跨循环：initJu=8, k=3 → 1（绕回）', () {
      // (8-1+2) mod 9 + 1 = 9 mod 9 + 1 = 1
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(8, 3, YinYang.YANG),
        1,
      );
    });

    test('阴遁跨循环：initJu=2, k=3 → 9', () {
      // (2-1-2) mod 9 + 1 = (-1 mod 9 → 8) + 1 = 9
      expect(
        KeJiaQiMenJuCalculator.calcShiftedJuNumber(2, 3, YinYang.YIN),
        9,
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // §5 完整计算：calculate() 综合验证
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenJuCalculator.calculate', () {
    test('返回 KeJiaJu 类型与基本字段不为空', () {
      final dt = DateTime(2026, 5, 5, 11, 6); // 午时第 1 刻
      final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();

      expect(ju, isA<KeJiaJu>());
      expect(ju.jia, QiMenJia.KE);
      expect(ju.panDateTime, dt);
      expect(ju.keIndex, 1);
      expect(ju.juNumber, ju.initJuNumber); // 初局 = 时家初局
      expect(ju.fourZhuEightChar.split(' ').length, 4);
    });

    test('刻干阴阳决定 yinYangDun', () {
      // 取一个能稳定起到阳干刻的时间：12 min/刻，干支编号决定阴阳
      // 简单方式：在多个 keIndex 中验证 ju.yinYangDun 与 ju.keJiaZi.gan.yinYang 一致
      for (int minute = 0; minute < 120; minute += 12) {
        final dt = DateTime(2026, 5, 5, 11, minute);
        final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();
        expect(
          ju.yinYangDun,
          ju.keJiaZi.gan.yinYang,
          reason:
              '第 ${ju.keIndex} 刻：刻干 ${ju.keJiaZi.gan.name}（${ju.keJiaZi.gan.yinYang.name}），但 yinYangDun=${ju.yinYangDun.name}',
        );
      }
    });

    test('同一时辰内 10 个刻局的甲子戊宫位严格按推移规则', () {
      final shiChenStart = DateTime(2026, 5, 5, 11);
      // 拿第 1 刻的 ju 作为 baseline
      final base = KeJiaQiMenJuCalculator(
        dateTime: shiChenStart,
      ).calculate();
      final initJu = base.initJuNumber;

      for (int k = 1; k <= 10; k++) {
        final dt = shiChenStart.add(Duration(minutes: 12 * (k - 1)));
        final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();
        final expected = KeJiaQiMenJuCalculator.calcShiftedJuNumber(
          initJu,
          k,
          ju.yinYangDun,
        );
        expect(
          ju.juNumber,
          expected,
          reason: '第 $k 刻应为局 $expected，实际 ${ju.juNumber}',
        );
      }
    });

    test('四柱第4柱 = 刻干支名（替代时干支）', () {
      final dt = DateTime(2026, 5, 5, 11, 30); // 午时第 3 刻
      final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();
      final fourthZhu = ju.fourZhuEightChar.split(' ').last;
      expect(fourthZhu, ju.keJiaZi.name);
    });
  });

  // ─────────────────────────────────────────────────────────
  // §6 用户文档示例验证
  // ─────────────────────────────────────────────────────────
  group('用户 spec 示例验证', () {
    test('阳遁示例：1→2→3→4 顺移', () {
      // 模拟"阳初局甲子戊在坎一" 设 initJu = 1
      const initJu = 1;
      final results = <int>[];
      for (int k = 1; k <= 4; k++) {
        results.add(KeJiaQiMenJuCalculator.calcShiftedJuNumber(
          initJu,
          k,
          YinYang.YANG,
        ));
      }
      expect(results, [1, 2, 3, 4]);
    });

    test('阴遁示例：1→9→8→7 逆移', () {
      const initJu = 1;
      final results = <int>[];
      for (int k = 1; k <= 4; k++) {
        results.add(KeJiaQiMenJuCalculator.calcShiftedJuNumber(
          initJu,
          k,
          YinYang.YIN,
        ));
      }
      expect(results, [1, 9, 8, 7]);
    });
  });

  // ─────────────────────────────────────────────────────────
  // §7 ArrangeType 枚举完整性（DataSource 可被任意 ArrangeType 取到）
  // ─────────────────────────────────────────────────────────
  test('ArrangeType 全集均可路由（间接验证 DI 已注册）', () {
    // 仅验证枚举枚举完整性；实际 DI 由 service_locator_test 覆盖
    expect(ArrangeType.values, isNotEmpty);
    expect(QiMenJia.KE.name, '刻家');
  });

  // ─────────────────────────────────────────────────────────
  // §7.5 五马遁 (八刻方案) — calcKeJiaZi / calcKeIndex 双方案派发
  // ─────────────────────────────────────────────────────────
  group('五马遁 (八刻方案)', () {
    test('五马遁映射：甲己时第1刻 → 甲子', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.JIA_ZI, 1),
        JiaZi.JIA_ZI,
      );
      // 己时（己丑→YI_CHOU 是乙丑；己时如己卯=number 16 是己卯；这里随便取一个己干时辰：JI_SI = 6）
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.JI_SI, 1),
        JiaZi.JIA_ZI,
        reason: '己时第一刻应为甲子',
      );
    });

    test('五马遁映射：乙庚时第1刻 → 丙子', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.YI_CHOU, 1),
        JiaZi.BING_ZI,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.GENG_WU, 1),
        JiaZi.BING_ZI,
      );
    });

    test('五马遁映射：丙辛时第1刻 → 戊子', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.BING_YIN, 1),
        JiaZi.WU_ZI,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.XIN_WEI, 1),
        JiaZi.WU_ZI,
      );
    });

    test('五马遁映射：丁壬时第1刻 → 庚子', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.DING_MAO, 1),
        JiaZi.GENG_ZI,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.REN_SHEN, 1),
        JiaZi.GENG_ZI,
      );
    });

    test('五马遁映射：戊癸时第1刻 → 壬子', () {
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.WU_CHEN, 1),
        JiaZi.REN_ZI,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.GUI_YOU, 1),
        JiaZi.REN_ZI,
      );
    });

    test('甲子时8刻顺数 → 辛未', () {
      // 甲子(1) → 乙丑 → ... → 辛未(8)
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.JIA_ZI, 8),
        JiaZi.XIN_WEI,
      );
    });

    test('戊午时8刻顺数 → 己未', () {
      // 戊癸时起壬子(49) → 癸丑 → 甲寅 → 乙卯 → 丙辰 → 丁巳 → 戊午 → 己未(56)
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.WU_WU, 8),
        JiaZi.JI_WEI,
      );
    });

    test('癸亥时8刻顺数 → 己未（与戊午时同结果）', () {
      // 戊癸时起壬子(49)，无论时辰干支具体什么——只要时干是癸都从壬子起
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZiWuMaDun(JiaZi.GUI_HAI, 8),
        JiaZi.JI_WEI,
      );
    });

    test('calcKeIndex 8刻方案：分钟差边界', () {
      final start = DateTime(2026, 5, 6, 15);
      const scheme = KeSchemeType.EIGHT_KE_WU_MA_DUN;
      // 第 1 刻：[0, 15)
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 6, 15, 0), start, scheme),
        1,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 6, 15, 14), start, scheme),
        1,
      );
      // 第 2 刻：[15, 30)
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 6, 15, 15), start, scheme),
        2,
      );
      // 第 8 刻：[105, 120)
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 6, 16, 59), start, scheme),
        8,
      );
    });

    test('calcKeIndex 8刻方案：120 分钟越界抛 StateError', () {
      final start = DateTime(2026, 5, 6, 15);
      expect(
        () => KeJiaQiMenJuCalculator.calcKeIndex(
          DateTime(2026, 5, 6, 17, 0),
          start,
          KeSchemeType.EIGHT_KE_WU_MA_DUN,
        ),
        throwsStateError,
      );
    });

    test('calcKeJiaZi 派发：scheme=TEN_KE 走五子建元', () {
      // 甲子时(1) + 第6刻 → 五子建元 = ((1-1)*10 + 5) % 60 + 1 = 6 → JI_SI
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(
            JiaZi.JIA_ZI, 6, KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN),
        JiaZi.JI_SI,
      );
    });

    test('calcKeJiaZi 派发：scheme=EIGHT_KE 走五马遁', () {
      // 甲子时 + 第6刻 → 五马遁 = 甲子(1) + 5 → 己巳(6)
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(
            JiaZi.JIA_ZI, 6, KeSchemeType.EIGHT_KE_WU_MA_DUN),
        JiaZi.JI_SI,
      );
      // 戊午时 + 第6刻 → 五马遁 = 壬子(49) + 5 → 丁巳(54)
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(
            JiaZi.WU_WU, 6, KeSchemeType.EIGHT_KE_WU_MA_DUN),
        JiaZi.DING_SI,
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // §7.6 calculate() · 8 刻方案 端到端验证
  //
  // 用例：2026-05-06 16:05（申时甲申，时干甲）
  // - shiJiaZi = 甲申 (number=21)
  // - 时辰起点 = 15:00；分钟差 = 65
  // - keIndex = (65 ÷ 15) + 1 = 5
  // - 五马遁：甲己时起甲子(1)；keJiaZi = ((1-1)+(5-1))%60+1 = 5 → 戊辰
  // - 戊为阳干 → yinYangDun = YANG
  // ─────────────────────────────────────────────────────────
  group('calculate() · 8 刻方案', () {
    test('2026-05-06 16:05 → keIndex=5、刻柱=戊辰、阳遁', () {
      final dt = DateTime(2026, 5, 6, 16, 5);
      final ju = KeJiaQiMenJuCalculator(
        dateTime: dt,
        keScheme: KeSchemeType.EIGHT_KE_WU_MA_DUN,
      ).calculate();

      expect(ju.keIndex, 5, reason: '8 刻方案 keIndex 应为 5');
      expect(ju.shiJiaZi, JiaZi.JIA_SHEN);
      expect(ju.keJiaZi, JiaZi.WU_CHEN, reason: '五马遁 keJiaZi 应为戊辰');
      expect(ju.keScheme, KeSchemeType.EIGHT_KE_WU_MA_DUN);
      expect(ju.totalKeCount, 8);
      expect(ju.yinYangDun, YinYang.YANG, reason: '戊为阳干 → 阳遁');
      // 局推移：阳遁 ((initJu-1+(keIndex-1)) mod 9)+1
      final expectedJu = ((ju.initJuNumber - 1 + 4) % 9) + 1;
      expect(ju.juNumber, expectedJu);
      expect(ju.fourZhuEightChar.split(' ').last, JiaZi.WU_CHEN.name);
    });

    test('2026-05-06 16:05 默认入口（不传 keScheme）→ 走 10 刻方案', () {
      final dt = DateTime(2026, 5, 6, 16, 5);
      final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();

      expect(ju.keScheme, KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN);
      expect(ju.totalKeCount, 10);
      expect(ju.keIndex, 6, reason: '10 刻方案 (65÷12)+1=6');
      expect(ju.keJiaZi, JiaZi.JI_CHOU, reason: '五子建元 ((21-1)*10+5)%60+1=26 → 己丑');
    });
  });

  // ─────────────────────────────────────────────────────────
  // §7.7 60 刻·60 甲子方案（每刻 2 分钟，每时辰起甲子，与时柱解耦）
  // ─────────────────────────────────────────────────────────
  group('60 刻·60 甲子方案', () {
    test('每时辰第 1 刻恒为甲子（与时柱无关）', () {
      // 时柱无论是什么，第 1 刻都是甲子
      expect(KeJiaQiMenJuCalculator.calcKeJiaZiLiuShiJiaZi(1), JiaZi.JIA_ZI);
    });

    test('第 20 刻 → 癸未（用户 spec 锚点）', () {
      expect(KeJiaQiMenJuCalculator.calcKeJiaZiLiuShiJiaZi(20), JiaZi.GUI_WEI);
    });

    test('第 60 刻 → 癸亥（一时辰末刻 = 60甲子末位）', () {
      expect(KeJiaQiMenJuCalculator.calcKeJiaZiLiuShiJiaZi(60), JiaZi.GUI_HAI);
    });

    test('calcKeJiaZi 派发：scheme=SIXTY_KE 走 60 甲子', () {
      // 任何 shiJiaZi 都不影响结果
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(
            JiaZi.JIA_ZI, 20, KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI),
        JiaZi.GUI_WEI,
      );
      expect(
        KeJiaQiMenJuCalculator.calcKeJiaZi(
            JiaZi.YI_SI, 20, KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI),
        JiaZi.GUI_WEI,
        reason: '时柱 ≠ 影响因子（与 8/10 刻方案不同）',
      );
    });

    test('calcKeIndex 60 刻方案：分钟差边界', () {
      final start = DateTime(2026, 5, 8, 9);
      const scheme = KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI;
      // 09:00 → 第 1 刻
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 8, 9, 0), start, scheme),
        1,
      );
      // 09:01 仍属第 1 刻 (两分钟一刻 [0, 2))
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 8, 9, 1), start, scheme),
        1,
      );
      // 09:02 进入第 2 刻
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 8, 9, 2), start, scheme),
        2,
      );
      // 09:39 → 第 20 刻
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 8, 9, 39), start, scheme),
        20,
      );
      // 10:58 → 第 60 刻 (118÷2+1)
      expect(
        KeJiaQiMenJuCalculator.calcKeIndex(
            DateTime(2026, 5, 8, 10, 58), start, scheme),
        60,
      );
    });

    test('端到端：2026-05-08 09:39 → keIndex=20、刻柱=癸未', () {
      final dt = DateTime(2026, 5, 8, 9, 39);
      final ju = KeJiaQiMenJuCalculator(
        dateTime: dt,
        keScheme: KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI,
      ).calculate();

      expect(ju.keIndex, 20, reason: '60 刻方案 (39÷2)+1=20');
      expect(ju.shiJiaZi, JiaZi.YI_SI, reason: '壬日巳时 = 乙巳');
      expect(ju.keJiaZi, JiaZi.GUI_WEI, reason: '60 刻方案第 20 刻 = 癸未');
      expect(ju.keScheme, KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI);
      expect(ju.totalKeCount, 60);
      // 癸为阴干 → 阴遁
      expect(ju.yinYangDun, YinYang.YIN, reason: '癸为阴干 → 阴遁');
      // 局推移：阴遁 ((initJu-1-(keIndex-1)) mod 9)+1
      final expectedJu = (((ju.initJuNumber - 1 - 19) % 9) + 9) % 9 + 1;
      expect(ju.juNumber, expectedJu);
      expect(ju.fourZhuEightChar.split(' ').last, JiaZi.GUI_WEI.name);
    });
  });

  // ─────────────────────────────────────────────────────────
  // §7.8 拆补法符头派别（甲己作符 vs 仅甲作符）
  //
  // 5/7 辛巳日（number=18）这一天恰好是两派分歧点：
  // - 甲己作符：上一甲己日 = 5/5 己卯 → 卯=上元 → 立夏上元 = 阳遁4局
  // - 仅甲作符：上一甲日   = 4/30 甲戌 → 戌=下元 → 立夏下元 = 阳遁7局
  // ─────────────────────────────────────────────────────────
  group('拆补法符头派别', () {
    test('computeJiaOnlyFuTou：辛巳(18) → 甲戌(11)', () {
      expect(
        KeJiaQiMenJuCalculator.computeJiaOnlyFuTou(JiaZi.XIN_SI),
        JiaZi.JIA_XU,
      );
    });

    test('computeJiaOnlyFuTou：甲日为符头自身', () {
      expect(
        KeJiaQiMenJuCalculator.computeJiaOnlyFuTou(JiaZi.JIA_ZI),
        JiaZi.JIA_ZI,
      );
      expect(
        KeJiaQiMenJuCalculator.computeJiaOnlyFuTou(JiaZi.JIA_SHEN),
        JiaZi.JIA_SHEN,
      );
    });

    test('computeJiaOnlyFuTou：己日仍要回到上一甲日（不再作符）', () {
      // 己卯(16) → 上一甲日 甲戌(11)
      expect(
        KeJiaQiMenJuCalculator.computeJiaOnlyFuTou(JiaZi.JI_MAO),
        JiaZi.JIA_XU,
      );
    });

    test('默认派别为 JIA_JI_FU_TOU（向后兼容）', () {
      final dt = DateTime(2026, 5, 7, 20, 21);
      final ju = KeJiaQiMenJuCalculator(dateTime: dt).calculate();
      // 5/7 辛巳 → 上一甲己日 己卯(16) → 卯=上元
      expect(ju.fuTouJiaZi, JiaZi.JI_MAO);
      expect(ju.atThreeYuan, EnumThreeYuan.START);
      // 立夏上元 = 阳遁 4 局
      expect(ju.initJuNumber, 4);
    });

    test('神刻奇门派别（仅甲作符）：5/7 → 甲戌符头、下元、初局7', () {
      final dt = DateTime(2026, 5, 7, 20, 21);
      final ju = KeJiaQiMenJuCalculator(
        dateTime: dt,
        keScheme: KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI,
        fuTouScheme: FuTouSchemeType.JIA_FU_TOU,
      ).calculate();

      expect(ju.fuTouJiaZi, JiaZi.JIA_XU, reason: '仅甲作符：上一甲日 4/30=甲戌');
      expect(ju.atThreeYuan, EnumThreeYuan.END, reason: '戌=四墓库 → 下元');
      expect(ju.initJuNumber, 7, reason: '立夏下元 = 阳遁7局');
      expect(ju.shiJiaZi, JiaZi.WU_XU);
      expect(ju.keJiaZi, JiaZi.JIA_CHEN, reason: '60刻 第 (81÷2)+1=41 刻 → 甲辰');
      expect(ju.keIndex, 41);
      // 阳遁推移 ((7-1+40) % 9) + 1 = 46%9+1 = 1+1 = 2
      expect(ju.juNumber, 2, reason: '推移后 = 阳遁2局（与神刻奇门对照盘一致）');
      expect(ju.yinYangDun, YinYang.YANG, reason: '甲为阳干 → 阳遁');
    });

    test('对照：5/7 同一时间默认派别下初局 4、推移后 8', () {
      // 同一时间 + 60刻方案 + 默认（甲己作符）→ 推移后8局，与神刻奇门(2局)不同
      final dt = DateTime(2026, 5, 7, 20, 21);
      final ju = KeJiaQiMenJuCalculator(
        dateTime: dt,
        keScheme: KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI,
      ).calculate();

      expect(ju.initJuNumber, 4);
      // 阳遁推移 ((4-1+40) % 9) + 1 = 43%9+1 = 7+1 = 8
      expect(ju.juNumber, 8);
    });

    test('5/7 20:21 60刻+仅甲：值符值使同落乾6宫（神刻奇门盘体）', () {
      // 60刻 + 仅甲：阳遁2局, 旬首遁干壬在6宫
      // 刻柱=甲辰=旬首本身, step=0 → 值使停在旬首落宫=6
      final ju = KeJiaQiMenJuCalculator(
        dateTime: DateTime(2026, 5, 7, 20, 21),
        keScheme: KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI,
        fuTouScheme: FuTouSchemeType.JIA_FU_TOU,
      ).calculate();

      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      final pan = KeJiaQiMenPan(
        ju: ju,
        starSet: starSet,
        settings: PanArrangeSettings(
          arrangeType: ArrangeType.values.first,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI_NA_GUA,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        ),
      );

      expect(pan.zhiFuStar, NineStarsEnum.XIN, reason: '值符=天心(6宫本位)');
      expect(pan.zhiShiDoor, EightDoorEnum.KAI, reason: '值使=开门(6宫本位)');
      expect(pan.zhiFuStarAtGong, HouTianGua.Qian,
          reason: '值符天心 飞至 6宫(乾)');
      expect(pan.zhiShiDoorAtGong, HouTianGua.Qian,
          reason: '值使开门 飞至 6宫(乾) — 神刻奇门 step=0 跟随旬首');
    });
  });

  // ─────────────────────────────────────────────────────────
  // §8 KeJiaQiMenPan 排盘算法验证（用户 spec 2026-05-05 §2-§3）
  //
  // 重点验证项：
  //   - 值符飞至宫 = 刻干在地盘的落宫（不是步距）
  //   - 值使飞至宫 = 刻支后天八卦配宫（不是步距）
  //   - 八门 path direction = 刻干阴阳（阳干顺时针 / 阴干逆时针）
  // ─────────────────────────────────────────────────────────
  group('KeJiaQiMenPan 排盘', () {
    /// 构造一个最简的 KeJiaJu 用于直接驱动 KeJiaQiMenPan。
    /// 跳过 calculator 的复杂上游，专注验证排盘算法。
    KeJiaJu makeKeJiaJu({
      required JiaZi keJiaZi,
      required int qiJuGongHouTian,
      required YinYang yinYangDun,
    }) {
      return KeJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 5, 5),
        yinYangDun: yinYangDun,
        juNumber: qiJuGongHouTian,
        fourZhuEightChar: '甲子 甲子 甲子 ${keJiaZi.name}',
        keJiaZi: keJiaZi,
        keIndex: 1,
        shiJiaZi: JiaZi.JIA_ZI,
        initJuNumber: qiJuGongHouTian,
        shiChenStartAt: DateTime(2026, 5, 5),
        fuTouJiaZi: JiaZi.JIA_ZI,
        jieQiAt: TwentyFourJieQi.LI_CHUN,
        jieQiStartAt: DateTime(2026, 5, 5),
        jieQiEnd: TwentyFourJieQi.YU_SHUI,
        jieQiEndAt: DateTime(2026, 5, 5),
        atThreeYuan: EnumThreeYuan.START,
      );
    }

    test('阳干刻 甲子 + 阳遁一局：值符=蓬@坎1，值使=休@坎1，八门顺时针', () {
      final ju = makeKeJiaJu(
        keJiaZi: JiaZi.JIA_ZI,
        qiJuGongHouTian: 1, // 起坎1
        yinYangDun: YinYang.YANG,
      );
      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      final pan = KeJiaQiMenPan(
        ju: ju,
        starSet: starSet,
        settings: PanArrangeSettings(
          arrangeType: ArrangeType.values.first,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI_NA_GUA,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        ),
      );

      // 旬首=甲子, 旬首遁干=戊; 阳遁起坎1 → 戊在 1 宫
      expect(pan.zhiFuStar, NineStarsEnum.PENG, reason: '值符应为 天蓬 (坎1本位)');
      expect(pan.zhiShiDoor, EightDoorEnum.XIU, reason: '值使应为 休门 (坎1本位)');

      // 刻干甲 → 旬首遁干戊 → 落 1宫
      expect(pan.zhiFuStarAtGong, HouTianGua.Kan,
          reason: '值符飞至刻干所在宫 (戊在坎1)');

      // 刻支子 → 配宫 1
      expect(pan.zhiShiDoorAtGong, HouTianGua.Kan,
          reason: '值使飞至刻支配宫 (子→坎1)');

      // 八门顺时针起 1: 1=休, 8=生, 3=伤, 4=杜, 9=景, 2=死, 7=惊, 6=开
      expect(pan.gongMapper[HouTianGua.Kan]!.door, EightDoorEnum.XIU);
      expect(pan.gongMapper[HouTianGua.Gen]!.door, EightDoorEnum.SHENG);
      expect(pan.gongMapper[HouTianGua.Zhen]!.door, EightDoorEnum.SHANG);
      expect(pan.gongMapper[HouTianGua.Xun]!.door, EightDoorEnum.DU);
      expect(pan.gongMapper[HouTianGua.Li]!.door, EightDoorEnum.JING_S);
      expect(pan.gongMapper[HouTianGua.Kun]!.door, EightDoorEnum.SI);
      expect(pan.gongMapper[HouTianGua.Dui]!.door, EightDoorEnum.JING_W);
      expect(pan.gongMapper[HouTianGua.Qian]!.door, EightDoorEnum.KAI);
    });

    test('阴干刻 乙丑 + 阴遁一局：八门逆时针', () {
      // 阴遁起坎1：戊在1, 己在9, 庚在8, ..., 乙在2 (逆布)
      final ju = makeKeJiaJu(
        keJiaZi: JiaZi.YI_CHOU, // 乙丑刻
        qiJuGongHouTian: 1,
        yinYangDun: YinYang.YIN,
      );
      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      final pan = KeJiaQiMenPan(
        ju: ju,
        starSet: starSet,
        settings: PanArrangeSettings(
          arrangeType: ArrangeType.values.first,
          jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
          starMonthTokenType: MonthTokenTypeEnum.ZHU_QI_NA_GUA,
          starFourWeiGongType: GongTypeEnum.GONG_GUA,
          doorFourWeiGongType: GongTypeEnum.GONG_GUA,
          godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
          ganGongType: GanGongTypeEnum.WANG_MU,
        ),
      );

      // 乙丑在甲子旬, 旬首=甲子, 旬首遁干=戊
      // 阴遁起坎1, 戊在1宫 → 值符=蓬, 值使=休
      expect(pan.zhiFuStar, NineStarsEnum.PENG);
      expect(pan.zhiShiDoor, EightDoorEnum.XIU);

      // 刻干乙在地盘的落宫: 阴遁逆布从1起 [1,9,8,7,6,5,4,3,2] 配 [戊己庚辛壬癸丁丙乙]
      // 1戊 9己 8庚 7辛 6壬 5癸 4丁 3丙 2乙 → 乙落 2宫
      expect(pan.zhiFuStarAtGong, HouTianGua.Kun,
          reason: '阴遁起1，乙在 2宫 (坤)');

      // 刻支丑 → 配宫 8 (艮)
      expect(pan.zhiShiDoorAtGong, HouTianGua.Gen,
          reason: '刻支丑配宫 8 (艮)');

      // 八门逆时针 [1,6,7,2,9,4,3,8] 起 8: 8→1→6→7→2→9→4→3
      // 门起 休: 8=休, 1=生, 6=伤, 7=杜, 2=景, 9=死, 4=惊, 3=开
      expect(pan.gongMapper[HouTianGua.Gen]!.door, EightDoorEnum.XIU);
      expect(pan.gongMapper[HouTianGua.Kan]!.door, EightDoorEnum.SHENG);
      expect(pan.gongMapper[HouTianGua.Qian]!.door, EightDoorEnum.SHANG);
      expect(pan.gongMapper[HouTianGua.Dui]!.door, EightDoorEnum.DU);
      expect(pan.gongMapper[HouTianGua.Kun]!.door, EightDoorEnum.JING_S);
      expect(pan.gongMapper[HouTianGua.Li]!.door, EightDoorEnum.SI);
      expect(pan.gongMapper[HouTianGua.Xun]!.door, EightDoorEnum.JING_W);
      expect(pan.gongMapper[HouTianGua.Zhen]!.door, EightDoorEnum.KAI);
    });
  });
}
