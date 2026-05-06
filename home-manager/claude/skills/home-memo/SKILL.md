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

ユーザーの質問の **核となるキーワード** を抽出する。長文の質問をそのまま投げない。

**言語選択ルール:**
- ユーザー発話と同じ言語を主軸にする（日本語ノートは日本語クエリ、英語ノートは英語クエリの方がヒット率が高い）
- 技術用語は英語のまま (`middleware`, `routing`, `WebSocket` など)
- 固有概念や日本語特有の文脈（ファンテック、Findy、企業名）は日本語のまま
- 日英混在クエリも有効（例: `"Hono middleware 認証"`）

```
ユーザー: 「TanStack Router のファイルベースルーティングってどう書くんやっけ？」
→ query: "TanStack Router file-based routing"
```

```
ユーザー: 「前にまとめたファンテック企業のリスト見せて」
→ query: "ファンテック 企業 リスト"
```

```
ユーザー: 「Hono のミドルウェアで認証どうしてた？」
→ query: "Hono middleware 認証"
```

### 2. ツールを呼ぶ

```
mcp__home-memo__search_knowledge(query="...", max_results=5)
```

**`max_results` の段階的拡張ルール:**
- 1 回目: `5`（デフォルト）
- ヒット 0 か明らかにトピックがズレている場合のみ `10` で再検索
- それでも薄い場合は `20` で打ち止めし、フォールバックへ進む

やみくもに最初から `20` を投げない。ノイズが増えて semantic 検索の精度が落ちる。

### 3. 結果を回答に組み込む

**ヒットありの場合:**
- チャンク内容を要約しつつ、**ファイル名を `knowledge/xxx.md` の相対パス形式**で引用する（ユーザーが原典をたどれるように）
- 複数ヒット時の優先順位: ツールが返した **semantic スコア順を主軸** に、年月が分かるノートが混ざる場合は **新しい日付を優先** する（古い情報を最新と勘違いさせない）
- ヒット内容と一般知識を**混ぜて答えてよい**
- ノートと一般知識が食い違うときは **ノート優先** かつ食い違いを明示する（ノートが古い可能性もあるので、年月が分かれば添える）

**ヒットゼロ／薄い場合の手順:**
1. **回答冒頭で**「ノートには見つからなかった」と明示する（透明性のため、結果に紛れ込ませない）
2. 別キーワードで **1 回だけ** 再クエリする。軸の振り方:
   - 同義語に置き換え / 英訳 ↔ 和訳 / 関連用語に拡張 / 具体化（例: `auth` → `Bearer 認証`）
   - **複数軸を同時に変えても OK**（例: `Hono middleware 認証` → `Hono auth middleware`）。元クエリと意味的につながりが残る範囲で
3. それでも空なら一般知識・Web 検索にフォールバック
4. 新規の学びがあれば「ノートに残しますか？」と促すか、`nb-knowledge` 経由で書き残す

### 4. 関連スキルとの連携

- **nb-knowledge**: 検索結果が古かったり、新しい学びを得たら nb-knowledge スキルが発火して新規ノートを書く（こちらと書き手側で対）
- **job-hunter**: 求人系の検索ではこちらと併用。ノートに過去のリサーチ結果があれば再利用してリサーチ重複を避ける

## 重要

- **「Web 検索の前にまず home-memo」** を癖にする。Web より速いし、ユーザー固有の文脈が乗っている
- 検索結果が空でも**呼んだことを隠さない**（「ノートには見つからなかったので一般知識で答える」と明示する）。次に何をしたか説明することでユーザーが信頼できる
- クエリは**短く・キーワード中心**に。長文をそのまま投げると semantic search の精度が落ちる
- 同一セッションで同じトピックを再度問われた場合は、2 度目以降の検索は省略してよい（直前のコンテキストに結果が残っているはず）。**ただしユーザー発話が「別の角度」「もっと深く」と新しい切り口を要求している場合は再検索する**

### 境界条件（迷いやすいケース）

- **「version numbers の skip」**: 「**今の** 最新バージョン」「**現在の** 〜」のように現在値・最新値を問う場合のみ skip。
  「うちのプロジェクトで固定してた 〜 のバージョン覚えてる？」「前に決めた依存バージョン」のように **過去の自分の決定を参照する場合は home-memo を呼ぶ**（個人ノートに記録されている可能性が高い）
- **「コードベース内部質問」**: 「このリポジトリの `src/foo.ts` を読んで」のような直接読解は skip。
  ただし「**前に** このリポジトリで 〜 のパターン使ってたやろ？」のような **過去判断の参照は home-memo を呼ぶ**
