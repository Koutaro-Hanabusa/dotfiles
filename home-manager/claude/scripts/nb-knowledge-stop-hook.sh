#!/usr/bin/env bash
# Stop hook: nb-knowledge 記録漏れ防止リマインダ。
#
# 設計意図:
#   実作業のあったセッションで nb-knowledge スキルが一度も呼ばれていなければ、
#   停止前に1回だけ「未記録のインサイトを今すぐ記録せよ」と促す。
#
# 過去の失敗と対策:
#   かつて無条件 block していた際、モデルの「stop を許可します」系ナレーションが
#   直後の `git commit` HEREDOC に混入しコミット履歴を汚染した。今回は
#     (A) 記録済みセッションでは発火しない（既存 skill_call ログで正確判定）
#     (B) ツール使用が一切無い純粋な雑談セッションでは発火しない
#     (C) reason で「了承の発話を一切出すな・background 記録せよ」を明示
#     (D) stop_hook_active 再入ガードで最大1回
#   により発火面とナレーション量を最小化する。

input=$(cat)

# (D) 再入ガード: block の再発火による無限ループを防止（最大1回）
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
log="$HOME/.config/claude-otel-monitoring/logs/claude-hooks.log"

# (A) 既に nb-knowledge を呼んでいれば何もしない。
#     既存 PreToolUse フックが skill_call を session_id 付きで記録しているため、
#     スキルリスト等の文中出現と混同せず「実際のスキル呼び出し」だけを正確に判定できる。
if [ -n "$sid" ] && grep -F "$sid" "$log" 2>/dev/null | grep -q '"skill":"nb-knowledge"'; then
  exit 0
fi

# (B) ツール使用が一切無い純粋な雑談セッションでは催促しない。
#     何らかの作業（ツール使用）があれば発火対象とする。
[ -f "$tp" ] && grep -q '"type":"tool_use"' "$tp" 2>/dev/null || exit 0

# (C) リマインド: ナレーション明示禁止 = commit 汚染を断つ。記録不要なら即停止可。
jq -cn '{decision:"block", reason:"[自動リマインダ] このセッションで未記録のインサイト（バグ原因・非自明な挙動・設計判断・学びなど）があれば nb-knowledge スキルで今すぐ background 記録せよ。確認・了承・進捗の発話を一切出力しないこと（commit メッセージ汚染防止）。記録すべき新知見が無ければツールを呼ばず即座に停止してよい。"}'
exit 0
