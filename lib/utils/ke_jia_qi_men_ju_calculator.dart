import 'package:metaphysics_core/enums.dart';
import 'package:intl/intl.dart';
import 'package:qimendunjia/domain/entities/ke_jia_ju.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';
import 'package:qimendunjia/utils/qi_men_ju_calculator.dart';

/// 刻家奇门局计算器
///
/// 算法步骤：
///
/// 1. **本时辰时家奇门起局**（拆补法）→ 初局 juNumber 与节气信息
/// 2. **计算时辰内刻局序号**（按 [KeSchemeType] 决定的总刻数与每刻分钟数）：
///    - 一时辰 = 120 分钟，每刻分钟数与总刻数取自 [keScheme]
///    - keIndex = (分钟差 ~/ 每刻分钟数) + 1
/// 3. **计算刻干支**（三方案）：
///    - [KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN]：五子建元 + 60 甲子顺数
///      公式：`keJiaZi.number = ((shiJiaZi.number - 1) * 10 + (keIndex - 1)) mod 60 + 1`
///    - [KeSchemeType.EIGHT_KE_WU_MA_DUN]：五马遁
///      时干 → 第一刻（子刻）天干：甲己→甲、乙庚→丙、丙辛→戊、丁壬→庚、戊癸→壬；
///      时辰内 8 刻按 60 甲子顺数。
///    - [KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI]：60 刻 = 60 甲子整循环
///      每时辰起点恒为甲子，与时柱解耦；公式：`((keIndex - 1) mod 60) + 1`。
/// 4. **刻干阴阳决定 yinYangDun**（替代节气阴阳遁，三方案一致）
/// 5. **局推移**（三方案一致）：
///    - 阳：juNumber = ((initJu - 1 + (keIndex - 1)) mod 9) + 1
///    - 阴：juNumber = ((initJu - 1 - (keIndex - 1)) mod 9) + 1
class KeJiaQiMenJuCalculator {
  final DateTime dateTime;
  final KeSchemeType keScheme;
  final FuTouSchemeType fuTouScheme;

  KeJiaQiMenJuCalculator({
    required this.dateTime,
    this.keScheme = KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
    this.fuTouScheme = FuTouSchemeType.JIA_JI_FU_TOU,
  });

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// 计算时辰起始时间
  ///
  /// 子时（23:00-01:00）：
  ///   - hour == 23 → 起始 = 当日 23:00
  ///   - hour == 0  → 起始 = 前日 23:00
  /// 其它时辰：起始 = 当日 (奇数小时, 如 1, 3, 5, ..., 21)
  static DateTime calcShiChenStart(DateTime dt) {
    final h = dt.hour;
    if (h == 23) {
      return DateTime(dt.year, dt.month, dt.day, 23);
    }
    if (h == 0) {
      final prev = DateTime(dt.year, dt.month, dt.day).subtract(
        const Duration(days: 1),
      );
      return DateTime(prev.year, prev.month, prev.day, 23);
    }
    final startHour = h.isOdd ? h : h - 1;
    return DateTime(dt.year, dt.month, dt.day, startHour);
  }

  /// 计算刻局序号（1..scheme.totalKeCount）
  ///
  /// 入参 [dateTime]：起盘时间
  /// 入参 [shiChenStart]：本时辰起始时间
  /// 入参 [scheme]：刻制方案，默认十刻五子建元（向后兼容）
  static int calcKeIndex(
    DateTime dateTime,
    DateTime shiChenStart, [
    KeSchemeType scheme = KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
  ]) {
    final diffMinutes = dateTime.difference(shiChenStart).inMinutes;
    if (diffMinutes < 0 || diffMinutes >= scheme.totalMinutes) {
      throw StateError(
          '计算刻 index 异常：分钟差 $diffMinutes 不在 [0, ${scheme.totalMinutes}) 内');
    }
    return (diffMinutes ~/ scheme.minutesPerKe) + 1;
  }

  /// 计算刻干支（按方案派发）
  static JiaZi calcKeJiaZi(
    JiaZi shiJiaZi,
    int keIndex, [
    KeSchemeType scheme = KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
  ]) {
    switch (scheme) {
      case KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN:
        return calcKeJiaZiWuZiJianYuan(shiJiaZi, keIndex);
      case KeSchemeType.EIGHT_KE_WU_MA_DUN:
        return calcKeJiaZiWuMaDun(shiJiaZi, keIndex);
      case KeSchemeType.SIXTY_KE_LIU_SHI_JIA_ZI:
      case KeSchemeType.SHEN_KE_2MIN:
        return calcKeJiaZiLiuShiJiaZi(keIndex);
    }
  }

