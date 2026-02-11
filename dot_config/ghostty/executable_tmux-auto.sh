#!/bin/zsh

# tmuxセッション自動接続（Claude Code teams split panes対応）
# ロックで同時起動のレースコンディションを防止

# Ghosttyが最小環境で起動するためPATHを明示的に設定
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

LOCKDIR="/tmp/ghostty-tmux-lock"

# ロック取得を試みる（最大2秒待機）
for i in {1..20}; do
    mkdir "$LOCKDIR" 2>/dev/null && break
    sleep 0.1
done

if ! tmux has-session -t main 2>/dev/null; then
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux new-session -s main
elif [ -z "$(tmux list-clients -t main 2>/dev/null)" ]; then
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux attach-session -t main
else
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux new-session
fi
