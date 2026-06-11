# AI_README.md — 宪法入口

> **任何 AI 工具接入本项目前 MUST 读完本文件，并依赖此处索引完整阅读 `docs/ai/` 下 12 个模块。**
> 本文件是「宪法」的索引页，不是宪法本身。规则细节以各模块原文为准；本文与模块冲突时，以模块为准并提交 fix。

- 项目：xuan-qimendunjia（奇门遁甲，Flutter / Dart）
- 当前宪法版本：v1.0.0（与 `docs/ai/CONSTITUTION.md` 矩阵对齐）
- 维护人：wjt
- 最后更新：2026-05-08

---

## 一、7 条核心原则（不可协商）

| # | 原则 | 一句话摘要 |
|---|------|-----------|
| 1 | **SPEC First** | 非平凡改动 MUST 先有已批准并锁定的 SPEC，再写第一行代码。 |
| 2 | **Think Before Coding** | 不假设、不隐藏困惑、呈现权衡；不清楚就停下来问。 |
| 3 | **Simplicity First** | 最小代码量解决问题；不写推测性代码、单次抽象、未被要求的灵活性。 |
| 4 | **Surgical Changes** | 只改必须改的；diff 中每一行都应直接追溯到用户需求。 |
| 5 | **Goal-Driven Execution** | 把任务转化为可验证目标，循环直到验收通过。 |
| 6 | **Chinese-First** | 注释 / commit / 文档用中文；代码标识符用英文 camelCase。 |
| 7 | **Context-Aware** | 必须读实际源文件，禁止凭训练数据猜测项目结构与风格。 |

> **平凡改动豁免：** ≤5 行、错别字、纯格式化、测试数据微调可跳过 SPEC 流程直接改。
> 完整文本：`docs/ai/principles.md`

---

## 二、SPEC Coding 工作流

```
Part A: SPEC 生命周期（控制「怎么想」）
  A1 启动与框架  →  A2 内容填充  →  A3 评审与批准  →  A4 SPEC 锁定
                                          ↑ 修改意见循环 ↩

Part B: 交付（控制「怎么做」）
  B1 代码实现  →  B2 SPEC 验收  →  B3 SPEC 归档
```

