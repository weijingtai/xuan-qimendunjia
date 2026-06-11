/// 刻家奇门「刻制」方案
///
/// - [TEN_KE_WU_ZI_JIAN_YUAN]：一时辰 10 刻、每刻 12 分钟，刻干支按
///   "五子建元 + 60 甲子顺数"推算（公式：`((shiJiaZi.number - 1) * 10 + (keIndex - 1)) % 60 + 1`）。
/// - [EIGHT_KE_WU_MA_DUN]：一时辰 8 刻、每刻 15 分钟，刻干支按"五马遁"推算
///   （甲己时起甲子刻 / 乙庚时起丙子刻 / 丙辛时起戊子刻 / 丁壬时起庚子刻 / 戊癸时起壬子刻；
///   时辰内 8 刻沿 60 甲子顺序后推）。
/// - [SIXTY_KE_LIU_SHI_JIA_ZI]：一时辰 60 刻、每刻 2 分钟，60 刻 = 60 甲子一个完整周期。
///   每时辰起点恒为甲子，与时柱**解耦**；公式：`keJiaZi.number = ((keIndex - 1) % 60) + 1`。
/// - [SHEN_KE_2MIN]：神刻奇门·2 分钟一干支。一时辰 60 刻、每刻 2 分钟；刻干支同 60甲子
///   每时辰起甲子。但 **yinYangDun / juNumber 取自时家奇门（节气定局）**而非刻干阴阳，
///   起盘走独立 [ShenKeQiMenPan] 排盘器（含中5 的 1→2→3 顺数路径、白虎玄武八神序）。
///
/// 前三方案下"阴阳遁取自刻干阴阳"、"局推移 ±(keIndex-1)" 规则相同；神刻方案另起。
enum KeSchemeType {
  TEN_KE_WU_ZI_JIAN_YUAN("十刻·五子建元", 10, 12),
  EIGHT_KE_WU_MA_DUN("八刻·五马遁", 8, 15),
  SIXTY_KE_LIU_SHI_JIA_ZI("60刻·60甲子", 60, 2),
  SHEN_KE_2MIN("神刻·2分钟一干支", 60, 2);

  final String name;
  final int totalKeCount;
  final int minutesPerKe;

  const KeSchemeType(this.name, this.totalKeCount, this.minutesPerKe);

  int get totalMinutes => totalKeCount * minutesPerKe;
}
