import 'package:qimendunjia/ai/qimen_ai_service.dart';
import 'package:qimendunjia/ai/qimen_agent_tool_impl.dart';

/// 奇门遁甲 AI 集成
///
/// 此文件在 shell 层实现，不依赖 ai_core。
/// 负责注册奇门工具到 AI 服务。
class QiMenAiIntegration {
  /// 注册奇门工具到 AI 服务
  static void register(QiMenAiService aiService) {
    aiService.registerTool(
      'qimen_tools',
      QiMenAgentToolImpl().execute,
    );
  }
}
