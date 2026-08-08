#!/usr/bin/env bash
# SessionStart hook: remind Codex to persist non-trivial learnings to the knowledge base.

set -euo pipefail

cat <<'BODY'
# nb-knowledge Reminder

このセッションでは、Q&A、バグ原因、設計判断、非自明な学びが発生したら、`kb` で knowledge へバックグラウンド記録すること。

- trivial な確認、単なるコマンド結果、既知情報の要約だけなら記録しない
- 記録は `kb new -t "<説明的なタイトル>" --folder knowledge --content -` の1コマンドで行う（frontmatter と `# 見出し` は kb が生成する）
- `-t` は必須。位置引数のタイトルは本文として扱われるため、`-t` が無いとファイル名が時刻だけ（`20260729095853.md`）になり検索できなくなる
- 本文は `# H1` を書かない・`## Date:` を書かない（frontmatter の created がある）・`##` セクションを2つ以上に分ける。1段落の散文にしない
- `kb new` が表示したパスを確認する。時刻だけのファイル名になっていたら `-t` 忘れなので `kb delete` してやり直す
- ノートブックは kb がマシンから自動判定する（`~/.is_work_pc` があれば work、無ければ home）
- 記録後は `kb sync` で反映する
- `nb` は廃止済み。使わない
- 迷ったら「後で検索できるタイトル・内容になっているか」を基準にする
- ナレッジ記録は内部作業。ユーザーが尋ねない限り、成功・失敗を最終応答へ混ぜない。記録失敗が依頼した作業そのものを妨げる場合だけ簡潔に伝える
BODY
