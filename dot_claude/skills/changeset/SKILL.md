---
name: changeset
description: >
  AI-powered changeset file generator for monorepos. Analyzes git diff to identify changed packages,
  auto-generates summary, and writes .changeset/*.md files. Use when user says "changeset", "create changeset",
  "generate changeset", or wants to prepare changesets before a release. Works with @changesets/cli format.
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"changeset"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

# Changeset Generator

monorepo の git diff を解析し、`.changeset/` ファイルを下書き生成するスキル。

## Workflow

### Step 1: 変更パッケージの特定

```bash
# ベースブランチとの diff から変更ファイルを取得
git diff --name-only HEAD~1
# または staging されたファイル
git diff --name-only --cached
# またはベースブランチ指定
git diff --name-only main...HEAD
```

変更されたファイルパスから、どのパッケージが影響を受けているかを特定する:

1. 各変更ファイルのパスを確認
2. 最も近い `package.json` を探して、パッケージ名を取得
3. `devDependencies` のみの変更（テスト、lint設定等）は除外を検討

### Step 2: semver レベルの判定（デフォルト patch）

以下のヒューリスティクスでデフォルト値を決定:

| 変更内容 | デフォルト |
|---|---|
| バグ修正、typo、内部リファクタ | `patch` |
| 新しい機能・API の追加 | `minor` |
| 破壊的変更（API 削除・シグネチャ変更） | `major` |

迷ったら `patch` にする。ユーザーが後から変更できる。

### Step 3: 要約の自動生成

diff の内容から、以下のフォーマットで要約を生成:

- **何を変えたか**（What）を簡潔に
- 技術的な詳細より、ユーザー視点の影響を優先
- 日本語 or 英語はプロジェクトの既存 changeset に合わせる

### Step 4: .changeset ファイルの書き出し

```bash
# ランダムな changeset ID を生成（changesets CLI 互換）
# 形容詞-名詞-形容詞 の形式（例: brave-dogs-smile）
```

ファイルフォーマット:

```md
---
"@scope/package-name": patch
"@scope/another-package": minor
---

変更内容の要約をここに書く。
複数行OK。
```

書き出し先: `<project-root>/.changeset/<random-id>.md`

### Step 5: ユーザーに確認

生成したファイルの内容を表示し、以下を確認:

- パッケージの選定は正しいか
- semver レベルは適切か（patch/minor/major）
- 要約の内容は正確か

ユーザーが修正を指示したら、Edit ツールで修正する。

## Notes

- `.changeset/config.json` が存在する場合、`fixed` や `linked` の設定を尊重する
- 既存の `.changeset/*.md` ファイルのスタイル（言語、フォーマット）に合わせる
- changeset が不要なパッケージ（private: true で publish しないもの）はスキップ
