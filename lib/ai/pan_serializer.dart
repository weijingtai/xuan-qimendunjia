import 'package:metaphysics_core/enums.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_eight_gods.dart';
import 'package:qimendunjia/enums/enum_most_popular_ge_ju.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_six_jia.dart';
import 'package:qimendunjia/enums/enum_three_yuan.dart';

/// 盘信息序列化工具
///
/// 将 [QiMenPan] 转换为结构化 Map（供 AiEntity.rawData）
/// 或自然语言描述（供 AiEntity.description，直接喂给 LLM）。
class PanSerializer {
  PanSerializer._();

  static final _log = Logger('PanSerializer');

  /// 从结构化 Map 反序列化为 [QiMenPan]。
  ///
  /// 此方法从 [toMap] 输出的格式重建 QiMenPan 实体。
  /// 因为 toMap 不包含完整的 ShiJiaJu 日历数据，
  /// ShiJiaJu 仅包含从 Map 中可提取的字段（部分字段使用默认值）。
  static QiMenPan fromMap(Map<String, dynamic> map) {
    _log.info('[fromMap] starting deserialization, map keys=${map.keys.toList()}');

    final time = DateFormat('yyyy-MM-dd HH:mm').parse(map['time'] as String);
    _log.fine('[fromMap] parsed time=$time');

    final juMap = map['ju'] as Map<String, dynamic>;
    final zhiFuMap = map['zhiFu'] as Map<String, dynamic>;
    final zhiShiMap = map['zhiShi'] as Map<String, dynamic>;
    final fuFanYinMap = map['fuFanYin'] as Map<String, dynamic>;
    final gongInfoMap = map['gong_info'] as Map<String, dynamic>;

    // Parse ju description to extract juNumber and yinYangDun
    final juDesc = juMap['description'] as String; // e.g., "阳3局" or "阴7局"
    final yinYangDun = juDesc.startsWith('阳') ? YinYang.YANG : YinYang.YIN;
    final juNumber = int.parse(juDesc.replaceAll(RegExp(r'[^\d]'), ''));
    _log.fine('[fromMap] ju: $juDesc -> yinYang=${yinYangDun.name}, juNumber=$juNumber');

    final jieQi = TwentyFourJieQi.values.firstWhere(
      (e) => e.name == juMap['jieqi'],
    );
    final threeYuan = EnumThreeYuan.values.firstWhere(
      (e) => e.name == juMap['threeYuan'],
    );
    final fuTou = JiaZi.values.firstWhere(
      (e) => e.name == juMap['fuTou'],
    );
    _log.fine('[fromMap] jieQi=${jieQi.name}, threeYuan=${threeYuan.name}, fuTou=${fuTou.name}');

    // Build a minimal ShiJiaJu from available data
    final ju = ShiJiaJu(
      id: 'deserialized_${time.millisecondsSinceEpoch}',
      panDateTime: time,
      juNumber: juNumber,
      fuTouJiaZi: fuTou,
      yinYangDun: yinYangDun,
      jieQiAt: jieQi,
      jieQiStartAt: time, // Approximation — exact value not in serialized data
      jieQiEnd: jieQi, // Approximation
      jieQiEndAt: time, // Approximation
      atThreeYuan: threeYuan,
      fourZhuEightChar: map['fourZhuEightChar'] as String? ?? '',
    );

    // Parse gong_info
    final gongMapper = <HouTianGua, EachGong>{};
    for (final entry in gongInfoMap.entries) {
      final gua = _houTianGuaFromName(entry.key);
      final gongData = entry.value as Map<String, dynamic>;
      gongMapper[gua] = _parseEachGong(gua, gongData);
    }
    _log.fine('[fromMap] parsed ${gongMapper.length} gong entries: ${gongMapper.keys.map((g) => g.name).toList()}');

    // Parse geJuList
    List<EnumMostPopularGeJu>? geJuList;
    if (map['geJuList'] != null) {
      geJuList = (map['geJuList'] as List<dynamic>)
          .map((name) => EnumMostPopularGeJu.values.firstWhere(
                (e) => e.name == name,
              ))
          .toList();
    }

    final pan = QiMenPan(
      id: 'deserialized_${time.millisecondsSinceEpoch}',
      panDateTime: time,
      ju: ju,
      plateType: PlateType.ZHUAN_PAN, // Default, not in serialized data
      gongMapper: gongMapper,
      zhiFuStar: NineStarsEnum.fromName(zhiFuMap['star'] as String),
      zhiFuStarAtGong: _houTianGuaFromName(zhiFuMap['gong'] as String),
      zhiShiDoor: EightDoorEnum.fromName(zhiShiMap['door'] as String),
      zhiShiDoorAtGong: _houTianGuaFromName(zhiShiMap['gong'] as String),
      isStarFuYin: fuFanYinMap['starFuYin'] as bool? ?? false,
      isStarFanYin: fuFanYinMap['starFanYin'] as bool? ?? false,
      isDoorFuYin: fuFanYinMap['doorFuYin'] as bool? ?? false,
      isDoorFanYin: fuFanYinMap['doorFanYin'] as bool? ?? false,
      isGanFuYin: fuFanYinMap['ganFuYin'] as bool? ?? false,
      isGanFanYin: fuFanYinMap['ganFanYin'] as bool? ?? false,
      horseLocation: _diZhiFromName(map['horseLocation'] as String),
      panGeJuList: geJuList,
    );
    _log.info('[fromMap] deserialization complete: id=${pan.id}, '
        'brief=${pan.brief}, '
        'zhiFu=${pan.zhiFuStar.name}@${pan.zhiFuStarAtGong.name}, '
        'zhiShi=${pan.zhiShiDoor.name}@${pan.zhiShiDoorAtGong.name}, '
        'gongs=${pan.gongMapper.length}');
    return pan;
  }

