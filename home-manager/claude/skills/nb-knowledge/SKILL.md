---
name: nb-knowledge
description: Record session learnings, answers, bug fixes, and design decisions in the kb knowledge notebook. Use whenever a session produces reusable knowledge, and review for missed recordings before task completion or session end.
---

# ナレッジ記録

## 新規ノート

学び、Q&A、バグ修正、設計判断が発生したら、メインの作業をブロックしないバックグラウンド処理で次の形式を1回実行する。

```bash
kb new -t "<説明的なタイトル>" --folder knowledge --content - <<'EOF'
## <セクション1>

- 要点

## <セクション2>

...
EOF
```

- `-t` は必須。タイトルを位置引数に置かない。
- 本文に `# H1` や `## Date:` を書かず、2つ以上の `##` セクションに分ける。
- `kb new` が表示したパスを確認する。ファイル名が時刻だけなら、作成したノートを削除して `-t` 付きでやり直す。
- ノートブックは `~/.is_work_pc` の有無から自動選択する。通常は `--notebook` を指定しない。

## 既存ノートと同期

- 既存ノートは `kb search <term> -l` で探し、ファイルを編集してから `kb sync` する。`kb edit` は使わない。
- `kb sync` は Markdown だけをステージし、コミット後に pull と push を行う。
- `nb` は廃止済みのため、絶対に使わない。

## 完了確認

タスク完了時とセッション終了前に、記録漏れがないか確認する。ノート作成後はパスとファイル名が正しいことを確認してから同期する。
