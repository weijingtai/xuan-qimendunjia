import 'package:ai_core/ai/ai_action.dart';
import 'package:ai_core/ai/ai_context.dart';
import 'package:provider/provider.dart';
import 'package:ai_core/ai_core.dart';
import 'package:flutter/material.dart';

class QiMenAnalyzeAction implements AiAction {
  @override
  String get id => 'qimen_analyze';

  @override
  String get name => '智能解盘';

  @override
  String get description => '使用 AI 分析当前奇门局';

  @override
  bool isApplicable(AiContext context) => true;

  @override
  String get label => name;

  @override
  IconData get icon => Icons.psychology;

  @override
  Future<void> execute({
    required BuildContext context,
    required AiContext aiContext,
  }) async {
    final aiService = context.read<AiService>();

    // Merge provided context with our specific intention if needed
    final effectiveContext = aiContext.intention.isEmpty
        ? AiContext(
            moduleName: 'xuan-qimendunjia',
            intention: '请帮我分析这个奇门局。你可以调用工具获取当前的排盘信息。',
            entities: aiContext.entities,
          )
        : aiContext;

    await aiService.openChat(
      context: context,
      initialContext: effectiveContext,
    );
  }
}
