import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_chart_ui/src/gong/gong_recipe.dart';
import 'package:metaphysics_chart_ui/src/gong/gong_slot.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_adapter.dart';
import 'package:qimendunjia/presentation/adapters/qimen_gong_ids.dart';
import 'package:qimendunjia/redesign_ui/components/palace/brief_palace_config.dart';
import 'package:qimendunjia/redesign_ui/layouts/smart_grid.dart';

void main() {
  const config = BriefPalaceConfig();

  test('adapter produces all six P0 IDs for a full palace', () {
    final data = PalaceData._test({
      'gongEnum': 'Li',
      'number': '9',
      'starEnum': 'YING',
      'doorEnum': 'JING_S',
      'godEnum': 'TENG_SHE',
      'tianPanGanEnum': 'BING',
      'diPanGanEnum': 'DING',
      'showGod': true,
      'showDoor': true,
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();

    expect(ids.contains('${QiMenGongIds.starPrimary}-9'), isTrue);
    expect(ids.contains('${QiMenGongIds.stemHeaven}-9'), isTrue);
    expect(ids.contains('${QiMenGongIds.stemEarth}-9'), isTrue);
    expect(ids.contains('${QiMenGongIds.deityPrimary}-9'), isTrue);
    expect(ids.contains('${QiMenGongIds.doorPrimary}-9'), isTrue);
  });

  test('showDoor=false omits door-primary', () {
    final data = PalaceData._test({
      'gongEnum': 'Li',
      'number': '9',
      'starEnum': 'YING',
      'doorEnum': 'JING_S',
      'godEnum': 'TENG_SHE',
      'tianPanGanEnum': 'BING',
      'diPanGanEnum': 'DING',
      'showGod': true,
      'showDoor': false,
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();

    expect(ids.contains('door-primary-9'), isFalse);
  });

  test('showGod=false omits deity-primary', () {
    final data = PalaceData._test({
      'gongEnum': 'Li',
      'number': '9',
      'starEnum': 'YING',
      'doorEnum': 'JING_S',
      'godEnum': 'TENG_SHE',
      'tianPanGanEnum': 'BING',
      'diPanGanEnum': 'DING',
      'showGod': false,
      'showDoor': true,
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();

    expect(ids.contains('deity-primary-9'), isFalse);
  });

  test('marks emitted in deterministic order', () {
    final data = PalaceData._test({
      'gongEnum': 'Gen',
      'number': '8',
      'starEnum': 'REN',
      'doorEnum': 'SHENG',
      'godEnum': 'JIU_DI',
      'tianPanGanEnum': 'REN',
      'diPanGanEnum': 'GUI',
      'showGod': true,
      'showDoor': true,
      'marks': ['值符', '驿马'],
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();
    expect(ids.contains('${QiMenGongIds.statusChief}-8'), isTrue);
    expect(ids.contains('${QiMenGongIds.statusHorse}-8'), isTrue);
  });

  test('dunjia booleans create matching mark nodes', () {
    final data = PalaceData._test({
      'gongEnum': 'Qian',
      'number': '6',
      'starEnum': 'XIN',
      'doorEnum': 'KAI',
      'godEnum': 'JIU_TIAN',
      'tianPanGanEnum': 'WU',
      'diPanGanEnum': 'JI',
      'showGod': true,
      'showDoor': true,
      'isTianPanDunjia': true,
      'isDiPanDunjia': true,
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();
    expect(ids.contains('${QiMenGongIds.markDunjiaHeaven}-6'), isTrue);
    expect(ids.contains('${QiMenGongIds.markDunjiaEarth}-6'), isTrue);
  });

  test('punishment booleans create matching mark nodes', () {
    final data = PalaceData._test({
      'gongEnum': 'Zhen',
      'number': '3',
      'starEnum': 'CHONG',
      'doorEnum': 'SHANG',
      'godEnum': 'LIU_HE',
      'tianPanGanEnum': 'JIA',
      'diPanGanEnum': 'YI',
      'showGod': true,
      'showDoor': true,
      'isTianPanJiXing': true,
    });

    final nodes = const QiMenGongAdapter().buildNodes(data, config);
    final ids = nodes.map((n) => n.id).toSet();
    expect(ids.contains('${QiMenGongIds.markPunishmentHeaven}-3'), isTrue);
  });
}

extension _PalaceDataTest on PalaceData {
  static PalaceData _test(Map<String, Object> params) {
    return PalaceData(
      gongEnum: _parseEnum<HouTianGua>(params['gongEnum']),
      number: params['number'] as String,
      starEnum: _starFromName(params['starEnum'] as String),
      doorEnum: _doorFromName(params['doorEnum'] as String),
      godEnum: _godFromName(params['godEnum'] as String),
      tianPanGanEnum: _ganFromName(params['tianPanGanEnum'] as String),
      diPanGanEnum: _ganFromName(params['diPanGanEnum'] as String),
      showGod: params['showGod'] as bool? ?? true,
      showDoor: params['showDoor'] as bool? ?? true,
      marks: (params['marks'] as List?)?.cast<String>() ?? const [],
      isTianPanDunjia: params['isTianPanDunjia'] as bool? ?? false,
      isDiPanDunjia: params['isDiPanDunjia'] as bool? ?? false,
      isTianJiGanDunjia: params['isTianJiGanDunjia'] as bool? ?? false,
      isDiJiGanDunjia: params['isDiJiGanDunjia'] as bool? ?? false,
      isTianPanJiXing: params['isTianPanJiXing'] as bool? ?? false,
      isDiPanJiXing: params['isDiPanJiXing'] as bool? ?? false,
      isTianJiGanJiXing: params['isTianJiGanJiXing'] as bool? ?? false,
      isDiJiGanJiXing: params['isDiJiGanJiXing'] as bool? ?? false,
    );
  }
}

HouTianGua _parseEnum<T>(Object? value) =>
    HouTianGua.values.firstWhere((e) => e.name == value);

QiMenStar _starFromName(String name) =>
    NineStarsEnum.values.firstWhere((e) => e.name == name);

EightDoorEnum _doorFromName(String name) =>
    EightDoorEnum.values.firstWhere((e) => e.name == name);

EightGodsEnum _godFromName(String name) =>
    EightGodsEnum.values.firstWhere((e) => e.name == name);

TianGan _ganFromName(String name) =>
    TianGan.values.firstWhere((e) => e.name == name);
