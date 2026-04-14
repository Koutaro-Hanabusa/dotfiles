#!/bin/zsh

# tmuxセッション自動接続（Claude Code agent teams split panes対応）
# Ghostty / cmux 両対応。ロックで同時起動のレースコンディションを防止

# Ghostty/cmuxが最小環境で起動するためPATHを明示的に設定
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

LOCKDIR="/tmp/terminal-tmux-lock"

# ロック取得を試みる（最大2秒待機）
for i in {1..20}; do
    mkdir "$LOCKDIR" 2>/dev/null && break
    sleep 0.1
done

if ! tmux has-session -t main 2>/dev/null; then
    # 初回起動: mainセッションを作成
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux new-session -s main
else
    # mainが既に存在: 新しいセッションを作成
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux new-session
fi
