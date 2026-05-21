/// 刻家奇门「拆补法符头」派别
///
/// 影响 [KeJiaQiMenJuCalculator] 在算"时家初局"时如何选符头：
/// - [JIA_JI_FU_TOU]（传统拆补·五日一元）：甲日和己日均作符头。复用
///   `ChaiBuCalculator` 的 `getFuTouByDayJiaZi`，符头每 5 天切换一次。
/// - [JIA_FU_TOU]（神刻奇门·十日一元）：**仅甲日**作符头，跳过己日。符头
///   每 10 天才切换一次；与传统拆补会在"前甲距日 5 ≤ d ≤ 9 天"区间产生
///   不同的三元判定（这正是 5/7 辛巳日两派分歧的来源）。
///
/// 仅在刻家奇门排盘时生效；时家/月家/年家/日家不读此字段。
enum FuTouSchemeType {
  JIA_JI_FU_TOU("甲己作符·传统"),
  JIA_FU_TOU("仅甲作符·神刻");

  final String name;
  const FuTouSchemeType(this.name);
}
