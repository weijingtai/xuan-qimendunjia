import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:qimendunjia/navigator.dart';
import 'package:qimendunjia/di/service_locator.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistence_drift/persistence_drift.dart';
import 'package:persistence_preferences/persistence_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persistence_drift/qimendunjia/qimendunjia_module_registry.dart';

/// 初始化 dart `logging` 包，将日志桥接到 debugPrint。
void _initDartLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      debugPrint('  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('  StackTrace: ${record.stackTrace}');
    }
  });
}

Future<void> initServices() async {
  // 初始化 dart logging 包（桥接到 debugPrint）
  _initDartLogging();

  // 初始化时区数据
  tz.initializeTimeZones();

  // Web平台使用路径URL策略
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  final newDb = PersistenceDriftDatabase(
    driftDatabase(
      name: 'persistence',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final sessionRepo = PreferencesAccountSessionRepository(prefs);
  final accountDb = AccountDatabase(
    driftDatabase(
      name: 'account',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
  final identityLinkRepo = DriftAccountIdentityLinkRepository(accountDb);
  
  final bootstrapStore = DriftScopeBootstrapStore(newDb);
  final ledger = DriftScopeLedger(db: newDb, bootstrapStore: bootstrapStore);
  final resolver = ScopeResolver(
    sessionRepository: sessionRepo,
    identityLinkRepository: identityLinkRepo,
    ledger: ledger,
  );
  final resolvedScope = await resolver.resolve();
  final scopeUid = resolvedScope.scopeUid;

  final ds = DriftRecordDataSource(newDb, scopeUid: scopeUid);
  final store = LocalRecordRepository(ds, RecordAdapterRegistry([QimendunjiaModuleRegistry.codec()]));
  final recordBackedRepository = QimendunjiaModuleRegistry.repository(store: store);

  // 初始化服务定位器 (MVVM架构需要)
  serviceLocator.init(
    const _StubOfficialRuleRepository(),
    recordBackedRepository,
  );

  // 记录启动日志
  Logger('qimendunjia.example').info("奇门遁甲模块已启动");
}

void main() async {
  // 初始化服务
  await initServices();

  // 启动应用
  runApp(const QiMenDunJiaApp());
}

/// 最小化 stub：example 仅演示排盘 UI，不加载官方规则 JSON。
/// 正式 app 应注入 AssetsQimendunjiaOfficialRuleRepository（来自 persistence_assets）。
class _StubOfficialRuleRepository
    implements QimendunjiaOfficialRuleRepository {
  const _StubOfficialRuleRepository();

  @override
  Future<String> loadTenGanKeYingJson() async => '[]';
  @override
  Future<String> loadTenGanKeYingGeJuJson() async => '[]';
  @override
  Future<String> loadDoorGanKeYingJson() async => '[]';
  @override
  Future<String> loadQiYiRuGongJson() async => '[]';
  @override
  Future<String> loadQiYiRuGongDiseaseJson() async => '[]';
  @override
  Future<String> loadDoorStarKeYingJson() async => '[]';
  @override
  Future<String> loadEightDoorKeYingJson() async => '[]';
}

class QiMenDunJiaApp extends StatelessWidget {
  const QiMenDunJiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '奇门遁甲',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'NotoSansSC-Regular',
      ),
      home: const SelectionPage(),
      // 使用项目的导航生成器
      onGenerateRoute: NavigatorGenerator.generateRoute,
      // 添加路由观察者用于调试
      navigatorObservers: [NavigatorGenerator.routeObserver],
      // 调试横幅设置
      debugShowCheckedModeBanner: false,
    );
  }
}

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('奇门遁甲架构选择'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/qimendunjia');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('老架构 (Direct View)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/qimendunjia/mvvm');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('新架构 (MVVM + UseCase)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/qimendunjia/multi_jia');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('多家奇门 (时/月/年家)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/redesign_ui/smart_grid_demo');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.green,
              ),
              child: const Text('UI重设计 - 智能九宫格'),
            ),
          ],
        ),
      ),
    );
  }
}
