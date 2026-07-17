import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

const _guas = [
  HouTianGua.Xun,
  HouTianGua.Li,
  HouTianGua.Kun,
  HouTianGua.Zhen,
  HouTianGua.Center,
  HouTianGua.Dui,
  HouTianGua.Gen,
  HouTianGua.Kan,
  HouTianGua.Qian,
];

const _stars = [
  NineStarsEnum.FU,
  NineStarsEnum.YING,
  NineStarsEnum.RUI,
  NineStarsEnum.CHONG,
  NineStarsEnum.QIN,
  NineStarsEnum.ZHU,
  NineStarsEnum.REN,
  NineStarsEnum.PENG,
  NineStarsEnum.XIN,
];

const _doors = [
  EightDoorEnum.DU,
  EightDoorEnum.JING_S,
  EightDoorEnum.SI,
  EightDoorEnum.SHANG,
  EightDoorEnum.CENTER,
  EightDoorEnum.JING_W,
  EightDoorEnum.SHENG,
  EightDoorEnum.XIU,
  EightDoorEnum.KAI,
];

const _gods = [
  EightGodsEnum.ZHI_FU,
  EightGodsEnum.TENG_SHE,
  EightGodsEnum.TAI_YIN,
  EightGodsEnum.LIU_HE,
  EightGodsEnum.BAI_HU,
  EightGodsEnum.XUAN_WU,
  EightGodsEnum.JIU_DI,
  EightGodsEnum.JIU_TIAN,
  EightGodsEnum.ZHI_FU,
];

const _stems = [
  TianGan.YI,
  TianGan.BING,
  TianGan.DING,
  TianGan.WU,
  TianGan.JI,
  TianGan.GENG,
  TianGan.XIN,
  TianGan.REN,
  TianGan.GUI,
];

List<PalaceData> buildQiMenPalaceFixture() {
  return List.generate(9, (i) {
    final gong = _guas[i];
    // EachGong now uses gongNumber + gongGua (not the old gongEnum).
    // star accepts QiMenStar (NineStarsEnum implements this).
    // Removed fields from old API: gongEnum, tianJiGan, diJiGan, jiStar,
    // isTianPanDunJia, isDiPanDunJia, isTianPanJiXing, isYangDun.
    // New fields: gongNumber, tianPanJiGan, diPanJiGan, sixJiaXunHeader, isJiTianQin.
    final eachGong = EachGong(
      gongNumber: i + 1,
      gongGua: gong,
      star: _stars[i],
      door: _doors[i],
      god: _gods[i],
      diGod: _gods[(i + 1) % _gods.length],
      tianPan: _stems[i],
      diPan: _stems[(i + 3) % _stems.length],
      yinGan: _stems[(i + 2) % _stems.length],
      renPanAnGan: _stems[(i + 4) % _stems.length],
      tianPanAnGan: _stems[(i + 1) % _stems.length],
      tianPanJiGan: _stems[(i + 5) % _stems.length],
      diPanJiGan: _stems[(i + 6) % _stems.length],
      isJiTianQin: i == 2,
    );

    final marks = <String>[];
    if (i == 0) marks.add('值符');
    if (i == 2) marks.add('驿马');
    if (i == 7) marks.add('空亡');

    // PalaceData.fromEachGong no longer takes external number/diGodEnum —
    // those are derived internally from the EachGong instance.
    return PalaceData.fromEachGong(
      eachGong,
      marks: marks,
    );
  });
}
