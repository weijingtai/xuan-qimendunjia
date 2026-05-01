/// 奇门遁甲家级枚举
///
/// 区分时/日/月/年四种家。当前代码主体围绕「时家」展开，
/// 通过引入此维度逐步支持其它三家（详见 docs/more_qimen/ 下规划）。
enum QiMenJia {
  NIAN("年家"),
  YUE("月家"),
  RI("日家"),
  SHI("时家");

  final String name;
  const QiMenJia(this.name);

  static QiMenJia fromName(String name) =>
      values.firstWhere((e) => e.name == name);
}
