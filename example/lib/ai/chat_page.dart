import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:ai_core/services/llm/openai_compatible_client.dart';
import 'package:common/domain/ai/agent_tool.dart';
import 'qimen_ai_provider.dart';

class SimpleChatPage extends StatelessWidget {
  final OpenAICompatibleClient client;
  final List<AgentTool> tools;

  const SimpleChatPage({
    super.key,
    required this.client,
    required this.tools,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 助手 (奇门遁甲)')),
      body: SimpleChatView(client: client, tools: tools),
    );
  }
}

class SimpleChatView extends StatefulWidget {
  final OpenAICompatibleClient client;
  final List<AgentTool> tools;

  const SimpleChatView({
    super.key,
    required this.client,
    required this.tools,
  });

  @override
  State<SimpleChatView> createState() => _SimpleChatViewState();
}

class _SimpleChatViewState extends State<SimpleChatView> {
  late QimenAiProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = QimenAiProvider(
      client: widget.client,
      tools: widget.tools,
      model: 'deepseek-chat', 
    );
  }

  @override
  Widget build(BuildContext context) {
    return LlmChatView(
      provider: _provider,
      style: const LlmChatViewStyle(
         backgroundColor: Colors.white,
      ),
    );
  }
}
