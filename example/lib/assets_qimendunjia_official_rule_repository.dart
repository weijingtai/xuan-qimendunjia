import 'package:flutter/services.dart' show rootBundle;
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

/// Asset-backed implementation of [QimendunjiaOfficialRuleRepository].
///
/// Reads the official immutable rule JSON shipped inside the `qimendunjia`
/// product package's asset bundle.
///
/// This is a local copy for the example app because `persistence_assets`
/// has transitive dependency conflicts with `taiyishenshu`.
class AssetsQimendunjiaOfficialRuleRepository
    implements QimendunjiaOfficialRuleRepository {
  const AssetsQimendunjiaOfficialRuleRepository();

  static const String _tenGanKeYingPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/ten_gan_ke_ying_v1.json';
  static const String _tenGanKeYingGeJuPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/ten_gan_ke_ying_final.json';
  static const String _doorGanKeYingPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/door_gan_ke_ying.json';
  static const String _qiYiRuGongPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/gong_qi.json';
  static const String _qiYiRuGongDiseasePath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/gong_gan.json';
  static const String _starDoorKeYingPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/star_door_ke_ying.json';
  static const String _eightDoorKeYingPath =
      'packages/persistence_assets/lib/qimendunjia/assets/qi_men_dun_jia/eight_door_ke_ying.json';

  Future<String> _load(String assetKey) async {
    try {
      return await rootBundle.loadString(assetKey);
    } catch (e) {
      throw StorageError('Failed to load asset "$assetKey": $e');
    }
  }

  @override
  Future<String> loadTenGanKeYingJson() => _load(_tenGanKeYingPath);

  @override
  Future<String> loadTenGanKeYingGeJuJson() => _load(_tenGanKeYingGeJuPath);

  @override
  Future<String> loadDoorGanKeYingJson() => _load(_doorGanKeYingPath);

  @override
  Future<String> loadQiYiRuGongJson() => _load(_qiYiRuGongPath);

  @override
  Future<String> loadQiYiRuGongDiseaseJson() => _load(_qiYiRuGongDiseasePath);

  @override
  Future<String> loadDoorStarKeYingJson() => _load(_starDoorKeYingPath);

  @override
  Future<String> loadEightDoorKeYingJson() => _load(_eightDoorKeYingPath);
}
