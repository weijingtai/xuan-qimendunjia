import 'package:flutter_test/flutter_test.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/utils/read_data_utils.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

/// In-memory fake implementing [QimendunjiaOfficialRuleRepository].
///
/// Returns canned JSON strings so [ReadDataUtils] parsing can be verified
/// without touching real assets or the filesystem.
class _FakeOfficialRules implements QimendunjiaOfficialRuleRepository {
  const _FakeOfficialRules();

  @override
  Future<String> loadTenGanKeYingJson() async => '''
{
  "甲": {
    "甲": {"juName": "双木成林", "shortExplain": "伏吟"},
    "乙": {"juName": "青龙合灵", "shortExplain": "吉"}
  },
  "乙": {
    "甲": {"juName": "奇仪相合", "shortExplain": "吉"},
    "丙": {"juName": "玉兔入月", "shortExplain": "吉"}
  }
}''';

  @override
  Future<String> loadTenGanKeYingGeJuJson() async => '''
{
  "甲": {
    "甲": {
      "tianPan": "甲",
      "diPan": "甲",
      "jiXiong": "凶",
      "geJuNames": ["双木成林"],
      "explains": ["伏吟"]
    },
    "乙": {
      "tianPan": "甲",
      "diPan": "乙",
      "jiXiong": "吉",
      "geJuNames": ["青龙合灵"],
      "explains": ["吉"]
    }
  },
  "乙": {
    "丙": {
      "tianPan": "乙",
      "diPan": "丙",
      "jiXiong": "吉",
      "geJuNames": ["奇仪顺遂"],
      "explains": ["吉"]
    }
  }
}''';

  @override
  Future<String> loadDoorGanKeYingJson() async => '''
{
  "开": {
    "戊": "财名俱得。",
    "乙": "小财可求。"
  },
  "休": {
    "丙": "贵人印绶。"
  }
}''';

  @override
  Future<String> loadQiYiRuGongJson() async => '''
{
  "乾": {
    "乙": {
      "geJuName": "玉兔入天门",
      "geJuJiXiong": "吉",
      "description": "大发。"
    }
  }
}''';

  @override
  Future<String> loadQiYiRuGongDiseaseJson() async => '''
{
  "乾": {
    "乙": "肝胆之疾"
  }
}''';

  @override
  Future<String> loadDoorStarKeYingJson() async => '''
{
  "天蓬": {
    "开门": {
      "door": "开门",
      "star": "天蓬",
      "jiXiong": "吉",
      "description": "出行吉"
    }
  }
}''';

  @override
  Future<String> loadEightDoorKeYingJson() async => '''
{
  "开门": {
    "动应": {
      "开门": "六里，逢贵人。",
      "休门": "一里，逢贵人来。"
    },
    "静应": {
      "开门": "主有贵人。",
      "休门": "有贵人来。"
    }
  }
}''';
}

void main() {
  late ReadDataUtils reader;

  setUp(() {
    reader = ReadDataUtils(const _FakeOfficialRules());
  });

  group('ReadDataUtils via fake QimendunjiaOfficialRuleRepository', () {
    test('readTenGanKeYing parses ten gan ke ying JSON', () async {
      final result = await reader.readTenGanKeYing();
      expect(result, isNotEmpty);
      expect(result[TianGan.JIA], isNotNull);
      expect(result[TianGan.JIA]![TianGan.JIA]!.juName, '双木成林');
      expect(result[TianGan.getFromValue('乙')]![TianGan.BING]!.juName, '玉兔入月');
    });

    test('readTenGanKeYingGeJu parses ge ju JSON', () async {
      final result = await reader.readTenGanKeYingGeJu();
      expect(result, isNotEmpty);
      expect(result[TianGan.JIA]![TianGan.JIA]!.geJuNames, contains('双木成林'));
      expect(result[TianGan.getFromValue('乙')]![TianGan.BING]!.geJuNames,
          contains('奇仪顺遂'));
    });

    test('readDoorGanKeYing parses door gan ke ying JSON', () async {
      final result = await reader.readDoorGanKeYing();
      expect(result, isNotEmpty);
      expect(result[EightDoorEnum.KAI]![TianGan.WU], '财名俱得。');
      expect(result[EightDoorEnum.XIU]![TianGan.BING], '贵人印绶。');
    });

    test('readQiYiRuGong parses qi yi ru gong JSON', () async {
      final result = await reader.readQiYiRuGong();
      expect(result, isNotEmpty);
      final qian = result[HouTianGua.Qian];
      expect(qian, isNotNull);
      expect(qian![TianGan.YI]!.geJuName, '玉兔入天门');
    });

    test('readQiYiRuGongDisease parses disease JSON', () async {
      final result = await reader.readQiYiRuGongDisease();
      expect(result, isNotEmpty);
      expect(result[HouTianGua.Qian]![TianGan.YI], '肝胆之疾');
    });

    test('readDoorStarKeYing parses door star ke ying JSON', () async {
      final result = await reader.readDoorStarKeYing();
      expect(result, isNotEmpty);
      final pengOpen = result[EightDoorEnum.KAI]?[NineStarsEnum.PENG];
      expect(pengOpen, isNotNull);
      expect(pengOpen!.description, '出行吉');
    });

    test('readEightDoorKeYing parses eight door ke ying JSON', () async {
      final result = await reader.readEightDoorKeYing();
      expect(result, isNotEmpty);
      final openFix = result[EightDoorEnum.KAI]?[EightDoorEnum.XIU];
      expect(openFix, isNotNull);
      expect(openFix![YinYang.YIN]!.description, '有贵人来。');
    });
  });
}
