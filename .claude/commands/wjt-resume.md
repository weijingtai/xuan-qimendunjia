---
name: /wjt-resume
description: 接手工作并继续（基于任务纪要，不依赖上一个Agent留下任何遗言）
---

按以下顺序恢复上下文, 以 git 为准, 然后直接继续:

1. 读 AGENTS.md(项目规则, 必须遵守 Git 安全铁律)
2. 确认当前分支: git branch --show-current
   读取 tasks/ 下与当前分支对应的任务纪要(分支 agent/claude/login-api
   对应 tasks/claude-login-api.md)。重点顺序: 踩坑墓地(别人失败过什么,
   千万别重试) -> 当前状态(含微观意图) -> 计划 -> 决定记录。
   若纪要不存在(App自建worktree): 按模板新建一份并 commit, 文件名 =
   分支名把 / 换成 -。
3. 执行: git log --oneline -10 && git status && git diff --stat
4. 检查影子快照: git for-each-ref --sort=-creatordate refs/snapshots/ | head -5
   若最新快照比 HEAD 新: git diff HEAD <快照ref> --stat 查看,
   有价值则 git restore --source=<快照ref> --worktree -- . 恢复猝死半成品
5. 工作区有未提交改动: 是半成品就以 "wip: 接手前落盘" 提交, 绝不丢弃
6. 断点 = 计划区第一个未勾选项, 对照最近 commit 和 diff 推断, 从断点继续

开工协议: 若计划区还是模板占位符, 你的第一个动作是把任务拆成30-60分钟
粒度的子任务填入计划区并 commit, 然后才写代码。

Debug协议: 遇到陌生报错, 先执行 aiwt when "<报错关键词>" 检索历史病历
(这个错也许已被前任解决过), 再开始独立排查。

禁止: 重读全部源码、重新总结项目、修改 TASKS.md 总览板、修改验收标准区、
询问用户"之前做到哪了"。