import 'dart:async';
import 'package:flutter/material.dart';

// ============================================================================
// 奇门 AI 抽象接口层
//
// 这些接口在业务模块中定义，不依赖 ai_core。
// 实际实现由 shell 层提供（通过 ai_core）。
// ============================================================================

/// 奇门 AI 上下文
class QiMenAiContext {
  final String moduleName;
  final String intention;
  final List<QiMenAiEntity> entities;

  const QiMenAiContext({
    required this.moduleName,
    required this.intention,
    this.entities = const [],
  });
}

/// 奇门 AI 实体
class QiMenAiEntity {
  final String id;
  final String type;
  final String name;
  final String description;
  final Map<String, dynamic>? rawData;

  const QiMenAiEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.rawData,
  });
}

/// AI 聊天事件基类
abstract class QiMenAiChatEvent {
  const QiMenAiChatEvent();
}

/// 工具结果事件
class QiMenToolResultEvent extends QiMenAiChatEvent {
  final String toolName;
  final Map<String, dynamic> resultData;
  final String sessionUuid;

  const QiMenToolResultEvent({
    required this.toolName,
    required this.resultData,
    required this.sessionUuid,
  });
}

/// AI 人格
class QiMenAiPersona {
  final String id;
  final String name;
  final String? description;

  const QiMenAiPersona({
    required this.id,
    required this.name,
    this.description,
  });
}

/// AI 服务接口
///
/// 由 shell 层实现，业务模块只依赖此接口
abstract class QiMenAiService {
  /// 聊天事件流
  Stream<QiMenAiChatEvent> get chatEvents;

  /// 打开 AI 聊天
  Future<void> openChat({
    required BuildContext context,
    required QiMenAiContext initialContext,
    QiMenAiPersona? persona,
  });

  /// 构建聊天视图
  Widget buildChatView(
    BuildContext context, {
    QiMenAiContext? initialContext,
    QiMenAiPersona? persona,
  });

  /// 注册工具
  void registerTool(String name, Future<Map<String, dynamic>> Function(Map<String, dynamic> args) executor);

  /// 显示人格选择器
  Future<QiMenAiPersona?> showPersonaSelector({required BuildContext context});
}

/// AI 操作接口
abstract class QiMenAiAction {
  String get id;
  String get name;
  String get description;
  String get label;
  IconData get icon;
  bool isApplicable(QiMenAiContext context);
  Future<void> execute({
    required BuildContext context,
    required QiMenAiContext aiContext,
  });
}

/// Agent 工具接口
abstract class QiMenAgentTool {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
  Map<String, dynamic> toFunctionDeclaration();
}
