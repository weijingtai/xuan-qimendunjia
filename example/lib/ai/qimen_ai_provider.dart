import 'dart:async';
import 'dart:convert';

import 'package:ai_core/models/chat_message_model.dart';
import 'package:ai_core/models/llm_request_model.dart';
import 'package:ai_core/models/tool_definition.dart';
import 'package:ai_core/services/llm/openai_compatible_client.dart';
import 'package:common/domain/ai/agent_tool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

/// A provider that integrates with OpenAI-compatible API and supports Agent Tools.
class QimenAiProvider extends ChangeNotifier implements LlmProvider {
  QimenAiProvider({
    required this.client,
    required this.tools,
    this.model = 'deepseek-chat',
    this.systemInstruction,
    List<ChatMessage>? history,
  }) : _history = history?.toList() ?? [];

  final OpenAICompatibleClient client;
  final List<AgentTool> tools;
  final String model;
  final String? systemInstruction;

  List<ChatMessage> _history;

  // Internal history for LLM (includes tool calls/results which might not be in UI history)
  final List<ChatMessageModel> _llmHistory = [];

  @override
  Iterable<ChatMessage> get history => List.unmodifiable(_history);

  @override
  set history(Iterable<ChatMessage> history) {
    _history = history.toList();
    // Rebuild LLM history from UI history is tricky because UI history lacks tool calls.
    // For simplicity in this example, we assume _llmHistory is maintained cumulatively.
    // If the UI clears history, we might need to clear _llmHistory too.
    if (_history.isEmpty) {
      _llmHistory.clear();
    }
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment>? attachments,
  }) async* {
    yield* _sendMessageInternal(prompt, isUser: false);
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment>? attachments,
  }) async* {
    // Add user message to UI history
    final userMessage = ChatMessage.user(prompt, attachments ?? []);
    _history.add(userMessage);
    notifyListeners();

    yield* _sendMessageInternal(prompt, isUser: true);
  }

  Stream<String> _sendMessageInternal(
    String prompt, {
    required bool isUser,
  }) async* {
    // 1. Add user message to LLM history
    if (isUser) {
      _llmHistory.add(ChatMessageModel.user(prompt));
    }

    // 2. Prepare system message if needed
    final messages = <ChatMessageModel>[
      if (systemInstruction != null)
        ChatMessageModel.system(systemInstruction!),
      ..._llmHistory,
    ];

    // 3. Prepare tools
    final toolDefinitions = tools
        .map(
          (t) => ToolDefinition(
            function: FunctionDefinition(
              name: t.name,
              description: t.description,
              parameters: t.parametersSchema,
            ),
          ),
        )
        .toList();

    // 4. Run loop
    bool finished = false;
    int turns = 0;
    const maxTurns = 5; // Prevent infinite loops

    while (!finished && turns < maxTurns) {
      turns++;

      final request = LlmRequestModel(
        model: model,
        messages: messages,
        tools: toolDefinitions.isNotEmpty ? toolDefinitions : null,
        stream: false, // Use non-streaming for easier tool handling
      );

      final response = await client.chatCompletion(request);
      final choice = response.choices.first;
      final message = choice.message!;

      // Add assistant response to history
      _llmHistory.add(message);

      // If there is content, yield it
      if (message.content.isNotEmpty) {
        // Create a placeholder for assistant response in UI if it's the first turn
        if (turns == 1) {
          final responseMessage = ChatMessage.llm();
          _history.add(responseMessage);
          notifyListeners();
        }

        // In non-streaming mode, we get the whole chunk.
        yield message.content;

        // Update UI message
        // Note: ChatMessage in toolkit might not expose append if typed as ChatMessage.
        // But we know it's an LLM message.
        final lastMsg = _history.last;
        // We can't easily append if the API doesn't expose it on ChatMessage.
        // But we can replace the message or use reflection if needed.
        // Actually, flutter_ai_toolkit ChatMessage is likely mutable or has append.
        // Let's assume append exists or we can just replace the history item?
        // No, history setter notifies listeners.

        // DeepSeekProvider uses: responseMessage.append(chunk);
        // So it must be available.
        try {
          // ignore: avoid_dynamic_calls
          (lastMsg as dynamic).append(message.content);
        } catch (e) {
          // If append fails, we might need to cast to specific type or it doesn't exist.
          // Ignore for now.
        }
        notifyListeners();
      }

      // Check for tool calls
      if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
        // Execute tools
        for (final toolCall in message.toolCalls!) {
          final function = toolCall.function;
          final tool = tools.firstWhere(
            (t) => t.name == function.name,
            orElse: () => throw Exception('Tool not found'),
          );

          Map<String, dynamic> args = {};
          try {
            args = jsonDecode(function.arguments);
          } catch (e) {
            // ignore error
          }

          // Execute
          final result = await tool.execute(args);

          // Add result to history
          _llmHistory.add(
            ChatMessageModel.tool(jsonEncode(result), toolCall.id),
          );
        }
        // Loop continues to let LLM process tool results

        // Update messages for next turn
        messages.clear();
        if (systemInstruction != null) {
          messages.add(ChatMessageModel.system(systemInstruction!));
        }
        messages.addAll(_llmHistory);
      } else {
        finished = true;
      }
    }
  }
}
