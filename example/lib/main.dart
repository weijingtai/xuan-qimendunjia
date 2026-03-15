import 'package:common/common_logger.dart';
import 'package:common/services/ai_service.dart';
import 'package:common/services/ai_registry.dart';
import 'package:ai_core/ai_core.dart';
import 'package:ai_core/utils/ai_bootstrap.dart';
import 'package:ai_core/services/ai_service_impl.dart';
import 'package:ai_core/services/llm/llm_service.dart';
import 'package:qimendunjia/ai/qimen_ai_integration.dart';
import 'package:qimendunjia/ai/qimen_ai_action.dart';
import 'package:qimendunjia/ai/qimen_agent_tool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:qimendunjia/navigator.dart';
import 'package:qimendunjia/di/service_locator.dart';
import 'package:provider/provider.dart';

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

void initQimenModule() {
  // 注册 Action 和 Tool
  AiRegistry.register(
    actions: [QiMenAnalyzeAction()],
    tools: [QiMenAgentTool()],
  );
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

  // 初始化服务定位器 (MVVM架构需要)
  serviceLocator.init();

  // 记录启动日志
  CommonLogger().logger.i("奇门遁甲模块已启动");
}

void main() async {
  // 初始化服务
  await initServices();

  // 初始化奇门 AI 模块
  initQimenModule();

  // 初始化 AI 数据库
  final db = AiDatabase();

  // TODO: 使用实际的 API Key
  const apiKey = 'sk-962c889316ff4799a87d4e82ef76d1bb';

  // 确保数据库中有可用的 LLM Provider
  await ensureDeepSeekProvider(db, apiKey: apiKey);

  // 初始化 LLM 服务
  final llmService = LlmService(db);

  // 初始化 AI 服务实现
  final aiService = AiServiceImpl(llmService: llmService, db: db);

  // 注册奇门 AI 能力
  QiMenAiIntegration.register(aiService);

  // 启动应用
  runApp(
    MultiProvider(
      providers: [Provider<AiService>.value(value: aiService)],
      child: const QiMenDunJiaApp(),
    ),
  );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              // 打开 AI 聊天界面
              final aiService = context.read<AiService>();
              aiService.openChat(context: context);
            },
          ),
        ],
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
