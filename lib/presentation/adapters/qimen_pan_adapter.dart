import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:tuple/tuple.dart';

/// Adapter: QiMenPan (domain entity) → Legacy display state.
///
/// One-way only. Missing required fields throw [StateError], not silently
/// default.
///
/// Extracts all data that legacy pages (beatiful_page,
/// scalable_beatiful_page, shi_jia_qi_men_view_model) previously obtained
/// from ShiJiaQiMen, and re-derives it from QiMenPan + ShiJiaJu.
class LegacyQiMenDisplayState {
  /// 值使门
  final EightDoorEnum zhiShiDoor;

  /// 值符星 (NineStarsEnum)
  final NineStarsEnum zhiFuStar;

  /// 旬首天干
  final TianGan xunHeaderTianGan;

  /// 时空 (时柱旬空)
  final Tuple2<DiZhi, DiZhi> timeXunKong;

  /// 日柱旬空
  final Tuple2<DiZhi, DiZhi> dayXunKong;

  /// 月柱旬空
  final Tuple2<DiZhi, DiZhi> monthXunKong;

  /// 年柱旬空
  final Tuple2<DiZhi, DiZhi> yearXunKong;

  /// 马星
  final DiZhi horseLocation;

  /// 月将
  final MonthToken monthToken;

  /// 日家甲子
  final JiaZi dayJiaZi;

  /// 时家甲子
  final JiaZi timeJiaZi;

  /// 阴阳遁
  final YinYang yinYangDun;

  /// 局数
  final int juNumber;

  /// 节气
  final TwentyFourJieQi jieQi;

  /// 四柱八字
  final String fourZhuEightChar;

  /// 六甲旬首
  final SixJia sixJiaXunHeader;

  /// 是否六击星
  final bool isSixJiXing;

  /// 值符天干
  final TianGan zhiFuGan;

  /// 值符所在宫
  final HouTianGua zhiFuStarAtGong;

  /// 值使门所在宫
  final HouTianGua zhiShiDoorAtGong;

  const LegacyQiMenDisplayState({
    required this.zhiShiDoor,
    required this.zhiFuStar,
    required this.xunHeaderTianGan,
    required this.timeXunKong,
    required this.dayXunKong,
    required this.monthXunKong,
    required this.yearXunKong,
    required this.horseLocation,
    required this.monthToken,
    required this.dayJiaZi,
    required this.timeJiaZi,
    required this.yinYangDun,
    required this.juNumber,
    required this.jieQi,
    required this.fourZhuEightChar,
    required this.sixJiaXunHeader,
    required this.isSixJiXing,
    required this.zhiFuGan,
    required this.zhiFuStarAtGong,
    required this.zhiShiDoorAtGong,
  });
}

/// Converts a [QiMenPan] domain entity into a [LegacyQiMenDisplayState]
/// that legacy pages can consume without importing calculators or ruleReaders.
///
/// One-way only: QiMenPan → LegacyQiMenDisplayState.
/// Missing required fields throw [StateError], not silently default.
class QiMenPanAdapter {
  QiMenPanAdapter._();

  /// Convert [QiMenPan] to legacy display state.
  ///
  /// Requires the pan's ju to be a [ShiJiaJu] (时家盘).
  /// Throws [StateError] if required data is missing.
  static LegacyQiMenDisplayState convert(QiMenPan pan) {
    final shiJiaJu = pan.shiJiaJu;
    if (shiJiaJu == null) {
      throw StateError(
        'QiMenPanAdapter.convert requires a ShiJiaJu (时家盘). '
        'Got ju type: ${pan.ju.runtimeType}',
      );
    }

    // Derive time JiaZi from fourZhuEightChar
    final eightCharList = shiJiaJu.fourZhuEightChar.split(' ');
    if (eightCharList.length < 4) {
      throw StateError(
        'fourZhuEightChar must have 4 parts, got: ${shiJiaJu.fourZhuEightChar}',
      );
    }

    final yearJiaZi = JiaZi.getFromGanZhiValue(eightCharList[0]);
    final monthJiaZi = JiaZi.getFromGanZhiValue(eightCharList[1]);
    final dayJiaZi = JiaZi.getFromGanZhiValue(eightCharList[2]);
    final timeJiaZi = JiaZi.getFromGanZhiValue(eightCharList[3]);

    if (yearJiaZi == null ||
        monthJiaZi == null ||
        dayJiaZi == null ||
        timeJiaZi == null) {
      throw StateError(
        'Failed to parse JiaZi from fourZhuEightChar: '
        '${shiJiaJu.fourZhuEightChar}',
      );
    }

    // Derive xun header
    final sixJiaXunHeader = SixJia.getSixJiaByJiaZi(timeJiaZi.xunHeader);
    final xunHeaderTianGan = sixJiaXunHeader.gan;

    // Derive zhiFuGan: follows the time stem, except when it's JIA
    var zhiFuGan = timeJiaZi.gan;
    if (zhiFuGan == TianGan.JIA) {
      zhiFuGan = xunHeaderTianGan;
    }

    // zhiFuStar must be NineStarsEnum for legacy pages
    final zhiFuStar = pan.zhiFuStar;
    if (zhiFuStar is! NineStarsEnum) {
      throw StateError(
        'zhiFuStar must be NineStarsEnum, got: ${zhiFuStar.runtimeType}',
      );
    }

    return LegacyQiMenDisplayState(
      zhiShiDoor: pan.zhiShiDoor,
      zhiFuStar: zhiFuStar,
      xunHeaderTianGan: xunHeaderTianGan,
      timeXunKong: timeJiaZi.getKongWang(),
      dayXunKong: dayJiaZi.getKongWang(),
      monthXunKong: monthJiaZi.getKongWang(),
      yearXunKong: yearJiaZi.getKongWang(),
      horseLocation: pan.horseLocation,
      monthToken: MonthToken.fromDiZhi(monthJiaZi.diZhi),
      dayJiaZi: dayJiaZi,
      timeJiaZi: timeJiaZi,
      yinYangDun: shiJiaJu.yinYangDun,
      juNumber: shiJiaJu.juNumber,
      jieQi: shiJiaJu.jieQiAt,
      fourZhuEightChar: shiJiaJu.fourZhuEightChar,
      sixJiaXunHeader: sixJiaXunHeader,
      isSixJiXing: sixJiaXunHeader.isSixJiXing(pan.zhiFuStarAtGong),
      zhiFuGan: zhiFuGan,
      zhiFuStarAtGong: pan.zhiFuStarAtGong,
      zhiShiDoorAtGong: pan.zhiShiDoorAtGong,
    );
  }
}
