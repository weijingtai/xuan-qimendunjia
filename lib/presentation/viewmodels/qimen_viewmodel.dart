import 'package:flutter/foundation.dart';
import 'package:enumeration/enums.dart' show EnumDatetimeType;
import 'package:logging/logging.dart';
import 'package:qimendunjia/ai/qimen_ai_service.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';
import 'package:qimendunjia/domain/pipeline/qimen_pipeline_executor.dart';
import 'package:qimendunjia/domain/pipeline/qimen_chart_params.dart';
import 'package:qimendunjia/domain/pipeline/pipeline_evidence.dart';
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
import 'package:repository_interface_divination_pipeline/repository_interface_divination_pipeline.dart';
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

  /// Pipeline 统一入参排盘执行器（可选注入）。注入后 calculateAndArrangePan 走新路径，
  /// 失败回退老路径，不打断 UI。
  final QimenPipelineExecutor? _pipelineExecutor;

  /// 最后一次走统一入参排盘的 [ChartRequest]，供测试断言 executor 被真实调用。
  ChartRequest<QimenChartParams>? lastPipelineRequest;

  /// 最后一次统一入参排盘产出的 Record（契约层 [Chart] 形态）。
  Chart? lastPipelineRecord;

  /// 本次排盘执行证据（供壳侧 E2E 测试断言 executor 真实执行）。
  /// 只读：不参与生产逻辑判断、不影响渲染。
  PipelineEvidence? _lastPipelineEvidence;
  int _pipelineCallCount = 0;

  /// 最后一次走统一入参排盘的执行证据；未走 pipeline 路径时为 null。
  @visibleForTesting
  PipelineEvidence? get lastPipelineEvidence => _lastPipelineEvidence;

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
    QimenPipelineExecutor? pipelineExecutor,
  })  : _recordRepository = recordRepository,
        _pipelineExecutor = pipelineExecutor;

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
  /// 将当前盘信息转为 [QiMenAiContext] 供聊天窗口使用。
  /// 如果尚未排盘则返回 null。
  QiMenAiContext? buildAiContext() {
    final s = _qiMenState;
    if (s is! QiMenSuccess) return null;
    final pan = s.pan;

    final entity = QiMenAiEntity(
      id: pan.id,
      type: 'qimen_pan',
      name: pan.brief,
      description: PanSerializer.toDescription(pan, config: _displayConfig),
      rawData: PanSerializer.toMap(pan, config: _displayConfig),
    );

    return QiMenAiContext(
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

      // 4. Pipeline 统一入参排盘 + 落库 Record（注入 executor 时）
      await _runPipeline(
        dateTime: dateTime,
        jia: jia,
        arrangeType: arrangeType,
        plateType: plateType,
        keScheme: keScheme ?? _panSettings.keScheme,
        fuTouScheme: fuTouScheme ?? _panSettings.fuTouScheme,
      );

      // 5. 保存排盘记录（A4 Phase 2 接线）
      _saveRecordIfAvailable(pan: pan, ju: ju);
    } catch (e) {
      _qiMenState = QiMenError(e.toString());
      _state = QiMenViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Pipeline 统一入参排盘 + 落库 Record。
  ///
  /// 注入 [QimenPipelineExecutor] 时构建 [ChartRequest] 走统一入参排盘并落库 Record；
  /// 失败只 debugPrint 回退，不打断 UI。
  Future<void> _runPipeline({
    required DateTime dateTime,
    required QiMenJia jia,
    required ArrangeType arrangeType,
    required PlateType plateType,
    required KeSchemeType keScheme,
    required FuTouSchemeType fuTouScheme,
  }) async {
    final executor = _pipelineExecutor;
    if (executor == null) return;

    final params = QimenChartParams(
      uuid: 'qimen-${dateTime.millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      question: null,
      jia: jia,
      arrangeType: arrangeType,
      plateType: plateType,
      panSettings: _panSettings,
      keScheme: keScheme,
      fuTouScheme: fuTouScheme,
    );
    final request = ChartRequest<QimenChartParams>(
      moment: DivinationMoment(
        instantUtc: dateTime.toUtc(),
        place: const GeoPoint(
          latitude: 0.0,
          longitude: 0.0,
          timeZoneId: 'Asia/Shanghai',
        ),
        reckoning: EnumDatetimeType.standard,
      ),
      params: params,
    );
    lastPipelineRequest = request;
    try {
      _pipelineCallCount++;
      final record = await executor.executeAndSave(request);
      lastPipelineRecord = record;
      _lastPipelineEvidence = PipelineEvidence(
        callCount: _pipelineCallCount,
        requestId: params.uuid,
        resultUuid: _recordUuid(record),
        module: 'qimendunjia',
        keyResult: _keyResultOf(record),
        error: null,
      );
    } catch (error, stack) {
      _lastPipelineEvidence = PipelineEvidence(
        callCount: _pipelineCallCount,
        requestId: params.uuid,
        resultUuid: null,
        module: 'qimendunjia',
        keyResult: null,
        error: error,
      );
      debugPrint('奇门 Pipeline 排盘失败，已回退老路径: $error\n$stack');
    }
  }

  /// 提取 Record 的 uuid（契约层 [Chart] 形态没有直接 uuid 字段，从 toJson 取）。
  String? _recordUuid(Chart record) {
    final json = record.toJson();
    return json['uuid'] as String?;
  }

  /// 提取页面可观察的关键结果（遁/局数），作为执行证据的 keyResult。
  ///
  /// 遁与局数由本次排盘决定（executor/calculator 计算产出），
  /// 且直接显示在奇门盘面顶部，因此能代表「这次执行真的发生了」。
  Object? _keyResultOf(Chart record) {
    final json = record.toJson();
    return {
      'juType': json['juType'],
      'juNumber': json['juNumber'],
    };
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
