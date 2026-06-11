import 'package:ai_core/ai/ai_context.dart';
import 'package:ai_core/ai/ai_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:qimendunjia/ai/pan_display_config.dart';
import 'package:qimendunjia/ai/pan_serializer.dart';
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

  // 状态
  QiMenViewState _state = QiMenViewState.initial;
  String? _errorMessage;

  // 数据
  BaseJu? _currentJu;
  QiMenPan? _currentPan;
  EachGong? _selectedGong;
  GongDetailInfo? _gongDetailInfo;

  // 设置
  PanSettings _panSettings = PanSettings.defaultSettings();
  PanDisplayConfig _displayConfig = const PanDisplayConfig.defaultConfig();

  QiMenViewModel(
    this._calculateJuUseCase,
    this._arrangePanUseCase,
    this._selectGongUseCase,
  );

  // Getters
  QiMenViewState get state => _state;
  String? get errorMessage => _errorMessage;
  ShiJiaJu? get currentJu =>
      _currentJu is ShiJiaJu ? _currentJu as ShiJiaJu : null;

  /// 当前局（任意家）。新代码优先使用此 getter，按 `ju.jia` 判断。
  BaseJu? get currentBaseJu => _currentJu;
  QiMenPan? get currentPan => _currentPan;
  EachGong? get selectedGong => _selectedGong;
  GongDetailInfo? get gongDetailInfo => _gongDetailInfo;
  PanSettings get panSettings => _panSettings;
  PanDisplayConfig get displayConfig => _displayConfig;

  bool get isLoading =>
      _state == QiMenViewState.calculating ||
      _state == QiMenViewState.arranging ||
      _state == QiMenViewState.loadingGongDetail;

  bool get hasError => _state == QiMenViewState.error;
  bool get hasData => _currentPan != null;

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
    final pan = _currentPan;
    if (pan == null) return null;

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
      _currentJu = ju;

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
      _currentPan = pan;

      // 3. 成功
      _state = QiMenViewState.success;
      notifyListeners();
    } catch (e) {
      _state = QiMenViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
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

      if (_currentPan == null) {
        throw Exception('请先排盘');
      }

      final detailInfo = await _selectGongUseCase.execute(
        SelectGongParams(
          pan: _currentPan!,
          gongGua: gong.gongGua,
        ),
      );
      _gongDetailInfo = detailInfo;

      _state = QiMenViewState.success;
      notifyListeners();
    } catch (e) {
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
    _currentPan = pan;
    _currentJu = pan.shiJiaJu;
    _selectedGong = null;
    _gongDetailInfo = null;
    _errorMessage = null;
    _state = QiMenViewState.success;
    notifyListeners();
    _log.info('[loadExternalPan] state updated to success');
  }

  /// 重置状态
  void reset() {
    _state = QiMenViewState.initial;
    _errorMessage = null;
    _currentJu = null;
    _currentPan = null;
    _selectedGong = null;
    _gongDetailInfo = null;
    notifyListeners();
  }
}
