#!/usr/bin/env bash
# SessionStart hook: remind Codex to persist non-trivial learnings to the knowledge base.

set -euo pipefail

cat <<'BODY'
# nb-knowledge Reminder

このセッションでは、Q&A、バグ原因、設計判断、非自明な学びが発生したら、最終応答前に `kb` で knowledge へ記録すること。

- trivial な確認、単なるコマンド結果、既知情報の要約だけなら記録しない
- 記録は `kb new -t "<説明的なタイトル>" --folder knowledge --content -` の1コマンドで行う（frontmatter は kb が生成する）
- ノートブックは kb がマシンから自動判定する（`~/.is_work_pc` があれば work、無ければ home）
- 記録後は `kb sync` で反映する
- `nb` は廃止済み。使わない
- 迷ったら「後で検索できるタイトル・内容になっているか」を基準にする
BODY