| 阶段 | 关键产出 | 强约束 |
|------|---------|-------|
| A1 | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` 骨架，10 个必填节齐全 | MUST NOT 在骨架不全时进入 A2 |
| A2 | 内容填满，无 TBD/TODO/???，每条验收 `[ ]` 独立可判定 | MUST NOT 写「尽量」「差不多」类模糊条款 |
| A3 | 用户明确批准（"批准/OK/可以"） | MUST NOT 在批准前写任何代码 |
| A4 | SPEC 状态 → 「已锁定」，进入 Part B | 锁定后 MUST 走 SPEC 变更流程才能改 |
| B1 | 代码可逐行追溯到验收条件 | MUST NOT 在实现中改 SPEC（要改 → 走变更流程） |
| B2 | 每条验收 `[ ]` → `[x]` + 代码行号 | MUST NOT 批量勾选 |
| B3 | SPEC 状态 → 「已归档」；架构变更同步 `docs/Plans.md` | 归档后 SPEC 不可再改 |

> 完整定义：`docs/ai/phases.md`

---

## 三、代码交付流水线（5 步）

```
Step 1 分支就绪 → Step 2 代码开发 → Step 3 自测验证 → Step 4 提交就绪 → Step 5 合并归档
```

| Step | 硬门禁（不达即停） |
|------|-------------------|
| 1 分支就绪 | 工作区干净；从最新 main 创建；分支名匹配 `^(feat\|fix\|refactor\|doc\|chore)/[a-z][a-z0-9-]+[a-z0-9]$` |
| 2 代码开发 | `flutter analyze` 零 warning；`dart format --set-exit-if-changed lib/ test/` 返回 0；diff 不超 SPEC 范围 |
| 3 自测验证 | `flutter test` 全通过；新公开方法有测试；UI 改动需手动验证 |
| 4 提交就绪 | 提交信息匹配 `<type>: <中文简述>`，type ∈ {add, fix, update, refactor, remove, init}；单一逻辑变更；无敏感文件 |
| 5 合并归档 | merge 无冲突；post-merge 测试再次通过；架构变更已同步 `docs/Plans.md` |

> 完整规则：`docs/ai/delivery-pipeline.md`、`docs/ai/git-rules.md`

---

## 四、10 项快速自检清单

任务开始前 / 提交前逐项自问，任意一项「否」即 MUST 停止处理：

1. 我读完了 `AI_README.md` 和 `docs/ai/` 全部 12 个模块吗？
2. 我读完了 `docs/Plans.md` + 任务相关源文件 + 它们的项目内 import + 对应 test 文件吗？
3. 这是平凡改动吗？是 → 直接改并跳到第 8 项；否 → 走 A1–A4。
4. 非平凡改动的 SPEC 已锁定（`状态: 已锁定`）了吗？
5. 我在最新 main 上创建了符合命名规范的 `<type>/<desc>` 分支吗？
6. 实现严格对照 SPEC 验收条件，diff 中没有超范围的改动吗？
7. `flutter analyze` 零 warning、`dart format` 通过、无调试 print / 注释代码 / 死代码吗？
8. `flutter test` 全通过、新公开方法均有中文命名的对应测试吗？
9. 提交是单一逻辑、信息为 `<type>: <中文简述>`、不含 `--no-verify`、无敏感文件吗？
10. 验收条件已逐条 `[x]` + 行号；架构变更已同步 `docs/Plans.md`；SPEC 状态推进至「已验收 / 已归档」了吗？

> 补充：写入看板（`docs/board/`、`docs/Plans.md`、`docs/project/`）MUST 走 W1–W5 通道，详见 `docs/ai/board-protocol.md`。

---

## 五、宪法 12 模块索引

| # | 模块 | 用途 | 何时读 |
|---|------|------|-------|
| 1 | [`docs/ai/CONSTITUTION.md`](docs/ai/CONSTITUTION.md) | 12 模块版本矩阵与修订历史 | 每次接入；版本变更时 |
| 2 | [`docs/ai/glossary.md`](docs/ai/glossary.md) | 术语表（SPEC / 平凡改动 / W1-W5 / MUST 等） | 首次接入 |
| 3 | [`docs/ai/principles.md`](docs/ai/principles.md) | 7 条不可协商原则 | 首次接入；任何怀疑「是否要这么做」时 |
| 4 | [`docs/ai/phases.md`](docs/ai/phases.md) | SPEC Coding A1–A4 / B1–B3 阶段定义与准入准出 | 启动任何非平凡任务前 |
| 5 | [`docs/ai/delivery-pipeline.md`](docs/ai/delivery-pipeline.md) | 代码交付 5 步流水线（硬门禁 / 软提醒 / 最佳实践） | 进入实现阶段前 |
| 6 | [`docs/ai/code-style.md`](docs/ai/code-style.md) | Dart / Flutter 代码风格 | 每次写代码前 |
| 7 | [`docs/ai/directory-structure.md`](docs/ai/directory-structure.md) | `lib/` 目录约定（domain / data / presentation 等） | 新增文件 / 移动文件前 |
| 8 | [`docs/ai/git-rules.md`](docs/ai/git-rules.md) | 分支 / commit / merge 规范 | 创建分支、提交、合并前 |
| 9 | [`docs/ai/doc-standards.md`](docs/ai/doc-standards.md) | 文档格式与命名规则 | 新增 / 修改任何文档前 |
| 10 | [`docs/ai/toolchain.md`](docs/ai/toolchain.md) | Flutter SDK / 构建 / 工具链配置 | 工具链相关问题、CI 调整 |
| 11 | [`docs/ai/board-protocol.md`](docs/ai/board-protocol.md) | 看板协议、AI 写入权限矩阵、W1–W5 通道 | 写 `docs/board/` / `Plans.md` / `project/` 前 |
| 12 | [`docs/ai/project-context-guide.md`](docs/ai/project-context-guide.md) | 7 批必读清单 + 文档/代码冲突处理 | 首次接入；任何「不确定先读什么」时 |

---

## 六、本仓库 docs/ 的特殊约定

- `docs/` 来自 [`weijingtai/docs`](https://github.com/weijingtai/docs)，**git 联系已断开**，作为本仓库普通文件被 xuan-qimendunjia 追踪。
- 不存在指向上游的 remote；如需获取上游更新，**MUST 由人手动重新克隆并合并**，不走 submodule / subtree。
- `docs/` 内文件视为本项目所有，可被项目内提交修改，但 MUST 经 SPEC 流程（宪法模块的修改 = MAJOR/MINOR/PATCH 变更，需更新 `CONSTITUTION.md` 版本矩阵）。

---

## 七、AI 接入后的第一句话

读完上述全部内容后，AI MUST 在与人交互前主动确认：

> 我已阅读 AI_README.md 与 docs/ai/ 下 12 个模块（CONSTITUTION 标记宪法版本 v1.0.0），并理解 SPEC First 与 7 条核心原则。请下达任务。