  static EachGong _parseEachGong(HouTianGua gua, Map<String, dynamic> data) {
    return EachGong(
      gongNumber: gua.houTianOrder,
      gongGua: gua,
      star: NineStarsEnum.fromName(data['star'] as String),
      door: EightDoorEnum.fromName(data['door'] as String),
      god: EightGodsEnum.fromName(data['god'] as String),
      diGod: data['diGod'] != null
          ? EightGodsEnum.fromName(data['diGod'] as String)
          : EightGodsEnum.ZHI_FU, // Default when not serialized
      tianPan: _tianGanFromName(data['tianPan'] as String),
      diPan: _tianGanFromName(data['diPan'] as String),
      tianPanAnGan: data['anGan_tianPan'] != null
          ? _tianGanFromName(data['anGan_tianPan'] as String)
          : TianGan.JIA, // Default when not serialized
      renPanAnGan: data['anGan_renPan'] != null
          ? _tianGanFromName(data['anGan_renPan'] as String)
          : TianGan.JIA, // Default when not serialized
      yinGan: data['yinGan'] != null
          ? _tianGanFromName(data['yinGan'] as String)
          : TianGan.JIA, // Default when not serialized
      tianPanJiGan: data['tianPanJiGan'] != null
          ? _tianGanFromName(data['tianPanJiGan'] as String)
          : null,
      diPanJiGan: data['diPanJiGan'] != null
          ? _tianGanFromName(data['diPanJiGan'] as String)
          : null,
      sixJiaXunHeader: data['sixJiaXunHeader'] != null
          ? SixJia.getSixJiaByName(data['sixJiaXunHeader'] as String)
          : null,
    );
  }

  static HouTianGua _houTianGuaFromName(String name) {
    return HouTianGua.values.firstWhere((e) => e.name == name);
  }

  static TianGan _tianGanFromName(String name) {
    return TianGan.getFromValue(name) ?? TianGan.JIA;
  }

  static DiZhi _diZhiFromName(String name) {
    return DiZhi.values.firstWhere((e) => e.name == name);
  }

  /// 将盘信息序列化为结构化 Map
  static Map<String, dynamic> toMap(
    QiMenPan pan, {
    PanDisplayConfig config = const PanDisplayConfig.defaultConfig(),
  }) {
    // pan_serializer 当前仅支持时家盘的完整序列化（节气、三元、符头等字段为时家专属）；
    // 月/年/日家通过 BaseJu 的最小集合做降级序列化。
    final ju = pan.shiJiaJu;

    // 必选：宫位信息
    final gongInfo = pan.gongMapper.map((key, gong) {
      final gongData = <String, dynamic>{
        'star': gong.star.name,
        'door': gong.door.name,
        'god': gong.god.name,
        'tianPan': gong.tianPan.name,
        'diPan': gong.diPan.name,
      };

      // 可选字段
      if (config.showAnGan) {
        gongData['anGan_tianPan'] = gong.tianPanAnGan.name;
        gongData['anGan_renPan'] = gong.renPanAnGan.name;
      }
      if (config.showYinGan) {
        gongData['yinGan'] = gong.yinGan.name;
      }
      if (config.showDiGod) {
        gongData['diGod'] = gong.diGod.name;
      }
      if (config.showSixJiaXunHeader && gong.sixJiaXunHeader != null) {
        gongData['sixJiaXunHeader'] = gong.sixJiaXunHeader!.name;
      }
      if (config.showJiGan) {
        if (gong.tianPanJiGan != null) {
          gongData['tianPanJiGan'] = gong.tianPanJiGan!.name;
        }
        if (gong.diPanJiGan != null) {
          gongData['diPanJiGan'] = gong.diPanJiGan!.name;
        }
      }

      return MapEntry(key.name, gongData);
    });

    final result = <String, dynamic>{
      'brief': pan.brief,
      'time': DateFormat('yyyy-MM-dd HH:mm').format(pan.panDateTime),
      'jia': pan.ju.jia.name,
      'ju': ju == null
          ? {
              'description': '${pan.ju.jia.name}·${pan.ju.juNumber}局',
            }
          : {
              'description': ju.juDescription,
              'jieqi': ju.jieQiAt.name,
              'threeYuan': ju.atThreeYuan.name,
              'fuTou': ju.fuTouJiaZi.name,
            },
      'fourZhuEightChar': pan.ju.fourZhuEightChar,
      'zhiFu': {
        'star': pan.zhiFuStar.name,
        'gong': pan.zhiFuStarAtGong.name,
      },
      'zhiShi': {
        'door': pan.zhiShiDoor.name,
        'gong': pan.zhiShiDoorAtGong.name,
      },
      'horseLocation': pan.horseLocation.name,
      'fuFanYin': {
        'starFuYin': pan.isStarFuYin,
        'starFanYin': pan.isStarFanYin,
        'doorFuYin': pan.isDoorFuYin,
        'doorFanYin': pan.isDoorFanYin,
        'ganFuYin': pan.isGanFuYin,
        'ganFanYin': pan.isGanFanYin,
      },
      'gong_info': gongInfo,
    };

    // 可选：盘级格局列表
    if (config.showGeJuList && pan.panGeJuList != null && pan.panGeJuList!.isNotEmpty) {
      result['geJuList'] = pan.panGeJuList!.map((g) => g.name).toList();
    }

    return result;
  }

