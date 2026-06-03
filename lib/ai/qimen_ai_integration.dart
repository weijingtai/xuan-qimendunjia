import 'package:xuan_common/services/ai_service.dart';
import 'package:qimendunjia/ai/qimen_agent_tool.dart';

class QiMenAiIntegration {
  static void register(AiService aiService) {
    // 注册奇门排盘工具
    aiService.registerTool(QiMenAgentTool());
  }
}
