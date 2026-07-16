import 'package:ai_core/ai/ai_context.dart';
import 'package:ai_core/ai/ai_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';
import 'package:qimendunjia/presentation/models/qimen_state.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/entities/shi_jia_ju.dart';
import 'package:qimendunjia/domain/usecases/arrange_pan_usecase.dart';
import 'package:qimendunjia/domain/usecases/calculate_ju_usecase.dart';
import 'package:qimendunjia/domain/usecases/select_gong_usecase.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_fu_tou_scheme.dart';
import 'package:qimendunjia/enums/enum_ke_scheme.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

/// 奇门遁甲视图状态
enum QiMenViewState {
  /// 初始状态
  initial,

  /// 计算中
  calculating,

  /// 排盘中
  arranging,

  /// 加载宫位详情中
  loadingGongDetail,

  /// 成功
  success,

  /// 错误
  error,
}

/// 奇门遁甲 ViewModel
///
/// 负责管理奇门遁甲界面的状态和业务逻辑
/// 遵循 MVVM 架构模式
class QiMenViewModel extends ChangeNotifier {
  static final _log = Logger('QiMenViewModel');

  // 用例
  final CalculateJuUseCase _calculateJuUseCase;
  final ArrangePanUseCase _arrangePanUseCase;
  final SelectGongUseCase _selectGongUseCase;

  // 记录仓储（A4 Phase 2 接线：排盘完成后保存记录）
  final QimenRecordRepository? _recordRepository;

  // ==================== 密封状态（Q3 新增） ====================

  /// 核心状态：idle → calculating → success / error
  QiMenState _qiMenState = const QiMenIdle();

  /// 当前密封状态，新代码优先使用此 getter + pattern matching。
  QiMenState get qiMenState => _qiMenState;

  // ==================== 向后兼容：详细子状态 ====================
  QiMenViewState _state = QiMenViewState.initial;
  String? _errorMessage;

  // 宫位选择子状态（独立于核心状态）
  EachGong? _selectedGong;
  GongDetailInfo? _gongDetailInfo;

  // 设置
  PanSettings _panSettings = PanSettings.defaultSettings();
  PanDisplayConfig _displayConfig = const PanDisplayConfig.defaultConfig();

  QiMenViewModel(
    this._calculateJuUseCase,
    this._arrangePanUseCase,
    this._selectGongUseCase, {
    QimenRecordRepository? recordRepository,
  }) : _recordRepository = recordRepository;

  // Getters
  QiMenViewState get state => _state;
  String? get errorMessage {
    final s = _qiMenState;
    if (s is QiMenError) return s.message;
    return _errorMessage;
  }

  /// 时家局（向后兼容）；非时家盘返回 null。
  ShiJiaJu? get currentJu {
    final s = _qiMenState;
    if (s is QiMenSuccess && s.ju is ShiJiaJu) return s.ju as ShiJiaJu;
    return null;
  }

  /// 当前局（任意家）。新代码优先使用此 getter，按 `ju.jia` 判断。
  BaseJu? get currentBaseJu {
    final s = _qiMenState;
    return s is QiMenSuccess ? s.ju : null;
  }

  QiMenPan? get currentPan {
    final s = _qiMenState;
    return s is QiMenSuccess ? s.pan : null;
  }

  EachGong? get selectedGong => _selectedGong;
  GongDetailInfo? get gongDetailInfo => _gongDetailInfo;
  PanSettings get panSettings => _panSettings;
  PanDisplayConfig get displayConfig => _displayConfig;

  bool get isLoading => _qiMenState is QiMenCalculating ||
      _state == QiMenViewState.loadingGongDetail;

  bool get hasError => _qiMenState is QiMenError || _state == QiMenViewState.error;
  bool get hasData => _qiMenState is QiMenSuccess;

  /// 更新排盘设置
  void updatePanSettings(PanSettings settings) {
    _panSettings = settings;
    notifyListeners();
  }

  /// 更新 AI 显示配置
  void updateDisplayConfig(PanDisplayConfig config) {
    _displayConfig = config;
    notifyListeners();
  }

  /// 构建 AI 上下文
  ///
  /// 将当前盘信息转为 [AiContext] 供聊天窗口使用。
  /// 如果尚未排盘则返回 null。
  AiContext? buildAiContext() {
    final s = _qiMenState;
    if (s is! QiMenSuccess) return null;
    final pan = s.pan;

    final entity = AiEntity(
      id: pan.id,
      type: 'qimen_pan',
      name: pan.brief,
      description: PanSerializer.toDescription(pan, config: _displayConfig),
      rawData: PanSerializer.toMap(pan, config: _displayConfig),
    );

    return AiContext(
      moduleName: 'xuan-qimendunjia',
      intention: '用户已排好一个奇门局，请根据盘局信息进行分析。如需排其他时间的盘，可使用 qimen_tools 工具。',
      entities: [entity],
    );
  }

