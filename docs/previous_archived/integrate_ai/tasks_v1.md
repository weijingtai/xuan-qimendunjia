# 奇门遁甲 AI 集成任务清单 (v1)

本文档旨在指导开发者将 `xuan-ai` 核心能力集成到 `qimendunjia` 模块（及其宿主应用 `example`）中，使 AI 功能达到基础可用状态。

## 1. 依赖配置 (pubspec.yaml)

- [x] **添加 `xuan-ai` 依赖**
  - 在 `example/pubspec.yaml` (或主工程) 中添加：

    ```yaml
    dependencies:
      xuan_ai:
        path: ../../xuan-ai  # 根据实际路径调整
      logging: ^1.2.0
      provider: ^6.1.1
    ```

- [x] **执行 `flutter pub get`**
  - 确保所有依赖正确解析。

## 2. 服务初始化 (Main App)

- [x] **初始化 LLM 客户端**
  - 在 `main.dart` 或初始化逻辑中创建 `LlmService` 实例。
  - 示例：

    ```dart
    final llmService = OpenAiCompatibleClient(
      apiKey: 'YOUR_API_KEY',
      baseUrl: 'https://api.deepseek.com/v1', // 或其他服务商
      defaultModel: 'deepseek-chat',
    );
    ```

- [x] **初始化 AiService**
  - 创建 `AiServiceImpl` 实例并注入 LLM 服务。

    ```dart
    final aiService = AiServiceImpl(
      llmService: llmService,
      auditService: AiAuditServiceImpl(), // 可选
    );
    ```

- [x] **注册模块能力 (关键)**
  - 调用集成助手注册奇门特有的 AI 能力。

    ```dart
    // 引入集成文件
    import 'package:qimendunjia/ai/qimen_ai_integration.dart';

    // 注册
    QiMenAiIntegration.register(aiService);
    ```

- [x] **注入服务**
  - 将 `aiService` 注入到 Flutter 树或依赖容器 (`GetIt`/`Provider`) 中，以便全局访问。

    ```dart
    // Provider 示例
    MultiProvider(
      providers: [
        Provider<AiService>.value(value: aiService),
      ],
      child: MyApp(),
    )
    ```

## 3. UI 入口集成

- [x] **添加 AI 助手入口**
  - 在 `SelectionPage` 或 `PrimaryPage` 的 `AppBar` 添加 Action 按钮。

    ```dart
    IconButton(
      icon: Icon(Icons.psychology),
      onPressed: () {
        final aiService = context.read<AiService>();
        // 方案 A: 直接打开聊天窗口
        aiService.openChat(context: context);
        
        // 方案 B: 带意图打开 (例如"分析当前局")
        // aiService.openChat(
        //   context: context,
        //   initialContext: AiContext(intention: "请帮我分析这个奇门局"),
        // );
      },
    )
    ```

## 4. 验证与测试

- [x] **启动应用**
  - 运行 `example` 工程。
- [x] **测试对话**
  - 点击 AI 按钮，发送 "你好"。
  - 确认 AI 能回复。
- [x] **测试工具调用 (Function Calling)**
  - 发送 "现在的奇门局是什么？" 或 "帮我排个盘"。
  - 观察日志，确认 `QiMenAgentTool` 被调用。
  - 确认 AI 能准确输出当前局的信息（如 "阳遁X局..."）。

## 5. (可选) 高级功能

- [ ] **实现窗口控制**
  - 引入 `window_manager` 包。
  - 实现 `WindowManager` 接口。
  - 注册 `WindowControlTool`。
