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
    final eachGong = EachGong(
      gongEnum: gong,
      star: _stars[i],
      door: _doors[i],
      god: _gods[i],
      diGod: _gods[(i + 1) % _gods.length],
      tianPan: _stems[i],
      diPan: _stems[(i + 3) % _stems.length],
      yinGan: _stems[(i + 2) % _stems.length],
      renPanAnGan: _stems[(i + 4) % _stems.length],
      tianPanAnGan: _stems[(i + 1) % _stems.length],
      tianJiGan: _stems[(i + 5) % _stems.length],
      diJiGan: _stems[(i + 6) % _stems.length],
      jiStar: _stars[(i + 1) % _stars.length],
      isTianPanDunJia: i == 0,
      isDiPanDunJia: i == 1,
      isTianPanJiXing: i == 2,
      isYangDun: true,
    );

    final marks = <String>[];
    if (i == 0) marks.add('值符');
    if (i == 2) marks.add('驿马');
    if (i == 7) marks.add('空亡');

    return PalaceData.fromEachGong(
      eachGong,
      number: _guas[i].name,
      marks: marks,
      diGodEnum: _gods[(i + 1) % _gods.length],
    );
  });
}
