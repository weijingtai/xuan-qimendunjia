import 'package:metaphysics_core/enums.dart';

enum CenterGongJiGongType {
  ONLY_KUN_GONG("坤宫"), // 只在坤宫
  KUN_GEN_GONG("艮坤"), // 坤艮宫，阴遁坤二宫，阳遁艮八宫
  FOUR_WEI_GONG("四维"), // 四维宫，立春（春）在艮八，立夏（夏）在巽四，立秋（秋）在坤二，立冬（冬）在前六
  EIGTH_GONG("八宫");

  final String name;
  const CenterGongJiGongType(this.name);
  // 根据八节寄宫：
  // 立春、雨水、惊蛰（艮八宫），
  // 春分、清明、谷雨（震三宫），
  // 立夏、小满、芒种（巽四宫），
  // 夏至、小暑、大暑（离九宫），
  // 立秋、处暑、白露（坤二宫），
  // 秋分、寒露、霜降（兑七宫），
  // 立冬、小雪、大雪（乾六宫），
  // 冬至、小寒、大寒（坎一宫）

  HouTianGua getJiGong(YinYang yinYangDun, TwentyFourJieQi jieQi) {
    switch (this) {
      case KUN_GEN_GONG:
        return atKunGen(yinYangDun);
      case FOUR_WEI_GONG:
        return atFourWei(jieQi);
      case EIGTH_GONG:
        return atEightGong(jieQi);
      default:
        return atKun();
    }
  }

  /// 只寄坤二
  HouTianGua atKun() {
    return HouTianGua.Kun;
  }

  /// 寄坤二，寄艮八 根据阴阳遁寄宫
  HouTianGua atKunGen(YinYang yinYangDun) {
    return yinYangDun.isYang ? HouTianGua.Gen : HouTianGua.Kun;
  }

  HouTianGua atFourWei(TwentyFourJieQi jieQi) {
    HouTianGua atGong;
    switch (jieQi.season) {
      case FourSeasons.SPRING:
        atGong = HouTianGua.Gen;
        break;
      case FourSeasons.SUMMER:
        atGong = HouTianGua.Xun;
        break;
      case FourSeasons.AUTUMN:
        atGong = HouTianGua.Kun;
        break;
      default:
        atGong = HouTianGua.Qian;
        break;
    }
    return atGong;
  }

  HouTianGua atEightGong(TwentyFourJieQi jieQi) {
    HouTianGua atGong;
    switch (jieQi) {
      case TwentyFourJieQi.LI_CHUN:
        atGong = HouTianGua.Gen;
        break;
      case TwentyFourJieQi.CHUN_FEN:
        atGong = HouTianGua.Zhen;
        break;
      case TwentyFourJieQi.LI_XIA:
        atGong = HouTianGua.Xun;
        break;
      case TwentyFourJieQi.XIA_ZHI:
        atGong = HouTianGua.Li;
        break;
      case TwentyFourJieQi.LI_QIU:
        atGong = HouTianGua.Kun;
        break;
      case TwentyFourJieQi.QIU_FEN:
        atGong = HouTianGua.Dui;
        break;
      case TwentyFourJieQi.LI_DONG:
        atGong = HouTianGua.Qian;
        break;
      default:
        atGong = HouTianGua.Kan;
        break;
    }
    return atGong;
  }
}
