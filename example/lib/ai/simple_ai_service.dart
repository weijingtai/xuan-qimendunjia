import 'dart:async';

import 'package:ai_core/services/llm/openai_compatible_client.dart';
import 'package:common/domain/ai/agent_tool.dart';
import 'package:common/domain/ai/ai_action.dart';
import 'package:common/domain/ai/ai_config_summary.dart';
import 'package:common/domain/ai/ai_context.dart';
import 'package:common/domain/ai/ai_persona.dart';
import 'package:common/services/ai_service.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class SimpleAiServiceImpl implements AiService {
  final OpenAICompatibleClient _client;
  final List<AgentTool> _tools = [];

  SimpleAiServiceImpl(this._client);

  @override
  Future<void> openChat({
    required BuildContext context,
    AiContext? initialContext,
  }) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleChatPage(client: _client, tools: _tools),
      ),
    );
  }

  @override
  Widget buildChatView(BuildContext context, {AiContext? initialContext}) {
    return SimpleChatView(client: _client, tools: _tools);
  }

  @override
  Future<AiPersona?> showPersonaSelector({
    required BuildContext context,
    List<int>? requiredSkills,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Persona selector not implemented in example app')),
    );
    return null;
  }

  @override
  Future<String> analyze({required AiContext context}) async {
    return "Analysis not implemented in example app.";
  }

  @override
  void registerTool(AgentTool tool) {
    _tools.add(tool);
  }

  @override
  List<AgentTool> getAvailableTools() => List.unmodifiable(_tools);

  @override
  void registerAction(AiAction action) {
    // Not implemented
  }

  @override
  List<AiAction> getAvailableActions(AiContext context) => [];

  @override
  Future<String?> getSummary({required String entityId}) async {
    return null;
  }

  @override
  Stream<String?> watchSummary({required String entityId}) {
    return Stream.value(null);
  }

  @override
  Future<bool> showConfigSheet({required BuildContext context}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Config sheet not implemented in example app.'),
      ),
    );
    return false;
  }

  @override
  Stream<AiConfigSummary> get activeConfig => Stream.value(
    const AiConfigSummary(
      personaName: 'Default Assistant',
      modelName: 'deepseek-chat',
    ),
  );
}
