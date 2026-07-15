#!/bin/bash
# Claude Code SessionStart hook: 会话启动时自动注入当前任务纪要(指针+摘要)
# 效果: Agent"睁眼"即知当前任务、断点、墓地, 无需手敲 /wjt-resume 也不会瞎写
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0
br="$(git branch --show-current 2>/dev/null)"
[ -n "$br" ] || { echo "【位置警告】当前处于 detached HEAD, 开发前请确认worktree与分支"; exit 0; }
case "$br" in
  main|master)
    echo "【位置警告】你在主工作区(分支 $br)。禁止在此直接开发业务代码。"
    echo "如需开发: 请人类运行 aiwt new <agent> <任务> 或 aiwt adopt 收编现有改动,"
    echo "然后到对应 .worktrees/ 目录工作。你现在只允许回答问题和只读操作。"
    exit 0 ;;
esac
echo "【位置确认】worktree: $(pwd) ｜ 分支: $br"
tf=""
case "$br" in
  agent/*/*) n="$(echo "$br" | awk -F/ '{print $2"-"$3}')"; [ -f "tasks/$n.md" ] && tf="tasks/$n.md" ;;
esac
[ -z "$tf" ] && tf="$(ls tasks/*.md 2>/dev/null | head -1)"
[ -f "$tf" ] || exit 0
echo "【会话启动自动注入】当前分支 $br 的任务纪要是 $tf。"
echo "开工前必须先消化以下内容(完整版读原文件), 严禁无视断点从头写:"
echo "----------------------------------------"
sed -n '1,90p' "$tf"
echo "----------------------------------------"
echo "落盘用 /wjt-handoff; 陌生报错先跑: aiwt when \"<关键词>\""
