# PRD v1: 将盘信息传入 AI Chat Window

> 版本: v1.0
> 状态: **已实现**
> 前置: [tasks_v1.md](./tasks_v1.md) (AI 基础集成)

---

## 1. 背景与目标

### 1.1 问题

用户在 `QiMenMvvmPage` 或 `ScalableShiJiaQiMenViewPage` 排盘后，打开 AI 聊天抽屉时，当前的盘信息（`QiMenPan`）未传入聊天上下文。`AiService.buildChatView()` 已支持 `initialContext` 参数，但两个页面均未使用。

AI 只能通过 `QiMenAgentTool`（Function Calling）自行排盘，无法直接分析用户已排好的盘。

### 1.2 目标

1. **Hybrid 方案** -- Push 当前盘作为 `AiContext` 初始上下文 + 保留 `QiMenAgentTool` 供 AI 排其他时间的盘
2. **可配置序列化** -- 用户通过 UI 面板选择发送哪些可选字段给 LLM，控制 token 消耗
3. **双架构覆盖** -- 同时支持 MVVM 架构页面 和 老架构页面

### 1.3 非目标

- 配置持久化（SharedPreferences）-- 当前仅存在 ViewModel 内存中，后续迭代
- 聊天历史管理 -- 由 `xuan-ai` 模块负责
- 流式分析结果展示 -- 由 `AiService` 实现层处理

---

## 2. 用户故事

| # | 角色 | 故事 | 验收标准 |
|---|------|------|----------|
| US-1 | 用户 | 排盘后打开 AI 聊天，AI 自动获得盘信息 | 聊天窗口打开时，`initialContext` 包含完整盘数据 |
| US-2 | 用户 | 切换盘（重新排盘）后打开聊天，看到新盘上下文 | `KeyedSubtree` 以 `pan.id` 为 key，盘变化时重建 chat |
| US-3 | 用户 | 通过设置面板控制哪些可选信息发送给 AI | 6 个 checkbox 可独立开关，下次打开聊天时生效 |
| US-4 | 用户 | 未排盘时打开聊天，不 crash | `buildAiContext()` 返回 null，不注入上下文 |
| US-5 | 用户 | 在聊天中让 AI 排其他时间的盘 | `QiMenAgentTool` 仍注册且正常工作 |

---

## 3. 数据模型

### 3.1 必选字段（始终传入 LLM）

| 字段 | 来源 | 说明 |
|------|------|------|
| `brief` | `QiMenPan.brief` | 盘局简要描述 |
| `time` | `QiMenPan.panDateTime` | 起盘时间 |
| `ju` | `ShiJiaJu` | 局描述、节气、三元、符头 |
| `fourZhuEightChar` | `ShiJiaJu.fourZhuEightChar` | 四柱八字 |
| `zhiFu` | `QiMenPan.zhiFuStar/AtGong` | 值符星及落宫 |
| `zhiShi` | `QiMenPan.zhiShiDoor/AtGong` | 值使门及落宫 |
| `horseLocation` | `QiMenPan.horseLocation` | 驿马位 |
| `fuFanYin` | `QiMenPan.is*FuYin/FanYin` | 六项伏吟反吟状态 |
| `gong_info` (per gong) | `EachGong` | 九星、八门、天盘八神、天盘干、地盘干 |

### 3.2 可选字段（由 `PanDisplayConfig` 控制）

| 配置项 | 默认值 | 字段内容 | 典型场景 |
|--------|--------|----------|----------|
| `showAnGan` | `false` | 天盘暗干、人盘暗干 | 阴盘奇门分析 |
| `showYinGan` | `false` | 隐干 | 特殊流派分析 |
| `showGeJuList` | `true` | 盘级格局列表（如五不遇时） | 常规分析 |
| `showDiGod` | `false` | 地盘八神 | 深度分析 |
| `showSixJiaXunHeader` | `false` | 各宫六甲旬首 | 进阶分析 |
| `showJiGan` | `false` | 天盘/地盘寄干 | 中宫寄宫分析 |

### 3.3 Token 预算

