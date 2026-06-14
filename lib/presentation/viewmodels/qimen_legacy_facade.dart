import 'package:flutter/foundation.dart';
import 'package:metaphysics_core/enums.dart';
import 'package:qimendunjia/domain/entities/base_ju.dart';
import 'package:qimendunjia/domain/entities/each_gong.dart';
import 'package:qimendunjia/domain/entities/qimen_pan.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/domain/usecases/arrange_pan_usecase.dart';
import 'package:qimendunjia/domain/usecases/calculate_ju_usecase.dart';
import 'package:qimendunjia/domain/usecases/select_gong_usecase.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';

/// Legacy Facade — 翻译层
///
/// 接受旧 UI 页面的意图调用（beatiful_page / scalable_beatiful_page），
/// 将其委托给 UseCase 层处理，再以旧页面可消费的形状暴露状态。
///
/// 此文件 **禁止** 直接引入：
/// - ChaiBuCalculator / ZhiRunCalculator / MaoShanCalculator / YinPanCalculator
/// - ShiJiaQiMen 构造
/// - officialRuleReader
///
/// Q2 迁移时旧页面将逐步切换到此 Facade。
class QiMenLegacyFacade extends ChangeNotifier {
  // ==================== 依赖 ====================
  final CalculateJuUseCase _calculateJuUseCase;
  final ArrangePanUseCase _arrangePanUseCase;
  final SelectGongUseCase _selectGongUseCase;

  QiMenLegacyFacade(
    this._calculateJuUseCase,
    this._arrangePanUseCase,
    this._selectGongUseCase,
  );

  // ==================== 状态 ====================
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // ==================== 数据（domain entities） ====================
  BaseJu? _currentJu;
  QiMenPan? _currentPan;

  /// 当前局信息（任意家）
  BaseJu? get currentJu => _currentJu;

  /// 当前完整盘（domain entity）
  QiMenPan? get currentPan => _currentPan;

  /// 是否已有排盘数据
  bool get hasData => _currentPan != null;

  // ==================== 宫位选择 ====================
  EachGong? _selectedGong;
  GongDetailInfo? _selectedGongDetail;

  EachGong? get selectedGong => _selectedGong;
  GongDetailInfo? get selectedGongDetail => _selectedGongDetail;

  // ==================== 旧页面兼容快捷访问 ====================

  /// 按卦象取宫（旧页面常用模式）
  EachGong? getGong(HouTianGua gua) => _currentPan?.getGong(gua);

  // ==================== 意图：计算并排盘 ====================

  /// 接受旧 UI 的排盘意图
  ///
  /// [dateTime]      起盘时间
  /// [arrangeType]   起盘方式（拆补/置润/茅山/阴盘）
  /// [plateType]     盘类型（转盘/飞盘）
  /// [jia]           家维度（默认时家）
  /// [settings]      排盘设置（可选，不传则用默认）
  Future<void> calculateAndArrangePan({
    required DateTime dateTime,
    required ArrangeType arrangeType,
    required PlateType plateType,
    QiMenJia jia = QiMenJia.SHI,
    PanSettings? settings,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. 计算局数
      final ju = await _calculateJuUseCase.execute(
        CalculateJuParams(
          dateTime: dateTime,
          jia: jia,
          arrangeType: arrangeType,
        ),
      );
      _currentJu = ju;

      // 2. 排盘
      final pan = await _arrangePanUseCase.execute(
        ArrangePanParams(
          ju: ju,
          plateType: plateType,
          settings: settings ?? PanSettings.defaultSettings(),
        ),
      );
      _currentPan = pan;
      _selectedGong = null;
      _selectedGongDetail = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 意图：选择宫位 ====================

  /// 接受旧 UI 的宫位选择意图
  ///
  /// [gongGua] 要选择的宫位卦象
  Future<void> selectGong(HouTianGua gongGua) async {
    if (_currentPan == null) {
      _errorMessage = '请先排盘';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final gong = _currentPan!.getGong(gongGua);
      if (gong == null) {
        throw Exception('未找到 $gongGua 宫');
      }
      _selectedGong = gong;

      _selectedGongDetail = await _selectGongUseCase.execute(
        SelectGongParams(pan: _currentPan!, gongGua: gongGua),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 取消宫位选择
  void unselectGong() {
    _selectedGong = null;
    _selectedGongDetail = null;
    notifyListeners();
  }

  // ==================== 意图：重置 ====================

  void reset() {
    _currentJu = null;
    _currentPan = null;
    _selectedGong = null;
    _selectedGongDetail = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