  /// 五子建元（10 刻方案）刻干支推算
  ///
  /// 起算锚点：甲子日子时甲子刻（即 shiJiaZi=JIA_ZI, keIndex=1 → JIA_ZI）
  ///
  /// 公式：keJiaZi.number = ((shiJiaZi.number - 1) * 10 + (keIndex - 1)) mod 60 + 1
  static JiaZi calcKeJiaZiWuZiJianYuan(JiaZi shiJiaZi, int keIndex) {
    final n = ((shiJiaZi.number - 1) * 10 + (keIndex - 1)) % 60 + 1;
    return JiaZi.getByNumber(n);
  }

  /// 五马遁（8 刻方案）刻干支推算
  ///
  /// - 时干 → 子刻天干（即第 1 刻）：甲己→甲、乙庚→丙、丙辛→戊、丁壬→庚、戊癸→壬
  /// - 时辰内 8 刻沿 60 甲子顺序后推：keJiaZi = 子刻 + (keIndex - 1)
  static JiaZi calcKeJiaZiWuMaDun(JiaZi shiJiaZi, int keIndex) {
    final firstZiKe = JiaZi.getFromGanZhiEnum(
      _wuMaDunFirstZiStem(shiJiaZi.gan),
      DiZhi.ZI,
    );
    final n = (firstZiKe.number - 1 + (keIndex - 1)) % 60 + 1;
    return JiaZi.getByNumber(n);
  }

  /// 60 刻·60 甲子（60 刻方案）刻干支推算
  ///
  /// - 一时辰 60 刻，每刻 2 分钟；60 刻刚好是 60 甲子一个完整周期
  /// - **每时辰起点恒为甲子**（与时柱解耦）
  /// - 公式：`keJiaZi.number = ((keIndex - 1) mod 60) + 1`
  static JiaZi calcKeJiaZiLiuShiJiaZi(int keIndex) {
    final n = ((keIndex - 1) % 60) + 1;
    return JiaZi.getByNumber(n);
  }

  /// 五马遁映射：时干 → 该时辰第一刻（子刻）的天干
  static TianGan _wuMaDunFirstZiStem(TianGan shiGan) {
    switch (shiGan) {
      case TianGan.JIA:
      case TianGan.JI:
        return TianGan.JIA;
      case TianGan.YI:
      case TianGan.GENG:
        return TianGan.BING;
      case TianGan.BING:
      case TianGan.XIN:
        return TianGan.WU;
      case TianGan.DING:
      case TianGan.REN:
        return TianGan.GENG;
      case TianGan.WU:
      case TianGan.GUI:
        return TianGan.REN;
      case TianGan.KONG_WANG:
        throw ArgumentError('五马遁不接受空亡时干 (TianGan.KONG_WANG)');
    }
  }

  /// 计算推移后局数（两方案一致）
  ///
  /// - 初局（keIndex=1）= initJu
  /// - 阳：juNumber = ((initJu - 1 + (keIndex - 1)) mod 9) + 1
  /// - 阴：juNumber = ((initJu - 1 - (keIndex - 1)) mod 9) + 1
  static int calcShiftedJuNumber(int initJu, int keIndex, YinYang yinYang) {
    final shift = keIndex - 1;
    final raw = yinYang.isYang ? (initJu - 1 + shift) : (initJu - 1 - shift);
    return ((raw % 9) + 9) % 9 + 1;
  }

  /// 仅甲日作符：返回 [dayJiaZi] 之前（含当日）最近的甲日 (number ≡ 1 mod 10)
  ///
  /// 神刻奇门派别：跳过己日，每 10 天才切换一次符头。
  static JiaZi computeJiaOnlyFuTou(JiaZi dayJiaZi) {
    final daysBack = (dayJiaZi.number - 1) % 10;
    return JiaZi.getByNumber(dayJiaZi.number - daysBack);
  }

