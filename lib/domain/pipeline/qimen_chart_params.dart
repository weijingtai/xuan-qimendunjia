import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
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

  @override
  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'createdAt': createdAt.toIso8601String(),
        if (question != null) 'question': question,
        'jia': jia.name,
        'arrangeType': arrangeType.name,
        'plateType': plateType.name,
      };
}
