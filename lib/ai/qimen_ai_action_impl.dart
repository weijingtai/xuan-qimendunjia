import 'package:flutter/material.dart';
import 'package:qimendunjia/ai/qimen_ai_service.dart';

/// 奇门 AI 解盘操作实现
///
/// 此文件在 shell 层实现，不依赖 ai_core。
/// 业务模块只定义接口，实际调用由 shell 层完成。
class QiMenAnalyzeActionImpl implements QiMenAiAction {
  final QiMenAiService _aiService;

  QiMenAnalyzeActionImpl(this._aiService);

  @override
  String get id => 'qimen_analyze';

  @override
  String get name => '智能解盘';

  @override
  String get description => '使用 AI 分析当前奇门局';

  @override
  bool isApplicable(QiMenAiContext context) => true;

  @override
  String get label => name;

  @override
  IconData get icon => Icons.psychology;

  @override
  Future<void> execute({
    required BuildContext context,
    required QiMenAiContext aiContext,
  }) async {
    final effectiveContext = aiContext.intention.isEmpty
        ? QiMenAiContext(
            moduleName: 'xuan-qimendunjia',
            intention: '请帮我分析这个奇门局。你可以调用工具获取当前的排盘信息。',
            entities: aiContext.entities,
          )
        : aiContext;

    await _aiService.openChat(
      context: context,
      initialContext: effectiveContext,
    );
  }
}
