import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/model/center_gong_ji_gong_type.dart';
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';

final class QimenChartParams implements ModuleParams {
  final String uuid;
  final DateTime createdAt;
  final String? question;
  final QiMenJia jia;
  final ArrangeType arrangeType;
  final PlateType plateType;
  final PanSettings? panSettings;
  final KeSchemeType? keScheme;
  final FuTouSchemeType? fuTouScheme;

  const QimenChartParams({
    required this.uuid,
    required this.createdAt,
    this.question,
    required this.jia,
    required this.arrangeType,
    required this.plateType,
    this.panSettings,
    this.keScheme,
    this.fuTouScheme,
  });

  /// JSON 解码器（与 [toJson] 严格互逆）。
  ///
  /// - 缺字段套默认：`uuid` 空串、`createdAt` epoch、`question` null、
  ///   `jia` SHI、`arrangeType` CHAI_BU、`plateType` ZHUAN_PAN、
  ///   `panSettings` null、`keScheme`/`fuTouScheme` null，不抛错。
  /// - 字段存在但类型不合法（如 `uuid: 123`、`jia: 7`）抛 [FormatException]。
  /// - 枚举按 `.name` 解码；不认识的取值明确抛 [FormatException]，不静默兜底。
  /// - `panSettings` 为扁平化 JSON（9 字段全按 `.name`），缺失时套
  ///   `PanSettings.defaultSettings()`。
  factory QimenChartParams.fromJson(Map<String, dynamic> json) {
    final uuidRaw = json['uuid'];
    if (uuidRaw != null && uuidRaw is! String) {
      throw FormatException('uuid 类型不合法: $uuidRaw');
    }
    final questionRaw = json['question'];
    if (questionRaw != null && questionRaw is! String) {
      throw FormatException('question 类型不合法: $questionRaw');
    }
    final createdAtRaw = json['createdAt'];
    if (createdAtRaw != null && createdAtRaw is! String) {
      throw FormatException('createdAt 类型不合法: $createdAtRaw');
    }

    final jia = _enumByName<QiMenJia>(json['jia'], QiMenJia.values, 'jia');
    final arrangeType = _enumByName<ArrangeType>(
      json['arrangeType'],
      ArrangeType.values,
      'arrangeType',
    );
    final plateType = _enumByName<PlateType>(
      json['plateType'],
      PlateType.values,
      'plateType',
    );
    final keScheme = _enumByNameOrNull<KeSchemeType>(
      json['keScheme'],
      KeSchemeType.values,
      'keScheme',
    );
    final fuTouScheme = _enumByNameOrNull<FuTouSchemeType>(
      json['fuTouScheme'],
      FuTouSchemeType.values,
      'fuTouScheme',
    );
    final panSettingsRaw = json['panSettings'];
    if (panSettingsRaw != null && panSettingsRaw is! Map) {
      throw FormatException('panSettings 类型不合法: $panSettingsRaw');
    }

    return QimenChartParams(
      uuid: (uuidRaw as String?) ?? '',
      createdAt: _parseDateTime(createdAtRaw),
      question: questionRaw as String?,
      jia: jia ?? QiMenJia.SHI,
      arrangeType: arrangeType ?? ArrangeType.CHAI_BU,
      plateType: plateType ?? PlateType.ZHUAN_PAN,
      panSettings: panSettingsRaw is Map
          ? _decodePanSettings(Map<String, dynamic>.from(panSettingsRaw))
          : null,
      keScheme: keScheme,
      fuTouScheme: fuTouScheme,
    );
  }

