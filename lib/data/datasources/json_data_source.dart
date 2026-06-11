import 'package:qimendunjia/utils/read_data_utils.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/model/door_star_ke_ying.dart';
import 'package:qimendunjia/model/eight_door_ke_ying.dart';
import 'package:qimendunjia/model/qi_yi_ru_gong.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying_ge_ju.dart';

/// JSON 数据源
///
/// 负责加载和缓存 JSON 数据文件
/// 使用懒加载策略，只在需要时加载
class JsonDataSource {
  final ReadDataUtils _reader;
  final Map<String, dynamic> _cache = {};

  JsonDataSource(this._reader);

  /// 加载十干克应数据
  Future<Map<TianGan, Map<TianGan, TenGanKeYing>>> loadTenGanKeYing() async {
    const key = 'ten_gan_ke_ying';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<TianGan, Map<TianGan, TenGanKeYing>>;
    }
    final data = await _reader.readTenGanKeYing();
    _cache[key] = data;
    return data;
  }

  /// 加载十干克应格局数据
  Future<Map<TianGan, Map<TianGan, TenGanKeYingGeJu>>>
      loadTenGanKeYingGeJu() async {
    const key = 'ten_gan_ke_ying_ge_ju';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<TianGan, Map<TianGan, TenGanKeYingGeJu>>;
    }
    final data = await _reader.readTenGanKeYingGeJu();
    _cache[key] = data;
    return data;
  }

  /// 加载门星克应数据
  Future<Map<EightDoorEnum, Map<NineStarsEnum, DoorStarKeYing>>>
      loadDoorStarKeYing() async {
    const key = 'door_star_ke_ying';
    if (_cache.containsKey(key)) {
      return _cache[key]
          as Map<EightDoorEnum, Map<NineStarsEnum, DoorStarKeYing>>;
    }
    final data = await _reader.readDoorStarKeYing();
    _cache[key] = data;
    return data;
  }

  /// 加载八门克应数据
  Future<Map<EightDoorEnum, Map<EightDoorEnum, Map<YinYang, EightDoorKeYing>>>>
      loadEightDoorKeYing() async {
    const key = 'eight_door_ke_ying';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<EightDoorEnum,
          Map<EightDoorEnum, Map<YinYang, EightDoorKeYing>>>;
    }
    final data = await _reader.readEightDoorKeYing();
    _cache[key] = data;
    return data;
  }

  /// 加载三奇入宫数据
  Future<Map<HouTianGua, Map<TianGan, QiYiRuGong>>> loadQiYiRuGong() async {
    const key = 'qi_yi_ru_gong';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<HouTianGua, Map<TianGan, QiYiRuGong>>;
    }
    final data = await _reader.readQiYiRuGong();
    _cache[key] = data;
    return data;
  }

  /// 加载八门干克应数据
  Future<Map<EightDoorEnum, Map<TianGan, String>>>
      loadEightDoorGanKeYing() async {
    const key = 'eight_door_gan_ke_ying';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<EightDoorEnum, Map<TianGan, String>>;
    }
    final data = await _reader.readDoorGanKeYing();
    _cache[key] = data;
    return data;
  }

  /// 加载天干入宫疾病数据
  Future<Map<HouTianGua, Map<TianGan, String>>>
      loadTianGanRuGongDisease() async {
    const key = 'tian_gan_ru_gong_disease';
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<HouTianGua, Map<TianGan, String>>;
    }
    final data = await _reader.readQiYiRuGongDisease();
    _cache[key] = data;
    return data;
  }

  /// 清除所有已加载的数据缓存
  void clearCache() {
    _cache.clear();
  }

  /// 获取缓存大小
  int get cacheSize => _cache.length;

  /// 检查是否已加载某个数据集
  bool isLoaded(String key) => _cache.containsKey(key);
}
