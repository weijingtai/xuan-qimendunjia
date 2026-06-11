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

  group('神刻奇门 Bug 复现', () {
    test('案例 1: 2026-05-25 17:40 (小满中元 阳二局)', () {
      final dt = DateTime(2026, 5, 25, 17, 40);
      final calc = KeJiaQiMenJuCalculator(
        dateTime: dt,
        keScheme: KeSchemeType.SHEN_KE_2MIN,
        fuTouScheme: FuTouSchemeType.JIA_JI_FU_TOU,
      );
      final ju = calc.calculate();

      // 目前代码中神刻会有 +2 的 shift (21刻)，导致变为 4 局
      // 期望：不 shift，维持 2 局
      expect(ju.juNumber, 2, reason: '神刻不应随旬推移局数');
      expect(ju.yinYangDun, YinYang.YANG);
      expect(ju.keJiaZi.name, '甲申');

      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
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

      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
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

      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
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

      final starSet = NineStarsEnum.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      final pan = ShenKeQiMenPan(
        ju: ju,
        starSet: starSet,
        settings: defaultSettings,
      );

      expect(pan.zhiFuStarAtGong.houTianOrder, 1, reason: '值符天心应落一宫');
      expect(pan.zhiShiDoorAtGong.houTianOrder, 4, reason: '值使开门应落四宫');
    });
  });
}
