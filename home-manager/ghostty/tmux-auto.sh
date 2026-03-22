#!/bin/zsh

# tmuxセッション自動接続（Claude Code agent teams split panes対応）
# Ghostty / cmux 両対応。ロックで同時起動のレースコンディションを防止

# Ghostty/cmuxが最小環境で起動するためPATHを明示的に設定
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# cmux環境変数をtmuxグローバル環境に引き継ぐ（ソケット認証・通知用）
# cmuxがシェルに設定するCMUX_*変数を、tmuxサーバー経由で全ペインに伝播させる
_forward_cmux_env() {
    # cmux環境変数をtmuxグローバル環境に伝播
    for var in CMUX_WORKSPACE_ID CMUX_SURFACE_ID CMUX_SOCKET_PATH CMUX_TAB_ID; do
        if [ -n "${(P)var}" ]; then
            tmux set-environment -g "$var" "${(P)var}" 2>/dev/null
        fi
    done
    # CMUX_SOCKET_PASSWORDはファイルから読み取り（cmuxが環境変数にセットしなくなったため）
    local pw_file="$HOME/Library/Application Support/cmux/socket-control-password"
    if [ -f "$pw_file" ]; then
        tmux set-environment -g CMUX_SOCKET_PASSWORD "$(cat "$pw_file")" 2>/dev/null
    fi
}

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
    # mainが既に存在: CMUX環境変数を注入して新しいセッションを作成
    # （ハングしたセッションへの再接続は行わない）
    _forward_cmux_env
    rmdir "$LOCKDIR" 2>/dev/null
    exec tmux new-session
fi
