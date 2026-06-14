
/// 十二黑黄道神
///
/// 算法依据:`docs/日家奇门.md` §3
///
/// 顺序(从青龙起,顺次填入12时辰):
///   青龙(黄道) → 明堂(黄道) → 天刑(黑道) → 朱雀(黑道) → 金匮(黄道) → 天德(黄道)
///   → 白虎(黑道) → 玉堂(黄道) → 天牢(黑道) → 玄武(黑道) → 司命(黄道) → 勾陈(黑道)
///
/// 黄道(吉,6神):青龙、明堂、金匮、天德、玉堂、司命
/// 黑道(凶,6神):天刑、朱雀、白虎、天牢、玄武、勾陈
///
/// 每日青龙起时辰由日支决定(详见 [RiJiaDayAnalysis])。
enum RiJiaHuangDaoEnum {
  QING_LONG(0, '青龙', true),
  MING_TANG(1, '明堂', true),
  TIAN_XING(2, '天刑', false),
  ZHU_QUE(3, '朱雀', false),
  JIN_KUI(4, '金匮', true),
  TIAN_DE(5, '天德', true),
  BAI_HU(6, '白虎', false),
  YU_TANG(7, '玉堂', true),
  TIAN_LAO(8, '天牢', false),
  XUAN_WU(9, '玄武', false),
  SI_MING(10, '司命', true),
  GOU_CHEN(11, '勾陈', false);

  /// 序号(0-11),从青龙起顺推
  final int order;

  /// 神名
  final String name;

  /// 是否黄道(吉);false 为黑道(凶)
  final bool isHuangDao;

  const RiJiaHuangDaoEnum(this.order, this.name, this.isHuangDao);

  /// 是否黑道(凶)
  bool get isHeiDao => !isHuangDao;

  static RiJiaHuangDaoEnum fromOrder(int order) =>
      values.firstWhere((e) => e.order == order,
          orElse: () => throw ArgumentError(
              'RiJiaHuangDaoEnum.fromOrder: 期望 0-11,实际 $order'));

  static RiJiaHuangDaoEnum fromName(String name) =>
      values.firstWhere((e) => e.name == name,
          orElse: () => throw ArgumentError(
              'RiJiaHuangDaoEnum.fromName: 未找到 $name'));
}
