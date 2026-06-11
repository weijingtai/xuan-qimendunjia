import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_ri_jia_huang_dao.dart';

import 'base_entity.dart';

/// 日家奇门"日级辅助分析"
///
/// 算法依据:`docs/日家奇门.md` §3-§7
///
/// 由日柱(干 + 支)派生的 5 类神煞与时辰标记:
///
/// | § | 内容 | 驱动 | 数据 |
/// | :-: | :-- | :-- | :-- |
/// | §3 | 十二黑黄道 | 日支 | 12 时辰 → [RiJiaHuangDaoEnum] |
/// | §4 | 喜神方位 | 日干 | 单一 [HouTianGua] |
/// | §5 | 天乙贵人 | 日干 | 2 个时辰 |
/// | §6 | 截路空亡 | 日干 | 2 / 4 个时辰 |
/// | §7 | 五不遇时 | 日干 + 五虎遁推时干 | 1 / 2 个时辰 |
///
/// 与排盘(九星 / 八门)分离,作为独立的"时辰吉凶维度"暴露给 UI。
class RiJiaDayAnalysis extends Equatable implements Entity {
  @override
  String get id => 'ri-jia-analysis-${dayJiaZi.name}';

  /// 日柱
  final JiaZi dayJiaZi;

  /// 喜神方位卦
  final HouTianGua xiShenDirection;

  /// 天乙贵人时辰(2 个)
  final Set<DiZhi> tianYiGuiRenZhi;

  /// 截路空亡时辰(2 / 4 个,即时干为壬癸的时辰)
  final Set<DiZhi> jieLuKongWangZhi;

  /// 五不遇时时辰(1 / 2 个,即时干克日干且阳克阳/阴克阴的时辰)
  final Set<DiZhi> wuBuYuShiZhi;

  /// 十二黑黄道:12 时辰 → 神
  final Map<DiZhi, RiJiaHuangDaoEnum> twelveHuangDao;

  RiJiaDayAnalysis({
    required this.dayJiaZi,
    required this.xiShenDirection,
    required this.tianYiGuiRenZhi,
    required this.jieLuKongWangZhi,
    required this.wuBuYuShiZhi,
    required this.twelveHuangDao,
  });

  /// 从日柱构造分析(惟一公开入口)
  factory RiJiaDayAnalysis.fromJiaZi(JiaZi dayJiaZi) {
    return RiJiaDayAnalysis(
      dayJiaZi: dayJiaZi,
      xiShenDirection: calcXiShenDirection(dayJiaZi.gan),
      tianYiGuiRenZhi: calcTianYiGuiRen(dayJiaZi.gan),
      jieLuKongWangZhi: calcJieLuKongWang(dayJiaZi.gan),
      wuBuYuShiZhi: calcWuBuYuShi(dayJiaZi.gan),
      twelveHuangDao: calcTwelveHuangDao(dayJiaZi.diZhi),
    );
  }

  // ═════════════════════════════════════════════════════════
  // §4 喜神方位 — 由日干推
  // ═════════════════════════════════════════════════════════

  /// 喜神方位
  ///
  /// 《吉神方歌》:
  ///   "甲己艮、乙庚乾,丙辛坤位喜神安。
  ///    丁壬远向离宫坐,戊癸原来在巽间。"
  static HouTianGua calcXiShenDirection(TianGan gan) {
    switch (gan) {
      case TianGan.JIA:
      case TianGan.JI:
        return HouTianGua.Gen; // 艮 8 (东北)
      case TianGan.YI:
      case TianGan.GENG:
        return HouTianGua.Qian; // 乾 6 (西北)
      case TianGan.BING:
      case TianGan.XIN:
        return HouTianGua.Kun; // 坤 2 (西南)
      case TianGan.DING:
      case TianGan.REN:
        return HouTianGua.Li; // 离 9 (南)
      case TianGan.WU:
      case TianGan.GUI:
        return HouTianGua.Xun; // 巽 4 (东南)
      default:
        throw ArgumentError('日干不应为 $gan(空亡天干非日柱合法值)');
    }
  }

  // ═════════════════════════════════════════════════════════
  // §5 天乙贵人 — 由日干推时辰(2个)
  // ═════════════════════════════════════════════════════════