  /// 将盘信息序列化为自然语言描述
  static String toDescription(
    QiMenPan pan, {
    PanDisplayConfig config = const PanDisplayConfig.defaultConfig(),
  }) {
    final shiJiaJu = pan.shiJiaJu; // 时家专用，nullable
    final buf = StringBuffer();

    buf.writeln('【奇门遁甲盘局】');
    buf.writeln(pan.brief);
    buf.writeln('起盘时间：${DateFormat('yyyy-MM-dd HH:mm').format(pan.panDateTime)}');
    buf.writeln('四柱八字：${pan.ju.fourZhuEightChar}');
    if (shiJiaJu != null) {
      buf.writeln(
          '局信息：${shiJiaJu.juDescription}，节气${shiJiaJu.jieQiAt.name}，${shiJiaJu.atThreeYuan.name}，符头${shiJiaJu.fuTouJiaZi.name}');
    } else {
      buf.writeln('局信息：${pan.ju.jia.name}·${pan.ju.juNumber}局');
    }
    buf.writeln('值符：${pan.zhiFuStar.name}落${pan.zhiFuStarAtGong.name}宫');
    buf.writeln('值使：${pan.zhiShiDoor.name}落${pan.zhiShiDoorAtGong.name}宫');
    buf.writeln('驿马：${pan.horseLocation.name}');

    // 伏吟反吟
    final fuFanParts = <String>[];
    if (pan.isStarFuYin) fuFanParts.add('星伏吟');
    if (pan.isStarFanYin) fuFanParts.add('星反吟');
    if (pan.isDoorFuYin) fuFanParts.add('门伏吟');
    if (pan.isDoorFanYin) fuFanParts.add('门反吟');
    if (pan.isGanFuYin) fuFanParts.add('干伏吟');
    if (pan.isGanFanYin) fuFanParts.add('干反吟');
    if (fuFanParts.isNotEmpty) {
      buf.writeln('伏吟反吟：${fuFanParts.join("、")}');
    }

    // 可选：格局列表
    if (config.showGeJuList && pan.panGeJuList != null && pan.panGeJuList!.isNotEmpty) {
      buf.writeln('格局：${pan.panGeJuList!.map((g) => g.name).join("、")}');
    }

    // 九宫信息
    buf.writeln('');
    buf.writeln('【九宫信息】');
    for (final entry in pan.gongMapper.entries) {
      final gua = entry.key;
      final gong = entry.value;
      final parts = <String>[
        '星${gong.star.name}',
        '门${gong.door.name}',
        '神${gong.god.name}',
        '天盘${gong.tianPan.name}',
        '地盘${gong.diPan.name}',
      ];

      if (config.showAnGan) {
        parts.add('暗干(天)${gong.tianPanAnGan.name}');
        parts.add('暗干(人)${gong.renPanAnGan.name}');
      }
      if (config.showYinGan) {
        parts.add('隐干${gong.yinGan.name}');
      }
      if (config.showDiGod) {
        parts.add('地神${gong.diGod.name}');
      }
      if (config.showSixJiaXunHeader && gong.sixJiaXunHeader != null) {
        parts.add('旬首${gong.sixJiaXunHeader!.name}');
      }
      if (config.showJiGan) {
        if (gong.tianPanJiGan != null) {
          parts.add('天寄干${gong.tianPanJiGan!.name}');
        }
        if (gong.diPanJiGan != null) {
          parts.add('地寄干${gong.diPanJiGan!.name}');
        }
      }

      buf.writeln('${gua.name}宫：${parts.join("，")}');
    }

    return buf.toString().trimRight();
  }
}
