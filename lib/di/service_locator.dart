import 'package:qimendunjia/data/datasources/cache_data_source.dart';
import 'package:qimendunjia/data/datasources/calculator/qimen_calculator_data_source.dart';
import 'package:qimendunjia/data/datasources/json_data_source.dart';
import 'package:qimendunjia/data/repositories/qimen_calculator_repository_impl.dart';
import 'package:qimendunjia/data/repositories/qimen_data_repository_impl.dart';
import 'package:qimendunjia/domain/repositories/qimen_calculator_repository.dart';
import 'package:qimendunjia/domain/repositories/qimen_data_repository.dart';
import 'package:qimendunjia/domain/usecases/arrange_pan_usecase.dart';
import 'package:qimendunjia/domain/usecases/calculate_ju_usecase.dart';
import 'package:qimendunjia/domain/usecases/select_gong_usecase.dart';
import 'package:qimendunjia/enums/enum_arrange_plate_type.dart';
import 'package:qimendunjia/enums/enum_qi_men_jia.dart';
import 'package:qimendunjia/utils/read_data_utils.dart';
import 'package:qimendunjia/utils/yue_jia_qi_men_ju_calculator.dart' show YueJiaSanYuanStrategy;
import 'package:qimendunjia/presentation/viewmodels/qimen_viewmodel.dart';
import 'package:qimendunjia/redesign_ui/core/qi_men_star_theme.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';

/// 服务定位器
///
/// 负责管理整个应用的依赖注入
/// 使用单例模式确保全局唯一的依赖容器
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  // 缓存已创建的实例
  final Map<Type, dynamic> _services = {};

  /// 初始化所有依赖
  ///
  /// [officialRules] 由 host/app 装配层注入的官方规则资源仓储（assets 后端实现）。
  /// 产品包不直接依赖任何具体存储后端（见 EXECUTOR-RULES N3）。
  void init(
    QimendunjiaOfficialRuleRepository officialRules,
    QimenRecordRepository recordRepository,
  ) {
    _services[QimenRecordRepository] = recordRepository;

    // 1. 注册数据源
    _registerDataSources(officialRules);

    // 2. 注册仓储
    _registerRepositories();

    // 3. 注册用例
    _registerUseCases();

    // 4. 注册ViewModel
    _registerViewModels();
  }

  /// 注册数据源
  void _registerDataSources(QimendunjiaOfficialRuleRepository officialRules) {
    // 官方规则读取器（基于注入的 assets 端口，无 rootBundle）
    final reader = ReadDataUtils(officialRules);
    _services[ReadDataUtils] = reader;

    // JSON 数据源（单例）
    _services[JsonDataSource] = JsonDataSource(reader);

    // 缓存数据源（单例）
    _services[CacheDataSource] = CacheDataSource();

    // 计算器数据源（双维 Map：家 × 起局法）
    // 月家：CHAI_BU = 粗分（5年一局，默认）/ ZHI_RUN = 细分（10月一局）。
    // 年家：所有 ArrangeType 同映射到一个 DataSource。
    // 日家：所有 ArrangeType 同映射（不分拆补/置润；以休门为纲）。
    _services[Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>] = {
      QiMenJia.SHI: {
        ArrangeType.CHAI_BU: ChaiBuCalculatorDataSource(),
        ArrangeType.ZHI_RUN: ZhiRunCalculatorDataSource(),
        ArrangeType.MAO_SHAN: MaoShanCalculatorDataSource(),
        ArrangeType.YIN_PAN: YinPanCalculatorDataSource(),
      },
      QiMenJia.YUE: {
        ArrangeType.CHAI_BU: YueJiaCalculatorDataSource(
            strategy: YueJiaSanYuanStrategy.COARSE),
        ArrangeType.ZHI_RUN: YueJiaCalculatorDataSource(
            strategy: YueJiaSanYuanStrategy.FINE),
      },
      QiMenJia.NIAN: {
        for (final type in ArrangeType.values) type: NianJiaCalculatorDataSource(),
      },
      QiMenJia.RI: {
        for (final type in ArrangeType.values) type: RiJiaCalculatorDataSource(),
      },
      QiMenJia.KE: {
        for (final type in ArrangeType.values) type: KeJiaCalculatorDataSource(),
      },
    };

    // 九星主题（家级配色注册表）
    // Phase 2/4 各家在自己实现内调用 registerFamilyPalette 注入颜色。
    _services[QiMenStarTheme] = DefaultQiMenStarTheme();
  }

  /// 注册仓储
  void _registerRepositories() {
    // 奇门数据仓储
    _services[QiMenDataRepository] = QiMenDataRepositoryImpl(
      get<JsonDataSource>(),
      get<CacheDataSource>(),
    );

    // 奇门计算器仓储
    _services[QiMenCalculatorRepository] = QiMenCalculatorRepositoryImpl(
      get<Map<QiMenJia, Map<ArrangeType, QiMenCalculatorDataSource>>>(),
    );
  }

  /// 注册用例
  void _registerUseCases() {
    // 计算局数用例
    _services[CalculateJuUseCase] = CalculateJuUseCase(
      get<QiMenCalculatorRepository>(),
    );

    // 排盘用例
    _services[ArrangePanUseCase] = ArrangePanUseCase(
      get<QiMenCalculatorRepository>(),
    );

    // 选宫用例
    _services[SelectGongUseCase] = SelectGongUseCase(
      get<QiMenDataRepository>(),
    );
  }

  /// 注册ViewModels
  void _registerViewModels() {
    // 奇门遁甲 ViewModel
    // 使用工厂模式，每次获取都创建新实例
    // 因为 ViewModel 需要在每个页面有独立的状态
  }

  /// 创建 QiMenViewModel 实例（工厂方法）
  QiMenViewModel createQiMenViewModel() {
    return QiMenViewModel(
      get<CalculateJuUseCase>(),
      get<ArrangePanUseCase>(),
      get<SelectGongUseCase>(),
      recordRepository: _tryGet<QimenRecordRepository>(),
    );
  }

  /// 安全获取可选服务（不存在时返回 null）
  T? _tryGet<T>() {
    final service = _services[T];
    return service is T ? service : null;
  }

  /// 获取服务实例
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// 提供官方规则读取器给传统页面（遗留静态调用迁移点，见 §10）。
  ReadDataUtils get officialRuleReader => get<ReadDataUtils>();

  /// 提供奇门数据仓储给传统页面（替代 officialRuleReader 的逐条查询）。
  QiMenDataRepository get qiMenDataRepository => get<QiMenDataRepository>();

  /// 清理所有服务
  void dispose() {
    _services.clear();
  }
}

/// 全局服务定位器实例
final serviceLocator = ServiceLocator();