- 必选字段（9 宫）：约 300-400 tokens
- 全部可选字段开启：约 500-800 tokens
- 在主流 LLM 上下文窗口内可接受

---

## 4. 技术架构

### 4.1 数据流

```
用户排盘 → ViewModel 持有 QiMenPan
         → 用户打开 AI Drawer
         → ViewModel.buildAiContext()
           → PanSerializer.toDescription(pan, config) → AiEntity.description
           → PanSerializer.toMap(pan, config)          → AiEntity.rawData
           → AiContext(moduleName, intention, entities)
         → AiService.buildChatView(ctx, initialContext: context)
```

### 4.2 Hybrid 策略

```
┌─────────────────────────────────────────────────┐
│                  AI Chat Session                 │
│                                                  │
│  initialContext (Push)                            │
│  ├─ AiEntity(type: "qimen_pan")                  │
│  │  ├─ description: 自然语言盘局描述              │
│  │  └─ rawData: 结构化 JSON                      │
│  └─ intention: "用户已排好一个奇门局..."           │
│                                                  │
│  QiMenAgentTool (保留, AI 可主动调用)              │
│  └─ 排其他时间的盘 (Function Calling)             │
└─────────────────────────────────────────────────┘
```

### 4.3 Chat Session 重建

使用 `KeyedSubtree` + `ValueKey(pan.id)` 包裹 `buildChatView`，当盘 ID 变化（重新排盘）时，Flutter 框架自动销毁旧 widget 并创建新 session。

```dart
KeyedSubtree(
  key: ValueKey(vm.currentPan?.id ?? 'no-pan'),
  child: aiService.buildChatView(ctx, initialContext: vm.buildAiContext()),
)
```

---

## 5. 文件清单

### 5.1 新增文件

| 文件 | 说明 |
|------|------|
| `lib/ai/pan_display_config.dart` | 不可变配置类，6 个 bool 字段 + `copyWith()` + `defaultConfig()` |
| `lib/ai/pan_serializer.dart` | 共享序列化工具：`toMap()` (结构化) + `toDescription()` (自然语言) |

### 5.2 修改文件

| 文件 | 修改内容 |
|------|----------|
| `lib/presentation/viewmodels/qimen_viewmodel.dart` | 添加 `_displayConfig` 字段、`updateDisplayConfig()`、`buildAiContext()` |
| `lib/presentation/pages/qimen_mvvm_page.dart` | endDrawer 传入 `initialContext` + `KeyedSubtree`；AppBar 添加 `Icons.tune` 设置按钮 + `_showDisplayConfigSheet()` |
| `lib/pages/shi_jia_qi_men_view_model.dart` | 添加 `_displayConfig` 字段、`updateDisplayConfig()`、`buildAiContext()`（用 `QiMenPanMapper.fromModel()` 转换） |
| `lib/pages/scalable_shi_jia_qi_men_view_page.dart` | endDrawer 传入 `initialContext` + `KeyedSubtree`；AppBar 添加设置按钮 + `_showDisplayConfigSheet()` |
| `lib/ai/qimen_agent_tool.dart` | 删除 `_serializePan()` 私有方法，改用 `PanSerializer.toMap(pan)` |
| `lib/qimendunjia.dart` | 添加 `export 'ai/pan_display_config.dart'` 和 `export 'ai/pan_serializer.dart'` |

---

## 6. API 设计

### 6.1 PanDisplayConfig

```dart
class PanDisplayConfig {
  final bool showAnGan;          // default: false
  final bool showYinGan;         // default: false
  final bool showGeJuList;       // default: true
  final bool showDiGod;          // default: false
  final bool showSixJiaXunHeader;// default: false
  final bool showJiGan;          // default: false

  const PanDisplayConfig({...});
  const PanDisplayConfig.defaultConfig();
  PanDisplayConfig copyWith({...});
}
```

### 6.2 PanSerializer

```dart
class PanSerializer {
  /// 结构化 Map（供 AiEntity.rawData 和 QiMenAgentTool）
  static Map<String, dynamic> toMap(
    QiMenPan pan, {
    PanDisplayConfig config = const PanDisplayConfig.defaultConfig(),
  });

  /// 自然语言描述（供 AiEntity.description，直接喂给 LLM）
  static String toDescription(
    QiMenPan pan, {
    PanDisplayConfig config = const PanDisplayConfig.defaultConfig(),
  });
}
```

