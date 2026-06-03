import 'package:metaphysics_core/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/domain/entities/ri_jia_day_analysis.dart';
import 'package:qimendunjia/enums/enum_ri_jia_huang_dao.dart';

/// 日家奇门日级辅助分析测试
///
/// 算法依据:`docs/日家奇门.md` §3-§7
void main() {
  // ─────────────────────────────────────────────────────────
  // §1 RiJiaHuangDaoEnum 完整性
  // ─────────────────────────────────────────────────────────
  group('RiJiaHuangDaoEnum', () {
    test('12 个枚举值,序号 0-11', () {
      final orders = RiJiaHuangDaoEnum.values.map((e) => e.order).toList()
        ..sort();
      expect(orders, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    });

    test('黄道 6 神,黑道 6 神', () {
      final huangDao = RiJiaHuangDaoEnum.values.where((e) => e.isHuangDao).toList();
      final heiDao = RiJiaHuangDaoEnum.values.where((e) => e.isHeiDao).toList();
      expect(huangDao.length, 6);
      expect(heiDao.length, 6);
      // 黄道:青龙、明堂、金匮、天德、玉堂、司命
      expect(
          huangDao.map((e) => e.name).toSet(),
          {'青龙', '明堂', '金匮', '天德', '玉堂', '司命'});
      // 黑道:天刑、朱雀、白虎、天牢、玄武、勾陈
      expect(
          heiDao.map((e) => e.name).toSet(),
          {'天刑', '朱雀', '白虎', '天牢', '玄武', '勾陈'});
    });
  });

  // ─────────────────────────────────────────────────────────
  // §2 喜神方位
  // ─────────────────────────────────────────────────────────
  group('喜神方位', () {
    test('甲己 → 艮 8 (东北)', () {
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.JIA), HouTianGua.Gen);
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.JI), HouTianGua.Gen);
    });

    test('乙庚 → 乾 6 (西北)', () {
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.YI), HouTianGua.Qian);
      expect(
          RiJiaDayAnalysis.calcXiShenDirection(TianGan.GENG), HouTianGua.Qian);
    });

    test('丙辛 → 坤 2 (西南)', () {
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.BING), HouTianGua.Kun);
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.XIN), HouTianGua.Kun);
    });

    test('丁壬 → 离 9 (南)', () {
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.DING), HouTianGua.Li);
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.REN), HouTianGua.Li);
    });

    test('戊癸 → 巽 4 (东南)', () {
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.WU), HouTianGua.Xun);
      expect(RiJiaDayAnalysis.calcXiShenDirection(TianGan.GUI), HouTianGua.Xun);
    });
  });

  // ─────────────────────────────────────────────────────────
  // §3 天乙贵人
  // ─────────────────────────────────────────────────────────
  group('天乙贵人', () {
    test('甲戊 → 丑未', () {
      const expected = {DiZhi.CHOU, DiZhi.WEI};
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.JIA), expected);
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.WU), expected);
    });

    test('乙己 → 子申', () {
      const expected = {DiZhi.ZI, DiZhi.SHEN};
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.YI), expected);
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.JI), expected);
    });

    test('丙丁 → 亥酉', () {
      const expected = {DiZhi.HAI, DiZhi.YOU};
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.BING), expected);
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.DING), expected);
    });

    test('庚辛 → 寅午', () {
      const expected = {DiZhi.YIN, DiZhi.WU};
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.GENG), expected);
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.XIN), expected);
    });

    test('壬癸 → 卯巳', () {
      const expected = {DiZhi.MAO, DiZhi.SI};
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.REN), expected);
      expect(RiJiaDayAnalysis.calcTianYiGuiRen(TianGan.GUI), expected);
    });

    test('每个日干天乙贵人都有 2 个时辰', () {
      for (final gan in TianGan.values) {
        expect(RiJiaDayAnalysis.calcTianYiGuiRen(gan).length, 2,
            reason: '$gan 应有 2 个天乙贵人时辰');
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // §4 截路空亡(时干为壬癸的时辰)
  // ─────────────────────────────────────────────────────────
  group('截路空亡', () {
    test('甲己 → 申酉(壬申、癸酉)', () {
      const expected = {DiZhi.SHEN, DiZhi.YOU};
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.JIA), expected);
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.JI), expected);
    });

    test('乙庚 → 午未(壬午、癸未)', () {
      const expected = {DiZhi.WU, DiZhi.WEI};
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.YI), expected);
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.GENG), expected);
    });

    test('丙辛 → 辰巳(壬辰、癸巳)', () {
      const expected = {DiZhi.CHEN, DiZhi.SI};
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.BING), expected);
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.XIN), expected);
    });

    test('丁壬 → 寅卯(壬寅、癸卯)', () {
      const expected = {DiZhi.YIN, DiZhi.MAO};
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.DING), expected);
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.REN), expected);
    });

    test('戊癸 → 子丑戌亥(壬子、癸丑、壬戌、癸亥) — 4 个', () {
      const expected = {DiZhi.ZI, DiZhi.CHOU, DiZhi.XU, DiZhi.HAI};
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.WU), expected);
      expect(RiJiaDayAnalysis.calcJieLuKongWang(TianGan.GUI), expected);
    });
  });

  // ─────────────────────────────────────────────────────────
  // §5 五不遇时(时干克日干)
  // ─────────────────────────────────────────────────────────
  group('五不遇时', () {
    test('甲日 → 庚午时(庚克甲)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.JIA), {DiZhi.WU});
    });

    test('乙日 → 辛巳时(辛克乙)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.YI), {DiZhi.SI});
    });

    test('丙日 → 壬辰时(壬克丙)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.BING), {DiZhi.CHEN});
    });

    test('丁日 → 癸卯时(癸克丁)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.DING), {DiZhi.MAO});
    });

    test('戊日 → 甲寅时(甲克戊)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.WU), {DiZhi.YIN});
    });

    test('己日 → 乙丑、乙亥时(2 个,因时辰 12 周期)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.JI),
          {DiZhi.CHOU, DiZhi.HAI});
    });

    test('庚日 → 丙子、丙戌时(2 个)', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.GENG),
          {DiZhi.ZI, DiZhi.XU});
    });

    test('辛日 → 丁酉时', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.XIN), {DiZhi.YOU});
    });

    test('壬日 → 戊申时', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.REN), {DiZhi.SHEN});
    });

    test('癸日 → 己未时', () {
      expect(RiJiaDayAnalysis.calcWuBuYuShi(TianGan.GUI), {DiZhi.WEI});
    });
  });

  // ─────────────────────────────────────────────────────────
  // §6 十二黑黄道
  // ─────────────────────────────────────────────────────────
  group('十二黑黄道', () {
    test('青龙起时辰(子午→申、卯酉→寅、寅申→子、巳亥→午、辰戌→辰、丑未→戌)', () {
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.ZI), DiZhi.SHEN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.WU), DiZhi.SHEN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.MAO), DiZhi.YIN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.YOU), DiZhi.YIN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.YIN), DiZhi.ZI);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.SHEN), DiZhi.ZI);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.SI), DiZhi.WU);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.HAI), DiZhi.WU);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.CHEN), DiZhi.CHEN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.XU), DiZhi.CHEN);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.CHOU), DiZhi.XU);
      expect(RiJiaDayAnalysis.calcQingLongStartShi(DiZhi.WEI), DiZhi.XU);
    });

    test('甲子日(子日 → 申时起青龙)spec 引文示例', () {
      // spec 引文:"如甲子日从申时起青龙"
      final huangDao = RiJiaDayAnalysis.calcTwelveHuangDao(DiZhi.ZI);
      expect(huangDao[DiZhi.SHEN], RiJiaHuangDaoEnum.QING_LONG);
      expect(huangDao[DiZhi.YOU], RiJiaHuangDaoEnum.MING_TANG);
      expect(huangDao[DiZhi.XU], RiJiaHuangDaoEnum.TIAN_XING);
      expect(huangDao[DiZhi.HAI], RiJiaHuangDaoEnum.ZHU_QUE);
      expect(huangDao[DiZhi.ZI], RiJiaHuangDaoEnum.JIN_KUI);
      expect(huangDao[DiZhi.CHOU], RiJiaHuangDaoEnum.TIAN_DE);
      expect(huangDao[DiZhi.YIN], RiJiaHuangDaoEnum.BAI_HU);
      expect(huangDao[DiZhi.MAO], RiJiaHuangDaoEnum.YU_TANG);
      expect(huangDao[DiZhi.CHEN], RiJiaHuangDaoEnum.TIAN_LAO);
      expect(huangDao[DiZhi.SI], RiJiaHuangDaoEnum.XUAN_WU);
      expect(huangDao[DiZhi.WU], RiJiaHuangDaoEnum.SI_MING);
      expect(huangDao[DiZhi.WEI], RiJiaHuangDaoEnum.GOU_CHEN);
    });

    test('12 时辰全覆盖,不重不漏', () {
      for (final dayZhi in DiZhi.values) {
        final huangDao = RiJiaDayAnalysis.calcTwelveHuangDao(dayZhi);
        expect(huangDao.keys.toSet(), DiZhi.values.toSet(),
            reason: '日支 ${dayZhi.name} 应覆盖 12 时辰');
        expect(huangDao.values.toSet(), RiJiaHuangDaoEnum.values.toSet(),
            reason: '日支 ${dayZhi.name} 应使用 12 神');
      }
    });
  });

  // ─────────────────────────────────────────────────────────
  // §7 RiJiaDayAnalysis 整体集成
  // ─────────────────────────────────────────────────────────
  group('RiJiaDayAnalysis 综合', () {
    test('spec §综合实例:阳遁丙午日', () {
      // spec 引文:"此日喜神方位在坤宫,天乙贵人在酉亥"
      final analysis = RiJiaDayAnalysis.fromJiaZi(
          JiaZi.getFromGanZhiValue('丙午')!);
      expect(analysis.xiShenDirection, HouTianGua.Kun); // 喜神在坤
      expect(analysis.tianYiGuiRenZhi, {DiZhi.YOU, DiZhi.HAI}); // 酉亥
      // spec: "辰时为壬辰,是天牢,又为五不遇时;巳时玄武,又为截路空亡"
      // 丙午日,辰时 = 壬辰
      expect(analysis.isJieLuKongWang(DiZhi.CHEN), isTrue); // 丙日截路空亡:辰巳
      expect(analysis.isJieLuKongWang(DiZhi.SI), isTrue);
      expect(analysis.isWuBuYuShi(DiZhi.CHEN), isTrue); // 丙日五不遇时:辰
      // 丙午日青龙在申(子午起申)
      expect(analysis.huangDaoAt(DiZhi.SHEN), RiJiaHuangDaoEnum.QING_LONG);
      // 巳时玄武
      expect(analysis.huangDaoAt(DiZhi.SI), RiJiaHuangDaoEnum.XUAN_WU);
    });

    test('spec §综合实例:阴遁乙卯日', () {
      // spec 引文:"此日喜神方位在乾宫"
      final analysis = RiJiaDayAnalysis.fromJiaZi(
          JiaZi.getFromGanZhiValue('乙卯')!);
      expect(analysis.xiShenDirection, HouTianGua.Qian); // 喜神在乾
      // 乙卯日青龙在寅(卯酉之日又在寅)
      expect(analysis.huangDaoAt(DiZhi.YIN), RiJiaHuangDaoEnum.QING_LONG);
      // 卯时明堂
      expect(analysis.huangDaoAt(DiZhi.MAO), RiJiaHuangDaoEnum.MING_TANG);
      // spec: "巳时为辛巳,又为五不遇时" — 乙日五不遇时为巳
      expect(analysis.isWuBuYuShi(DiZhi.SI), isTrue);
      // spec: "午时为金匮,又为截路空亡" — 乙日截路空亡:午未
      expect(analysis.isJieLuKongWang(DiZhi.WU), isTrue);
      expect(analysis.huangDaoAt(DiZhi.WU), RiJiaHuangDaoEnum.JIN_KUI);
    });

    test('isShiAuspicious 综合规则', () {
      // 甲子日:青龙在申时
      final a = RiJiaDayAnalysis.fromJiaZi(JiaZi.getFromGanZhiValue('甲子')!);

      // 申时青龙 + 不空亡 + 不五不遇 → 吉
      expect(a.huangDaoAt(DiZhi.SHEN), RiJiaHuangDaoEnum.QING_LONG);
      expect(a.isShiAuspicious(DiZhi.SHEN), isTrue);

      // 戌时天刑 → 凶
      expect(a.huangDaoAt(DiZhi.XU).isHeiDao, isTrue);
      expect(a.isShiAuspicious(DiZhi.XU), isFalse);
    });
  });
}