  /// 天乙贵人时辰
  ///
  /// 《天乙贵人歌》:
  ///   "甲戊兼牛羊,乙己鼠猴乡,丙丁猪鸡位,
  ///    壬癸兔蛇藏,庚辛逢马虎,此是贵人方。"
  static Set<DiZhi> calcTianYiGuiRen(TianGan gan) {
    switch (gan) {
      case TianGan.JIA:
      case TianGan.WU:
        return const {DiZhi.CHOU, DiZhi.WEI}; // 丑(牛)、未(羊)
      case TianGan.YI:
      case TianGan.JI:
        return const {DiZhi.ZI, DiZhi.SHEN}; // 子(鼠)、申(猴)
      case TianGan.BING:
      case TianGan.DING:
        return const {DiZhi.HAI, DiZhi.YOU}; // 亥(猪)、酉(鸡)
      case TianGan.GENG:
      case TianGan.XIN:
        return const {DiZhi.YIN, DiZhi.WU}; // 寅(虎)、午(马)
      case TianGan.REN:
      case TianGan.GUI:
        return const {DiZhi.MAO, DiZhi.SI}; // 卯(兔)、巳(蛇)
      default:
        throw ArgumentError('日干不应为 $gan');
    }
  }

  // ═════════════════════════════════════════════════════════
  // §6 截路空亡 — 由日干推(时干为壬癸的时辰)
  // ═════════════════════════════════════════════════════════

  /// 截路空亡时辰
  ///
  /// 《截路空亡歌》:
  ///   "甲己申酉最为愁,乙庚午未不须求,丙辛辰巳何劳问,
  ///    丁壬寅卯一场忧,戊癸子丑及戌亥,时犯空亡万事休。"
  ///
  /// 本质:由五虎遁推时干,时干为壬或癸的时辰即截路空亡。
  /// 戊癸日因五虎遁起壬子,故有 4 个截路空亡时(子丑戌亥)。
  static Set<DiZhi> calcJieLuKongWang(TianGan gan) {
    switch (gan) {
      case TianGan.JIA:
      case TianGan.JI:
        return const {DiZhi.SHEN, DiZhi.YOU}; // 壬申、癸酉
      case TianGan.YI:
      case TianGan.GENG:
        return const {DiZhi.WU, DiZhi.WEI}; // 壬午、癸未
      case TianGan.BING:
      case TianGan.XIN:
        return const {DiZhi.CHEN, DiZhi.SI}; // 壬辰、癸巳
      case TianGan.DING:
      case TianGan.REN:
        return const {DiZhi.YIN, DiZhi.MAO}; // 壬寅、癸卯
      case TianGan.WU:
      case TianGan.GUI:
        return const {
          DiZhi.ZI,
          DiZhi.CHOU,
          DiZhi.XU,
          DiZhi.HAI,
        }; // 壬子、癸丑、壬戌、癸亥
      default:
        throw ArgumentError('日干不应为 $gan');
    }
  }

  // ═════════════════════════════════════════════════════════
  // §7 五不遇时 — 时干克日干(限阳克阳/阴克阴)
  // ═════════════════════════════════════════════════════════

  /// 五不遇时时辰
  ///
  /// 《五不遇时歌》:
  ///   "五不遇时知岂难,定为时干克日干,
  ///    纵有奇门亦不利,损其日月不堪观。"
  ///
  /// 时干由五虎遁推得;时干克日干且 阴阳同性 时即五不遇时。
  /// 部分日干(己/庚)有 2 个五不遇时(因时辰 12 周期 vs 时干 10 周期)。
  static Set<DiZhi> calcWuBuYuShi(TianGan gan) {
    switch (gan) {
      case TianGan.JIA:
        return const {DiZhi.WU}; // 庚午时
      case TianGan.YI:
        return const {DiZhi.SI}; // 辛巳时
      case TianGan.BING:
        return const {DiZhi.CHEN}; // 壬辰时
      case TianGan.DING:
        return const {DiZhi.MAO}; // 癸卯时
      case TianGan.WU:
        return const {DiZhi.YIN}; // 甲寅时
      case TianGan.JI:
        return const {DiZhi.CHOU, DiZhi.HAI}; // 乙丑、乙亥时
      case TianGan.GENG:
        return const {DiZhi.ZI, DiZhi.XU}; // 丙子、丙戌时
      case TianGan.XIN:
        return const {DiZhi.YOU}; // 丁酉时
      case TianGan.REN:
        return const {DiZhi.SHEN}; // 戊申时
      case TianGan.GUI:
        return const {DiZhi.WEI}; // 己未时
      default:
        throw ArgumentError('日干不应为 $gan');
    }
  }

