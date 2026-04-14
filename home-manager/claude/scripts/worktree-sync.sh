#!/bin/bash
# worktree-sync.sh - Claude Code ワークツリー変更時に nvim を自動同期
# PostToolUse hook for EnterWorktree / ExitWorktree

set -euo pipefail

STATE_FILE="$HOME/.claude/.worktree-state"
input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')

case "$tool_name" in
  EnterWorktree)
    # ワークツリーのパスを取得（複数の方法でフォールバック）
    worktree_dir=""

    # 1. cwd フィールドから（PostToolUse 時点で変更済みの場合）
    worktree_dir=$(printf '%s' "$input" | jq -r '.cwd // empty')

    # 2. cwd が取れない場合、tool_input.name + 既知のパスパターンから推定
    if [ -z "$worktree_dir" ] || ! echo "$worktree_dir" | grep -q '\.claude/worktrees'; then
      wt_name=$(printf '%s' "$input" | jq -r '.tool_input.name // empty')
      # .claude/worktrees/ 配下の最新ディレクトリを探す
      if [ -n "$worktree_dir" ] && [ -d "$worktree_dir" ]; then
        # cwd はあるがワークツリーパスではない → プロジェクトルートとして使う
        project_root="$worktree_dir"
      else
        project_root="$(pwd)"
      fi
      if [ -n "$wt_name" ] && [ -d "$project_root/.claude/worktrees/$wt_name" ]; then
        worktree_dir="$project_root/.claude/worktrees/$wt_name"
      else
        # 最新のワークツリーディレクトリを探す
        latest=$(find "$project_root/.claude/worktrees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -1)
        if [ -n "$latest" ]; then
          worktree_dir="$latest"
        fi
      fi
    fi

    if [ -z "$worktree_dir" ] || [ ! -d "$worktree_dir" ]; then
      exit 0
    fi

    # 元のディレクトリを推定（.claude/worktrees より上）
    original_dir=$(echo "$worktree_dir" | sed 's|/\.claude/worktrees/.*||')

    # 状態を保存
    mkdir -p "$(dirname "$STATE_FILE")"
    jq -cn --arg orig "$original_dir" --arg wt "$worktree_dir" \
      '{original_dir: $orig, worktree_dir: $wt, created_at: (now | todate)}' > "$STATE_FILE"

    ;;

  ExitWorktree)
    if [ -f "$STATE_FILE" ]; then
      rm -f "$STATE_FILE"
    fi
    ;;
esac
