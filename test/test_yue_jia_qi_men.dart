import 'package:common/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qimendunjia/domain/entities/san_yuan_type.dart';
import 'package:qimendunjia/domain/entities/yue_jia_ju.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/utils/yue_jia_qi_men_ju_calculator.dart';

/// 月家奇门单元测试
///
/// 算法依据：docs/more_qimen/yue_jia_algorithm.md
///         docs/more_qimen/qimen_jia_comparison.md
///
/// 注：fixture 中的"期望值符星 / 期望值使门 / 九星宫位分布"等
/// 需要领域人员核对（详见 docs/more_qimen/yue_jia_tasks.md
/// P3-T1.2 待补全）；本测试当前只覆盖 calculator 层确定性逻辑。
void main() {
  group('YueJiaQiMenJuCalculator.yearZhiToSanYuan', () {
    test('孟年（寅申巳亥）→ 上元', () {
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.YIN),
          SanYuanType.SHANG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.SHEN),
          SanYuanType.SHANG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.SI),
          SanYuanType.SHANG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.HAI),
          SanYuanType.SHANG);
    });

    test('仲年（子午卯酉）→ 中元', () {
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.ZI),
          SanYuanType.ZHONG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.WU),
          SanYuanType.ZHONG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.MAO),
          SanYuanType.ZHONG);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.YOU),
          SanYuanType.ZHONG);
    });

    test('季年（辰戌丑未）→ 下元', () {
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.CHEN),
          SanYuanType.XIA);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.XU),
          SanYuanType.XIA);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.CHOU),
          SanYuanType.XIA);
      expect(YueJiaQiMenJuCalculator.yearZhiToSanYuan(DiZhi.WEI),
          SanYuanType.XIA);
    });
  });

  group('YueJiaQiMenJuCalculator.sanYuanToQiJuGong（月家映射）', () {
    test('上元 → 坎 1', () {
      expect(YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.SHANG),
          HouTianGua.Kan);
      expect(
          YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.SHANG)
              .houTianOrder,
          1);
    });

    test('中元 → 兑 7（注意：与年家不同；年家中元起巽4）', () {
      expect(YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.ZHONG),
          HouTianGua.Dui);
      expect(
          YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.ZHONG)
              .houTianOrder,
          7);
    });

    test('下元 → 巽 4（注意：与年家不同；年家下元起兑7）', () {
      expect(YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.XIA),
          HouTianGua.Xun);
      expect(
          YueJiaQiMenJuCalculator.sanYuanToQiJuGong(SanYuanType.XIA)
              .houTianOrder,
          4);
    });
  });

  group('YueJiaJu 实体不变量', () {
    test('jia 恒为 QiMenJia.YUE', () {
      final ju = YueJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 4, 15),
        yearJiaZi: JiaZi.JIA_ZI,
        monthJiaZi: JiaZi.JIA_ZI,
        sanYuan: SanYuanType.SHANG,
        qiJuGong: HouTianGua.Kan,
        fourZhuEightChar: '甲子 甲子 甲子 甲子',
      );
      expect(ju.jia, QiMenJia.YUE);
    });

    test('yinYangDun 恒为 YIN（月家无阳遁）', () {
      final ju = YueJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 4, 15),
        yearJiaZi: JiaZi.JIA_ZI,
        monthJiaZi: JiaZi.JIA_ZI,
        sanYuan: SanYuanType.SHANG,
        qiJuGong: HouTianGua.Kan,
        fourZhuEightChar: '',
      );
      expect(ju.yinYangDun, YinYang.YIN);
      expect(ju.yinYangDun.isYin, true);
      expect(ju.yinYangDun.isYang, false);
    });

    test('juNumber == qiJuGong.houTianOrder', () {
      final ju = YueJiaJu(
        id: 'test',
        panDateTime: DateTime(2026, 4, 15),
        yearJiaZi: JiaZi.JIA_ZI,
        monthJiaZi: JiaZi.JIA_ZI,
        sanYuan: SanYuanType.ZHONG,
        qiJuGong: HouTianGua.Dui,
        fourZhuEightChar: '',
      );
      expect(ju.juNumber, 7);
    });
  });

  // TODO P3-T1.2：待领域人员补全 fixture 后启用
  //
  // group('YueJiaQiMenJuCalculator.calculate × fixture', () {
  //   for (final sample in yueJiaSamples) {
  //     test('${sample.input} → ${sample.monthJiaZi} / ${sample.sanYuan}', () {
  //       final ju = YueJiaQiMenJuCalculator(dateTime: sample.input).calculate();
  //       expect(ju.yearJiaZi.name, sample.yearJiaZi);
  //       expect(ju.monthJiaZi.name, sample.monthJiaZi);
  //       expect(ju.sanYuan.name, sample.sanYuan);
  //       expect(ju.qiJuGong.houTianOrder, sample.qiJuGong);
  //     });
  //   }
  // });
}
