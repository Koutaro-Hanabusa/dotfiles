---
name: home-memo
description: >
  Search Koutaro's personal knowledge notes via the `mcp__home-memo__search_knowledge` tool BEFORE
  answering questions where personal context might exist. The notes are 400+ markdown files in nb's
  home notebook (~/.nb/home/knowledge/), indexed via Cloudflare AI Search and served by the
  home-memo-mcp Worker. Trigger eagerly when the user asks about: technical topics that might have
  been researched before (frameworks like TanStack/React/Hono, libraries, patterns, dotfiles, MCP,
  Cloudflare, Nix), past design decisions or architectural notes, career / job-hunting / Findy /
  ファンテック context, prior Q&A or learnings ("前に調べた", "メモから", "ノートに", "知識から探して",
  "あの記事", "前にまとめた"), bug investigations that may already be documented, or any question
  where the user's own past notes could enrich the answer. Also fires on explicit invocations like
  `/home-memo` or "home-memo で〜調べて". Skip ONLY for: trivial real-time lookups (current time,
  version numbers, today's news, current prices), pure codebase-internal questions where reading
  source is more direct, or when the user explicitly says they want fresh / external info only.
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"home-memo"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

このスキルは、**回答する前に Koutaro の個人ナレッジを検索する**ためのもの。`nb-knowledge` が「書く側」なら、こちらは「読む側」。

## なぜ存在するか

Koutaro は `~/.nb/home/knowledge/` に 400+ の markdown ノート（技術学習・設計判断・キャリア・求人リサーチ等）を蓄積していて、それを Cloudflare AI Search でインデックスし、`home-memo-mcp` Worker 経由で `mcp__home-memo__search_knowledge` ツールとして公開している。

しかし放っておくと Claude はこのツールの存在を忘れて Web 検索や一般知識で答えてしまい、**せっかく蓄積したナレッジが活用されない**。このスキルはその防止策。

## 必ず使うシチュエーション

回答前に必ず `mcp__home-memo__search_knowledge` を呼ぶこと:

1. **技術トピックの質問** — 「TanStack Router って〜」「Hono の〜」「Cloudflare Workers の〜」など、過去に触ったことがありそうなライブラリ/フレームワーク全般
2. **設計判断・アーキテクチャの相談** — 「〜の設計ってどうしてた？」「前にこういうパターン使ってた気がする」
3. **キャリア・転職・求人** — Findy、ファンテック、企業リサーチなど（`job-hunter` スキルと併用）
4. **過去の言及を匂わせる質問** — 「前に調べた」「メモにあったやつ」「ノートに書いた」「あの記事」「以前まとめた」「知識から探して」
5. **バグ調査** — 過去に同じハマり方をしている可能性があるとき
6. **明示的呼び出し** — `/home-memo`、「home-memo で〜」

## スキップしていいシチュエーション

- 現在時刻・バージョン番号の確認のような一発回答できるもの
- リアルタイム情報（今日のニュース、株価、為替）
- 「このリポジトリのこのファイルを読んで」のようにソースを読めば即解決するもの
- ユーザーが明示的に「外部情報だけ欲しい」「最新の情報を」と言っているとき

## 使い方

### 1. クエリを組み立てる

ユーザーの質問の **核となるキーワード** を日本語または英語で抽出する。長文の質問をそのまま投げない。

```
ユーザー: 「TanStack Router のファイルベースルーティングってどう書くんやっけ？」
→ query: "TanStack Router file-based routing"
```

```
ユーザー: 「前にまとめたファンテック企業のリスト見せて」
→ query: "ファンテック 企業 リスト"
```

### 2. ツールを呼ぶ

```
mcp__home-memo__search_knowledge(query="...", max_results=5)
```

`max_results` のデフォルトは 5。ヒットが少ないと感じたら 10〜20 まで上げてもよい。

### 3. 結果を回答に組み込む

- ヒットしたチャンクの内容を要約しつつ、必要なら**ファイル名を引用**する（ユーザーが原典をたどれるように）
- ヒット内容と一般知識を**混ぜて答えてよい**。ただしノートにある内容と一般知識で食い違うときは、**ノート優先**かつ食い違いを明示する（ノートが古い可能性もあるので）
- ヒットがゼロ／薄かったら、その旨ひとこと添えてから一般知識・Web 検索にフォールバックする

### 4. 関連スキルとの連携

- **nb-knowledge**: 検索結果が古かったり、新しい学びを得たら nb-knowledge スキルが発火して新規ノートを書く（こちらと書き手側で対）
- **job-hunter**: 求人系の検索ではこちらと併用。ノートに過去のリサーチ結果があれば再利用してリサーチ重複を避ける

## 重要

- **「Web 検索の前にまず home-memo」** を癖にする。Web より速いし、ユーザー固有の文脈が乗っている
- 検索結果が空でも**呼んだことを隠さない**（「ノートには見つからなかったので一般知識で答える」と明示する）。次に何をしたか説明することでユーザーが信頼できる
- クエリは**短く・キーワード中心**に。長文をそのまま投げると semantic search の精度が落ちる
- 何度も同じセッションで同じトピックなら 2 度目以降は省略してよい（コンテキストに既にあるはず）
