import 'package:qimendunjia/ai/qimen_ai_service.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';
import 'package:qimendunjia/di/service_locator.dart';
import 'package:qimendunjia/domain/usecases/arrange_pan_usecase.dart';
import 'package:qimendunjia/domain/usecases/calculate_ju_usecase.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';

/// 奇门遁甲工具集实现
///
/// 此文件在 shell 层实现，不依赖 ai_core。
/// 提供起局排盘能力给 AI Agent。
class QiMenAgentToolImpl implements QiMenAgentTool {
  final ServiceLocator _locator;

  QiMenAgentToolImpl([ServiceLocator? locator])
      : _locator = locator ?? ServiceLocator();

  @override
  String get name => 'qimen_tools';

  @override
  String get description =>
      '奇门遁甲排盘工具。用于根据指定时间（或当前时间）获取奇门局信息，包括局数、干支、九星、八门、八神等落宫信息。';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'year': {'type': 'integer', 'description': '公历年份，默认当前年份'},
          'month': {'type': 'integer', 'description': '公历月份 (1-12)，默认当前月份'},
          'day': {'type': 'integer', 'description': '公历日期，默认当前日期'},
          'hour': {'type': 'integer', 'description': '公历小时 (0-23)，默认当前小时'},
          'minute': {'type': 'integer', 'description': '公历分钟，默认当前分钟'},
          'arrange_type': {
            'type': 'string',
            'enum': ['CHAI_BU', 'ZHI_RUN', 'MAO_SHAN', 'YIN_PAN'],
            'description':
                '排盘方式：拆补法(CHAI_BU)、置润法(ZHI_RUN)、茅山法(MAO_SHAN)、阴盘(YIN_PAN)。默认为拆补法。',
          },
        },
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    try {
      final now = DateTime.now();
      final year = args['year'] as int? ?? now.year;
      final month = args['month'] as int? ?? now.month;
      final day = args['day'] as int? ?? now.day;
      final hour = args['hour'] as int? ?? now.hour;
      final minute = args['minute'] as int? ?? now.minute;

      final dateTime = DateTime(year, month, day, hour, minute);

      final typeStr = args['arrange_type'] as String? ?? 'CHAI_BU';
      final arrangeType = ArrangeType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ArrangeType.CHAI_BU,
      );

      final calculateJu = _locator.get<CalculateJuUseCase>();
      final juParams = CalculateJuParams(
        dateTime: dateTime,
        arrangeType: arrangeType,
      );
      final ju = await calculateJu.execute(juParams);

      final arrangePan = _locator.get<ArrangePanUseCase>();
      final panParams = ArrangePanParams(
        ju: ju,
        plateType: PlateType.ZHUAN_PAN,
        settings: PanSettings.defaultSettings(),
      );
      final pan = await arrangePan.execute(panParams);

      return PanSerializer.toMap(pan);
    } catch (e) {
      return {'error': '排盘失败: $e'};
    }
  }

  @override
  Map<String, dynamic> toFunctionDeclaration() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': parametersSchema,
      },
    };
  }
}
