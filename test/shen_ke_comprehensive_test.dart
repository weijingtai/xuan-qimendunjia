import 'package:metaphysics_core/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/utils/ke_jia_qi_men_ju_calculator.dart';
import 'package:qimendunjia/model/shen_ke_qi_men_pan.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/model/pan_arrange_settings.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/model/shi_jia_qi_men.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';

void main() {
  final defaultSettings = PanArrangeSettings(
    arrangeType: ArrangeType.CHAI_BU,
    jiGong: CenterGongJiGongType.ONLY_KUN_GONG,
    starMonthTokenType: MonthTokenTypeEnum.ZHU_QI_NA_GUA,
    starFourWeiGongType: GongTypeEnum.GONG_GUA,
    doorFourWeiGongType: GongTypeEnum.GONG_GUA,
    godWithGongTypeEnum: GodWithGongTypeEnum.GONG_GUA_ONLY,
    ganGongType: GanGongTypeEnum.WANG_MU,
  );

  final List<QiMenStar> starSet = NineStarsEnum.values.toList()
    ..sort((a, b) => a.number.compareTo(b.number));

  group('神刻奇门 综合测试 (Tester Role)', () {
    // ─────────────────────────────────────────────────────────
    // §1 标准参考案例 (Bug 复现与回归)
    // ─────────────────────────────────────────────────────────
    group('标准参考案例 (2026/2035/2030)', () {
      test('案例 1: 2026-05-25 17:40 (小满中元 阳二局)', () {
        final dt = DateTime(2026, 5, 25, 17, 40);
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.SHEN_KE_2MIN,
        );
        final ju = calc.calculate();

        expect(ju.juNumber, 2, reason: '神刻不应随旬推移局数 (Expected Yang 2)');
        expect(ju.yinYangDun, YinYang.YANG);
        expect(ju.keJiaZi.name, '甲申');

        final pan = ShenKeQiMenPan(
          ju: ju,
          starSet: starSet,
          settings: defaultSettings,
        );

        expect(pan.zhiFuStarAtGong.houTianOrder, 4, reason: '值符天辅应落四宫');
        expect(pan.zhiShiDoorAtGong.houTianOrder, 4, reason: '值使杜门应落四宫');
      });

      test('案例 2: 2026-05-25 17:44 (小满中元 阳二局)', () {
        final dt = DateTime(2026, 5, 25, 17, 44);
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.SHEN_KE_2MIN,
        );
        final ju = calc.calculate();

        expect(ju.juNumber, 2);
        expect(ju.keJiaZi.name, '丙戌');

        final pan = ShenKeQiMenPan(
          ju: ju,
          starSet: starSet,
          settings: defaultSettings,
        );

        expect(pan.zhiFuStarAtGong.houTianOrder, 9, reason: '值符天辅应落九宫');
        expect(pan.zhiShiDoorAtGong.houTianOrder, 6, reason: '值使杜门应落六宫');
      });

      test('案例 3: 2035-05-25 17:44 (小满下元 阳八局)', () {
        final dt = DateTime(2035, 5, 25, 17, 44);
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.SHEN_KE_2MIN,
        );
        final ju = calc.calculate();

        expect(ju.juNumber, 8);
        expect(ju.keJiaZi.name, '丙戌');

        final pan = ShenKeQiMenPan(
          ju: ju,
          starSet: starSet,
          settings: defaultSettings,
        );

        expect(pan.zhiFuStarAtGong.houTianOrder, 6, reason: '值符天蓬应落六宫');
        expect(pan.zhiShiDoorAtGong.houTianOrder, 3, reason: '值使休门应落三宫');
      });

      test('案例 4: 2030-10-25 17:44 (霜降上元 阴八局)', () {
        final dt = DateTime(2030, 10, 25, 17, 44);
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.SHEN_KE_2MIN,
        );
        final ju = calc.calculate();

        expect(ju.juNumber, 8);
        expect(ju.yinYangDun, YinYang.YIN);
        expect(ju.keJiaZi.name, '丙戌');

        final pan = ShenKeQiMenPan(
          ju: ju,
          starSet: starSet,
          settings: defaultSettings,
        );

        expect(pan.zhiFuStarAtGong.houTianOrder, 1, reason: '值符天心应落一宫');
        expect(pan.zhiShiDoorAtGong.houTianOrder, 4, reason: '值使开门应落四宫');
      });

      test('案例 5: 2034-11-23 21:44 (小雪上元 阴九局)', () {
        final dt = DateTime(2034, 11, 23, 21, 44);
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.SHEN_KE_2MIN,
        );
        final ju = calc.calculate();

        expect(ju.juNumber, 9, reason: '神刻：癸未日 (Index 2) 阴遁应为 9 局');
        expect(ju.yinYangDun, YinYang.YIN);
        expect(ju.keJiaZi.name, '丙戌');

        final pan = ShenKeQiMenPan(
          ju: ju,
          starSet: starSet,
          settings: defaultSettings,
        );

        expect(pan.zhiFuStarAtGong.houTianOrder, 2, reason: '值符天柱应落二宫');
        expect(pan.zhiShiDoorAtGong.houTianOrder, 2, reason: '值使惊门：5 宫寄 2，应落二宫');
      });
    });

    // ─────────────────────────────────────────────────────────
    // §2 边界测试 (Boundary Testing)
    // ─────────────────────────────────────────────────────────
    group('边界测试 (Midnight & Hour Transitions)', () {
      test('时辰切换边界: 16:59:59 vs 17:00:00 (神刻)', () {
        final dt1 = DateTime(2026, 5, 25, 16, 59, 59);
        final dt2 = DateTime(2026, 5, 25, 17, 0, 0);

        final calc1 = KeJiaQiMenJuCalculator(dateTime: dt1, keScheme: KeSchemeType.SHEN_KE_2MIN);
        final calc2 = KeJiaQiMenJuCalculator(dateTime: dt2, keScheme: KeSchemeType.SHEN_KE_2MIN);

        final ju1 = calc1.calculate();
        final ju2 = calc2.calculate();

        expect(ju1.keIndex, 60, reason: '16:59:59 应为上一时辰最后一刻');
        expect(ju2.keIndex, 1, reason: '17:00:00 应为下一时辰第一刻');
        expect(ju2.keJiaZi, JiaZi.JIA_ZI, reason: '神刻每时辰起甲子');
      });

      test('跨天边界 (早子时/晚子时)', () {
        final dtLate = DateTime(2026, 5, 25, 23, 5); // 晚子时
        final dtEarly = DateTime(2026, 5, 26, 0, 5); // 早子时

        final calcLate = KeJiaQiMenJuCalculator(dateTime: dtLate, keScheme: KeSchemeType.SHEN_KE_2MIN);
        final calcEarly = KeJiaQiMenJuCalculator(dateTime: dtEarly, keScheme: KeSchemeType.SHEN_KE_2MIN);

        final juLate = calcLate.calculate();
        final juEarly = calcEarly.calculate();

        // 验证日柱是否一致（均为 5/26 的日柱）
        final dayLate = juLate.fourZhuEightChar.split(' ')[2];
        final dayEarly = juEarly.fourZhuEightChar.split(' ')[2];
        expect(dayLate, dayEarly, reason: '23:00 后日柱应已切换');
        expect(dayLate, '庚子', reason: '5/25 23:00 后应为庚子日');
      });
    });

    // ─────────────────────────────────────────────────────────
    // §3 回归测试 (Non-ShenKe Schemes)
    // ─────────────────────────────────────────────────────────
    group('回归测试 (Non-ShenKe Schemes)', () {
      test('10刻方案应保持原逻辑 (阳顺阴逆推移)', () {
        final dt = DateTime(2026, 5, 25, 17, 12); // 第 2 刻 (17:12 - 17:24)
        final calc = KeJiaQiMenJuCalculator(
          dateTime: dt,
          keScheme: KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
        );
        final ju = calc.calculate();

        expect(ju.keIndex, 2);
        // 17:00 为酉时，5/25 己亥日，酉时为癸酉时
        // 10刻：((癸酉(10)-1)*10 + (2-1)) % 60 + 1 = 91 % 60 + 1 = 32 → 乙未 (阴)
        expect(ju.keJiaZi.gan.yinYang, YinYang.YIN);
        // 阴遁推移：((initJu - 1 - (2-1)) % 9) + 1
        final expected = (((ju.initJuNumber - 1 - (2 - 1)) % 9) + 9) % 9 + 1;
        expect(ju.juNumber, expected);
      });
    });


    // ─────────────────────────────────────────────────────────
    // §4 刁钻角度 (Tricky/Inverse Testing)
    // ─────────────────────────────────────────────────────────
    group('刁钻角度与恒量校验', () {
      test('神刻恒量：同一时辰内 JuNumber 应严格相等 (修复 Bug 后)', () {
        final baseTime = DateTime(2026, 5, 25, 17, 0);
        int? juNumber;

        for (int m = 0; m < 120; m += 2) {
          final dt = baseTime.add(Duration(minutes: m));
          final ju = KeJiaQiMenJuCalculator(dateTime: dt, keScheme: KeSchemeType.SHEN_KE_2MIN).calculate();
          if (juNumber == null) {
            juNumber = ju.juNumber;
          } else {
            expect(ju.juNumber, juNumber, reason: '分钟 $m: 神刻时辰内局数应恒定');
          }
        }
      });

      test('逆向：值符落宫与刻干在地盘位置必须重合 (神刻 §五)', () {
        final dt = DateTime(2026, 5, 25, 17, 44);
        final ju = KeJiaQiMenJuCalculator(dateTime: dt, keScheme: KeSchemeType.SHEN_KE_2MIN).calculate();
        final pan = ShenKeQiMenPan(ju: ju, starSet: starSet, settings: defaultSettings);

        final HouTianGua zhiFuGua = pan.zhiFuStarAtGong;
        final zhiFuGong = pan.gongMapper[zhiFuGua]!;
        // 刻干丙戌 -> 丙。检查该宫地盘干是否为丙 (或旬首干，若刻干为甲)
        // 此时刻干不是甲，直接查丙
        expect(zhiFuGong.diPan, TianGan.BING, reason: '值符飞至宫的地盘干应等于刻干');
      });

      test('逆向：值使落宫与路径位次校验 (神刻 §六)', () {
        final dt = DateTime(2026, 5, 25, 17, 40); // 甲申刻 (旬首)
        final ju = KeJiaQiMenJuCalculator(dateTime: dt, keScheme: KeSchemeType.SHEN_KE_2MIN).calculate();
        final pan = ShenKeQiMenPan(ju: ju, starSet: starSet, settings: defaultSettings);

        // 旬首刻，值使应在旬首地盘宫 (step=0)
        final xunHeaderTianGan = SixJia.getSixJiaByJiaZi(ju.keJiaZi.xunHeader).gan;
        int diPanGong = 0;
        pan.diPanGanByGong.forEach((g, gan) {
          if (gan == xunHeaderTianGan) diPanGong = g;
        });

        expect(pan.zhiShiDoorAtGong.houTianOrder, diPanGong, reason: '旬首刻值使应在旬首宫');
      });
    });
  });

  group('ZenTao Protocol Compliance', () {
    test('Trace ID check', () {
      // Dummy test to ensure Trace ID is present in logs
      print('XUAN-ZT5-TESTVERIFY: Starting comprehensive test suite.');
    });
  });
}
