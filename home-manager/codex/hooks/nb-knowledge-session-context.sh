#!/usr/bin/env bash
# SessionStart hook: remind Codex to persist non-trivial learnings to nb.

set -euo pipefail

cat <<'BODY'
# nb-knowledge Reminder

このセッションでは、Q&A、バグ原因、設計判断、非自明な学びが発生したら、最終応答前に nb の knowledge へ記録すること。

- trivial な確認、単なるコマンド結果、既知情報の要約だけなら記録しない
- `~/.is_work_pc` が存在する場合は work notebook、存在しない場合は home notebook を使う
- 記録方法は、そのセッションで有効な AGENTS.md / instructions.md / nb-knowledge skill の指示に従う
- 迷ったら「後で検索できるファイル名・内容になっているか」を基準にする
BODY