  KeJiaJu calculate() {
    final shiJiaJu = ChaiBuCalculator(dateTime: dateTime).calculate();

    final fourZhuParts = shiJiaJu.fourZhuEightChar.split(' ');
    final shiJiaZi = JiaZi.getFromGanZhiValue(fourZhuParts[3])!;
    final shiChenStart = calcShiChenStart(dateTime);
    final keIndex = calcKeIndex(dateTime, shiChenStart, keScheme);

    final keJiaZi = calcKeJiaZi(shiJiaZi, keIndex, keScheme);

    // 神刻方案 §二：阴阳遁与局数沿用本时辰时家奇门（节气定局），不取刻干阴阳、不推移
    final bool isShenKe = keScheme == KeSchemeType.SHEN_KE_2MIN;
    final keYinYang = isShenKe ? shiJiaJu.yinYangDun : keJiaZi.gan.yinYang;

    // 按符头派别决定有效初局
    var effectiveInitJu = shiJiaJu.juNumber;
    var effectiveFuTou = shiJiaJu.fuTouJiaZi;
    var effectiveYuan = shiJiaJu.atThreeYuan;

    final dayJiaZi = JiaZi.getFromGanZhiValue(fourZhuParts[2])!;

    if (isShenKe) {
      // 神刻奇门突破性定局：取决于当日旬序号与阴阳遁 (九宫飞布循环)
      final dayXunIndex = ((dayJiaZi.number - 1) ~/ 10) + 1;
      if (shiJiaJu.yinYangDun.isYang) {
        // 阳遁：2, 5, 8 循环 (每旬跳 3 宫)
        effectiveInitJu = [2, 5, 8, 2, 5, 8][dayXunIndex - 1];
      } else {
        // 阴遁：1, 9, 8, 7, 6, 5 序列 (根据参考案例 4/5 推导)
        effectiveInitJu = [1, 9, 8, 7, 6, 5][dayXunIndex - 1];
      }
      effectiveFuTou = computeJiaOnlyFuTou(dayJiaZi);
      effectiveYuan =
          ShiJiaQiMenJuCalculator.getThreeYuanByFuHead(effectiveFuTou);
    } else if (fuTouScheme == FuTouSchemeType.JIA_FU_TOU) {
      // 仅甲日作符头方案
      effectiveFuTou = computeJiaOnlyFuTou(dayJiaZi);
      effectiveYuan =
          ShiJiaQiMenJuCalculator.getThreeYuanByFuHead(effectiveFuTou);
      final jueTuple = shiJiaJu.yinYangDun.isYang
          ? ShiJiaQiMenJuCalculator.YANG_DUN_JIE_QI_JU_NUMER[shiJiaJu.jieQiAt]!
          : ShiJiaQiMenJuCalculator.YIN_DUN_JIE_QI_JU_NUMER[shiJiaJu.jieQiAt]!;
      switch (effectiveYuan) {
        case EnumThreeYuan.START:
          effectiveInitJu = jueTuple.item1;
          break;
        case EnumThreeYuan.MIDDLE:
          effectiveInitJu = jueTuple.item2;
          break;
        case EnumThreeYuan.END:
          effectiveInitJu = jueTuple.item3;
          break;
        case EnumThreeYuan.NONE:
          effectiveInitJu = shiJiaJu.juNumber;
          break;
      }
    }

    final shiftedJu = isShenKe
        ? effectiveInitJu
        : calcShiftedJuNumber(
            effectiveInitJu,
            keIndex,
            keYinYang,
          );

    final keFourZhu = [
      fourZhuParts[0],
      fourZhuParts[1],
      fourZhuParts[2],
      keJiaZi.name,
    ].join(' ');

    return KeJiaJu(
      id: 'kejia-${dateTime.millisecondsSinceEpoch}',
      panDateTime: dateTime,
      yinYangDun: keYinYang,
      juNumber: shiftedJu,
      fourZhuEightChar: keFourZhu,
      keJiaZi: keJiaZi,
      keIndex: keIndex,
      keScheme: keScheme,
      shiJiaZi: shiJiaZi,
      initJuNumber: effectiveInitJu,
      shiChenStartAt: shiChenStart,
      fuTouJiaZi: effectiveFuTou,
      jieQiAt: shiJiaJu.jieQiAt,
      jieQiStartAt: shiJiaJu.jieQiStartAt ?? dateTime,
      jieQiEnd: shiJiaJu.jieQiEnd,
      jieQiEndAt: shiJiaJu.jieQiEndAt ?? dateTime,
      atThreeYuan: effectiveYuan,
    );
  }

  /// （仅供单测/调试用）格式化时间
  static String formatDateTime(DateTime dt) => _dateFormatter.format(dt);
}