  /// 计算并排盘
  ///
  /// [dateTime] 起盘时间
  /// [jia] 家维度（默认时家；日/月/年家在 Phase 2/3/4 接入后才可用）
  /// [arrangeType] 起盘方式
  /// [plateType] 盘类型
  /// [keScheme] 刻家专用：刻制方案；不传则用 [_panSettings.keScheme]
  /// [fuTouScheme] 刻家专用：拆补法符头派别；不传则用 [_panSettings.fuTouScheme]
  Future<void> calculateAndArrangePan({
    required DateTime dateTime,
    QiMenJia jia = QiMenJia.SHI,
    required ArrangeType arrangeType,
    required PlateType plateType,
    KeSchemeType? keScheme,
    FuTouSchemeType? fuTouScheme,
  }) async {
    try {
      // 1. 计算局数
      _qiMenState = const QiMenCalculating();
      _state = QiMenViewState.calculating;
      _errorMessage = null;
      notifyListeners();

      final ju = await _calculateJuUseCase.execute(
        CalculateJuParams(
          dateTime: dateTime,
          jia: jia,
          arrangeType: arrangeType,
          keScheme: keScheme ?? _panSettings.keScheme,
          fuTouScheme: fuTouScheme ?? _panSettings.fuTouScheme,
        ),
      );

      // 2. 排盘
      _state = QiMenViewState.arranging;
      notifyListeners();

      final pan = await _arrangePanUseCase.execute(
        ArrangePanParams(
          ju: ju,
          plateType: plateType,
          settings: _panSettings,
        ),
      );

      // 3. 成功
      _qiMenState = QiMenSuccess(pan: pan, ju: ju);
      _state = QiMenViewState.success;
      notifyListeners();

      // 4. 保存排盘记录（A4 Phase 2 接线）
      _saveRecordIfAvailable(pan: pan, ju: ju);
    } catch (e) {
      _qiMenState = QiMenError(e.toString());
      _state = QiMenViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 保存排盘记录至仓储（fire-and-forget，不影响排盘流程）
  void _saveRecordIfAvailable({required QiMenPan pan, required BaseJu ju}) {
    final repo = _recordRepository;
    if (repo == null) return;

    final contract = QimenDivinationRecordContract(
      uuid: pan.id,
      createdAt: DateTime.now(),
      datetimeJson: pan.panDateTime.toIso8601String(),
      juType: ju.jia.name,
      juNumber: ju.juNumber,
    );
    repo.saveRecord(contract).catchError((Object error, StackTrace stack) {
      _log.warning('保存排盘记录失败，已忽略', error, stack);
      return '';
    });
  }

  /// 选择宫位并加载详情
  ///
  /// [gong] 要选择的宫位
  Future<void> selectGong(EachGong gong) async {
    try {
      _state = QiMenViewState.loadingGongDetail;
      _selectedGong = gong;
      _errorMessage = null;
      notifyListeners();

      final pan = currentPan;
      if (pan == null) {
        throw Exception('请先排盘');
      }

      final detailInfo = await _selectGongUseCase.execute(
        SelectGongParams(
          pan: pan,
          gongGua: gong.gongGua,
        ),
      );
      _gongDetailInfo = detailInfo;

      _state = QiMenViewState.success;
      notifyListeners();
    } catch (e) {
      // 宫位详情加载失败不影响核心状态（pan 仍有效）
      _state = QiMenViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 取消选择宫位
  void unselectGong() {
    _selectedGong = null;
    _gongDetailInfo = null;
    _state = QiMenViewState.success;
    notifyListeners();
  }

  /// 加载外部盘（从 AI Tool 排盘结果拉起）。
  ///
  /// 将 AI 排盘结果直接加载到当前视图，不关闭 Drawer。
  void loadExternalPan(QiMenPan pan) {
    _log.info('[loadExternalPan] loading external pan: '
        'id=${pan.id}, brief=${pan.brief}, '
        'time=${pan.panDateTime}, '
        'gongs=${pan.gongMapper.length}');
    _qiMenState = QiMenSuccess(pan: pan, ju: pan.ju);
    _selectedGong = null;
    _gongDetailInfo = null;
    _errorMessage = null;
    _state = QiMenViewState.success;
    notifyListeners();
    _log.info('[loadExternalPan] state updated to success');
  }

  /// 重置状态
  void reset() {
    _qiMenState = const QiMenIdle();
    _state = QiMenViewState.initial;
    _errorMessage = null;
    _selectedGong = null;
    _gongDetailInfo = null;
    notifyListeners();
  }
}
