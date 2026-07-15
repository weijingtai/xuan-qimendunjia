import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:metaphysics_chart_ui/metaphysics_chart_ui.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qi_men_star.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_adapter.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_ids.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

const config = BriefPalaceConfig();

PalaceData _fromGong(HouTianGua gong, {List<String> marks = const []}) {
  return PalaceData.fromEachGong(
    EachGong(
      gongNumber: 1,
      gongGua: gong,
      star: NineStarsEnum.PENG,
      door: EightDoorEnum.XIU,
      god: EightGodsEnum.ZHI_FU,
      diGod: EightGodsEnum.TENG_SHE,
      tianPan: TianGan.YI,
      diPan: TianGan.BING,
      tianPanAnGan: TianGan.DING,
      renPanAnGan: TianGan.WU,
      yinGan: TianGan.JI,
      isJiTianQin: false,
    ),
    marks: marks,
  );
}

void main() {
  test('adapter produces all six P0 IDs for a full palace', () {
    final data = _fromGong(HouTianGua.Li);
    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();

    expect(ids.contains('star-primary-1'), isTrue);
    expect(ids.contains('stem-heaven-1'), isTrue);
    expect(ids.contains('stem-earth-1'), isTrue);
    expect(ids.contains('deity-primary-1'), isTrue);
    expect(ids.contains('door-primary-1'), isTrue);
  });

  test('marks emitted for 值符 and 驿马', () {
    final data = _fromGong(HouTianGua.Gen, marks: ['值符', '驿马']);
    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();
    expect(ids.contains('status-chief-1'), isTrue);
    expect(ids.contains('status-horse-1'), isTrue);
  });

  test('adapter returns non-empty node list', () {
    final data = _fromGong(HouTianGua.Xun);
    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    expect(nodes, isNotEmpty);
    expect(nodes.where((n) => n.priority == Tier.p0).length, greaterThanOrEqualTo(5));
  });
}