  static PanSettings _decodePanSettings(Map<String, dynamic> map) {
    return PanSettings(
      arrangeType: _enumByName<ArrangeType>(
            map['arrangeType'],
            ArrangeType.values,
            'panSettings.arrangeType',
          ) ??
          ArrangeType.CHAI_BU,
      jiGong: _enumByName<CenterGongJiGongType>(
            map['jiGong'],
            CenterGongJiGongType.values,
            'panSettings.jiGong',
          ) ??
          CenterGongJiGongType.KUN_GEN_GONG,
      starMonthTokenType: _enumByName<MonthTokenTypeEnum>(
            map['starMonthTokenType'],
            MonthTokenTypeEnum.values,
            'panSettings.starMonthTokenType',
          ) ??
          MonthTokenTypeEnum.ZHU_QI,
      starFourWeiGongType: _enumByName<GongTypeEnum>(
            map['starFourWeiGongType'],
            GongTypeEnum.values,
            'panSettings.starFourWeiGongType',
          ) ??
          GongTypeEnum.GONG_GUA,
      doorFourWeiGongType: _enumByName<GongTypeEnum>(
            map['doorFourWeiGongType'],
            GongTypeEnum.values,
            'panSettings.doorFourWeiGongType',
          ) ??
          GongTypeEnum.GONG_GUA,
      godWithGongType: _enumByName<GodWithGongTypeEnum>(
            map['godWithGongType'],
            GodWithGongTypeEnum.values,
            'panSettings.godWithGongType',
          ) ??
          GodWithGongTypeEnum.GONG_GUA_ONLY,
      ganGongType: _enumByName<GanGongTypeEnum>(
            map['ganGongType'],
            GanGongTypeEnum.values,
            'panSettings.ganGongType',
          ) ??
          GanGongTypeEnum.WANG_MU,
      keScheme: _enumByName<KeSchemeType>(
            map['keScheme'],
            KeSchemeType.values,
            'panSettings.keScheme',
          ) ??
          KeSchemeType.TEN_KE_WU_ZI_JIAN_YUAN,
      fuTouScheme: _enumByName<FuTouSchemeType>(
            map['fuTouScheme'],
            FuTouSchemeType.values,
            'panSettings.fuTouScheme',
          ) ??
          FuTouSchemeType.JIA_JI_FU_TOU,
    );
  }

  static T? _enumByName<T extends Enum>(
    Object? raw,
    List<T> values,
    String field,
  ) {
    if (raw == null) return null;
    if (raw is! String) {
      throw FormatException('$field 类型不合法: $raw');
    }
    for (final v in values) {
      // 用 Dart 内置 Enum.name（标识符）比对，绕开枚举自定义的 name 字段遮蔽。
      if ((v as Enum).name == raw) return v;
    }
    throw FormatException('$field 非合法枚举名: $raw');
  }

  /// Dart 内置 [Enum.name]（标识符），绕开枚举自定义 `name` 字段（中文）遮蔽。
  static String _enumId(Enum e) => e.name;

  static T? _enumByNameOrNull<T extends Enum>(
    Object? raw,
    List<T> values,
    String field,
  ) {
    if (raw == null) return null;
    return _enumByName<T>(raw, values, field);
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      throw FormatException('createdAt 非合法 ISO-8601 时间串: $value');
    }
    if (value is DateTime) return value;
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    throw FormatException('createdAt 类型不合法: $value');
  }

  @override
  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'createdAt': createdAt.toIso8601String(),
        if (question != null) 'question': question,
        'jia': _enumId(jia),
        'arrangeType': _enumId(arrangeType),
        'plateType': _enumId(plateType),
        if (panSettings != null) 'panSettings': _encodePanSettings(panSettings!),
        if (keScheme != null) 'keScheme': _enumId(keScheme!),
        if (fuTouScheme != null) 'fuTouScheme': _enumId(fuTouScheme!),
      };

  static Map<String, dynamic> _encodePanSettings(PanSettings settings) => {
        'arrangeType': _enumId(settings.arrangeType),
        'jiGong': _enumId(settings.jiGong),
        'starMonthTokenType': _enumId(settings.starMonthTokenType),
        'starFourWeiGongType': _enumId(settings.starFourWeiGongType),
        'doorFourWeiGongType': _enumId(settings.doorFourWeiGongType),
        'godWithGongType': _enumId(settings.godWithGongType),
        'ganGongType': _enumId(settings.ganGongType),
        'keScheme': _enumId(settings.keScheme),
        'fuTouScheme': _enumId(settings.fuTouScheme),
      };
}
