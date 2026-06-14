import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

/// QiMen input state — the user's intent before submitting a pan request.
///
/// This is the single source of truth for all input fields across the 3 QiMen
/// routes (legacy, mvvm, multi_jia).  Pages bind to this model; ViewModels
/// consume it to kick off [CalculateJuUseCase] + [ArrangePanUseCase].
///
/// Design notes:
/// - Uses [QiMenJia] (not a custom `QiMenFamily` alias) to match the domain.
/// - [validationErrors] is a lazily-computed map of field→error message.
/// - [isReadyToSubmit] returns true when no errors and all required fields set.
class QiMenInputState {
  /// The chosen date/time for pan calculation.
  final DateTime? dateTime;

  /// 起盘方式 (拆补 / 置润 / 茅山 / 阴盘 / 手动)
  final ArrangeType? arrangeType;

  /// 盘类型 (转盘 / 飞盘)
  final PlateType? plateType;

  /// 家维度 (时家 / 日家 / 月家 / 年家 / 刻家)
  final QiMenJia? family;

  const QiMenInputState({
    this.dateTime,
    this.arrangeType,
    this.plateType,
    this.family,
  });

  /// A completely empty state (no selections made).
  const QiMenInputState.empty() : this();

  /// Pre-filled defaults for the common case: current time, 拆补, 转盘, 时家.
  factory QiMenInputState.defaults() {
    return QiMenInputState(
      dateTime: DateTime.now(),
      arrangeType: ArrangeType.CHAI_BU,
      plateType: PlateType.ZHUAN_PAN,
      family: QiMenJia.SHI,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns a map of field name → error message for every invalid / missing
  /// required field.  Empty map means valid.
  Map<String, String> get validationErrors {
    final errors = <String, String>{};
    if (dateTime == null) {
      errors['dateTime'] = '请选择起盘时间';
    }
    if (arrangeType == null) {
      errors['arrangeType'] = '请选择起盘方式';
    }
    if (plateType == null) {
      errors['plateType'] = '请选择盘类型';
    }
    if (family == null) {
      errors['family'] = '请选择家';
    }
    return errors;
  }

  /// True when all required fields are non-null and validation passes.
  bool get isReadyToSubmit => validationErrors.isEmpty;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  QiMenInputState copyWith({
    DateTime? dateTime,
    ArrangeType? arrangeType,
    PlateType? plateType,
    QiMenJia? family,
  }) {
    return QiMenInputState(
      dateTime: dateTime ?? this.dateTime,
      arrangeType: arrangeType ?? this.arrangeType,
      plateType: plateType ?? this.plateType,
      family: family ?? this.family,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QiMenInputState &&
          dateTime == other.dateTime &&
          arrangeType == other.arrangeType &&
          plateType == other.plateType &&
          family == other.family;

  @override
  int get hashCode => Object.hash(dateTime, arrangeType, plateType, family);

  @override
  String toString() =>
      'QiMenInputState(dateTime=$dateTime, arrangeType=$arrangeType, '
      'plateType=$plateType, family=$family)';
}