### 6.3 ViewModel 新增接口

```dart
// QiMenViewModel (MVVM 架构)
PanDisplayConfig get displayConfig;
void updateDisplayConfig(PanDisplayConfig config);
AiContext? buildAiContext();

// ShiJiaQiMenViewModel (老架构)
PanDisplayConfig get displayConfig;
void updateDisplayConfig(PanDisplayConfig config);
AiContext? buildAiContext(); // 内部用 QiMenPanMapper.fromModel() 转换
```

---

## 7. UI 设计

### 7.1 设置按钮

- 图标：`Icons.tune`
- 位置：AppBar actions，在 AI 人设选择按钮（`Icons.psychology`）之前
- 可见条件：`aiService != null && viewModel.hasData`（MVVM）/ `vm.shiJiaQiMen != null`（老架构）

### 7.2 配置面板

`showModalBottomSheet` + `StatefulBuilder`，包含 6 个 `CheckboxListTile`：

| 标题 | 说明文字 | 对应配置 |
|------|---------|----------|
| 暗干 | 阴盘奇门中的天盘/人盘暗干 | `showAnGan` |
| 隐干 | 特殊流派使用的隐干信息 | `showYinGan` |
| 格局列表 | 盘级别的常见格局（如五不遇时等） | `showGeJuList` |
| 地盘八神 | 各宫地盘八神信息 | `showDiGod` |
| 六甲旬首 | 各宫的六甲旬首 | `showSixJiaXunHeader` |
| 寄干 | 中五宫天盘/地盘寄干 | `showJiGan` |

---

## 8. 关键依赖

| 依赖 | 来源 | 用途 |
|------|------|------|
| `AiContext` | `package:xuan_common/domain/ai/ai_context.dart` | 聊天初始上下文容器 |
| `AiEntity` | `package:xuan_common/domain/ai/ai_entity.dart` | 业务实体包装（description + rawData） |
| `AiService.buildChatView()` | `package:xuan_common/services/ai_service.dart` | 构建聊天 UI，接受 `initialContext` 参数 |
| `QiMenPanMapper.fromModel()` | `lib/data/models/mappers/qimen_pan_mapper.dart` | 老 Model (`ShiJiaQiMen`) 转 Domain Entity (`QiMenPan`) |
| `QiMenAgentTool` | `lib/ai/qimen_agent_tool.dart` | AI 主动排盘的 Function Calling 工具 |

---

## 9. 测试验证

| # | 测试场景 | 预期结果 |
|---|---------|----------|
| T-1 | MVVM 页面排盘后打开 AI 聊天 | 第一条系统消息包含盘信息（brief + 九宫） |
| T-2 | 老架构页面排盘后打开 AI 聊天 | 同 T-1 |
| T-3 | 设置面板切换可选字段后重新打开聊天 | 描述内容相应增减 |
| T-4 | 在聊天中让 AI 用 `qimen_tools` 排其他时间的盘 | Tool 正常调用，返回结构化数据 |
| T-5 | 未排盘时打开聊天 | 无 crash，`initialContext` 为 null |
| T-6 | 排盘 → 打开聊天 → 关闭聊天 → 重新排盘 → 打开聊天 | 新 session，展示新盘信息 |

---

## 10. 后续迭代方向

| 方向 | 优先级 | 说明 |
|------|--------|------|
| 配置持久化 | P2 | 使用 SharedPreferences 保存 `PanDisplayConfig`，跨 session 保持 |
| 宫位级格局注入 | P2 | 将每宫的 `EachGongGeJu`（十干克应格局等）也序列化进上下文 |
| 多盘对比上下文 | P3 | 支持同时传入多个盘（如本命盘 + 流年盘）进行对比分析 |
| Token 预算显示 | P3 | 在设置面板实时显示当前配置预估的 token 消耗 |
| 智能选字段 | P3 | 根据排盘方式自动推荐可选字段（如阴盘自动勾选暗干） |