  // ═════════════════════════════════════════════════════════
  // §3 十二黑黄道 — 由日支起青龙顺推 12 时辰
  // ═════════════════════════════════════════════════════════

  /// 12 时辰序列(子→亥)
  static const List<DiZhi> _shiZhiSeq = [
    DiZhi.ZI, DiZhi.CHOU, DiZhi.YIN, DiZhi.MAO,
    DiZhi.CHEN, DiZhi.SI, DiZhi.WU, DiZhi.WEI,
    DiZhi.SHEN, DiZhi.YOU, DiZhi.XU, DiZhi.HAI,
  ];

  /// 由日支查青龙起时辰
  ///
  /// 起例口诀:
  ///   "子午青龙起在申,卯酉之日又在寅,寅申须从子上起,
  ///    巳亥在午不须论,惟有辰戌归辰位,丑未原从戌上寻。"
  static DiZhi calcQingLongStartShi(DiZhi dayZhi) {
    switch (dayZhi) {
      case DiZhi.ZI:
      case DiZhi.WU:
        return DiZhi.SHEN; // 申
      case DiZhi.MAO:
      case DiZhi.YOU:
        return DiZhi.YIN; // 寅
      case DiZhi.YIN:
      case DiZhi.SHEN:
        return DiZhi.ZI; // 子
      case DiZhi.SI:
      case DiZhi.HAI:
        return DiZhi.WU; // 午
      case DiZhi.CHEN:
      case DiZhi.XU:
        return DiZhi.CHEN; // 辰
      case DiZhi.CHOU:
      case DiZhi.WEI:
        return DiZhi.XU; // 戌
    }
  }

  /// 由日支推十二黑黄道(12 时辰 → 神)
  ///
  /// 算法:
  ///   1. 找青龙起时辰
  ///   2. 从该时辰起,12 时辰按顺序填入 12 神(青龙→明堂→...→勾陈)
  static Map<DiZhi, RiJiaHuangDaoEnum> calcTwelveHuangDao(DiZhi dayZhi) {
    final qingLongShi = calcQingLongStartShi(dayZhi);
    final qingLongIdx = _shiZhiSeq.indexOf(qingLongShi);
    final result = <DiZhi, RiJiaHuangDaoEnum>{};
    for (int i = 0; i < 12; i++) {
      final shiZhi = _shiZhiSeq[(qingLongIdx + i) % 12];
      result[shiZhi] = RiJiaHuangDaoEnum.fromOrder(i);
    }
    return result;
  }

  // ═════════════════════════════════════════════════════════
  // 查询方法(给 UI / Pan 用)
  // ═════════════════════════════════════════════════════════

  /// 时辰是否为天乙贵人
  bool isTianYiGuiRen(DiZhi shiZhi) => tianYiGuiRenZhi.contains(shiZhi);

  /// 时辰是否为截路空亡
  bool isJieLuKongWang(DiZhi shiZhi) => jieLuKongWangZhi.contains(shiZhi);

  /// 时辰是否为五不遇时
  bool isWuBuYuShi(DiZhi shiZhi) => wuBuYuShiZhi.contains(shiZhi);

  /// 取时辰对应的黑黄道神(永远非 null,因 12 时辰全覆盖)
  RiJiaHuangDaoEnum huangDaoAt(DiZhi shiZhi) => twelveHuangDao[shiZhi]!;

  /// 时辰是否为吉(黄道 + 非五不遇时 + 非截路空亡 OR 截路空亡但是天乙贵人)
  ///
  /// 综合判定:
  ///   1. 黑道 → 凶
  ///   2. 五不遇时 → 凶(无论黄道黑道)
  ///   3. 截路空亡 + 非天乙贵人 → 失吉
  ///   4. 黄道 + 不犯空亡和五不遇 → 吉
  bool isShiAuspicious(DiZhi shiZhi) {
    if (huangDaoAt(shiZhi).isHeiDao) return false;
    if (isWuBuYuShi(shiZhi)) return false;
    if (isJieLuKongWang(shiZhi) && !isTianYiGuiRen(shiZhi)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        dayJiaZi,
        xiShenDirection,
        tianYiGuiRenZhi,
        jieLuKongWangZhi,
        wuBuYuShiZhi,
        twelveHuangDao,
      ];
}
