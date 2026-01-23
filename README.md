# dotfiles

chezmoiで管理しているdotfiles

## セットアップ

```bash
# chezmoiをインストール
brew install chezmoi

# dotfilesを適用
chezmoi init --apply Koutaro-Hanabusa
```

---

## chezmoiの使い方

### 基本コマンド

| コマンド | 動作 |
|----------|------|
| `chezmoi cd` | ソースディレクトリに移動 |
| `chezmoi status` | 変更があるファイルを確認 |
| `chezmoi diff` | 適用される変更の差分を表示 |
| `chezmoi apply` | 変更をホームディレクトリに適用 |
| `chezmoi apply -v` | 適用内容を表示しながら適用 |

### ファイルの追加・編集

| コマンド | 動作 |
|----------|------|
| `chezmoi add ~/.zshrc` | ファイルをchezmoi管理下に追加 |
| `chezmoi add --template ~/.zshrc` | テンプレートとして追加 |
| `chezmoi edit ~/.zshrc` | 管理ファイルを編集 |
| `chezmoi forget ~/.zshrc` | 管理から除外（実ファイルは残る） |

### 同期

| コマンド | 動作 |
|----------|------|
| `chezmoi update` | リモートから取得して適用 |
| `chezmoi git pull` | ソースリポジトリをpull |
| `chezmoi git push` | ソースリポジトリをpush |
| `chezmoi git status` | ソースリポジトリの状態確認 |

### 確認・デバッグ

| コマンド | 動作 |
|----------|------|
| `chezmoi data` | テンプレートで使える変数を表示 |
| `chezmoi cat ~/.zshrc` | 適用後の内容をプレビュー |
| `chezmoi source-path ~/.zshrc` | ソースファイルのパスを表示 |
| `chezmoi managed` | 管理中のファイル一覧 |

### 典型的なワークフロー

```bash
# 1. 設定ファイルを編集
chezmoi edit ~/.zshrc

# 2. 差分を確認
chezmoi diff

# 3. 変更を適用
chezmoi apply

# 4. 変更をコミット・プッシュ
chezmoi cd
git add -A && git commit -m "update zshrc" && git push
```

### ファイル名の規則

chezmoiはソースディレクトリで特殊なプレフィックスを使用：

| プレフィックス | 意味 |
|----------------|------|
| `dot_` | `.`に変換（例: `dot_zshrc` → `.zshrc`） |
| `private_` | パーミッション600で作成 |
| `executable_` | 実行権限を付与 |
| `readonly_` | 読み取り専用 |
| `create_` | 存在しない場合のみ作成 |
| `modify_` | 既存ファイルを修正するスクリプト |
| `run_` | 適用時に実行されるスクリプト |

---

## nvim + Claude Code 統合環境

`vim`や`code`コマンドでnvimとClaude Codeが左右分割で起動する。

```
┌────────────────────────────┬───────┐
│                            │       │
│           nvim             │Claude │
│           (75%)            │ Code  │
│                            │ (25%) │
│                            │       │
└────────────────────────────┴───────┘
```

### 起動コマンド

| コマンド | 動作 |
|----------|------|
| `vim` | nvim + Claude Code 起動 |
| `code` | nvim + Claude Code 起動 |
| `nvc` | 同上 |
| `nvim-raw` | 純粋なnvimのみ起動 |

### 終了

nvimで`:q`すればtmuxセッションごと終了する。

### Claude Code連携キーバインド

nvim内でClaude Codeと連携するためのキーバインド。

| キー | 動作 |
|------|------|
| `Space` `ac` | Claude Codeパネルのトグル |
| `Space` `as` | 選択範囲をClaudeに送信（Visual mode） |
| `Space` `aa` | 現在のファイルをClaudeに追加 |

---

## tmux操作

prefixキーは `Ctrl+a`

| キー | 動作 |
|------|------|
| `Ctrl+a` `h/j/k/l` | ペイン移動 |
| `Ctrl+a` `H/J/K/L` | ペインリサイズ |
| `Ctrl+a` `\|` | 縦分割 |
| `Ctrl+a` `-` | 横分割 |
| `Ctrl+a` `d` | デタッチ（セッション維持） |
| `tmux attach` | セッションに再接続 |
| マウス | ペイン選択・リサイズ可 |

---

## Git関連ツール

### Diffview（差分表示）

| キー | 動作 |
|------|------|
| `Space` `dv` | Diffviewを開く（現在の変更を表示） |
| `Space` `dc` | Diffviewを閉じる |
| `Space` `dh` | 現在ファイルの履歴 |
| `Space` `dH` | 全ファイルの履歴 |

Diffview内でのコンフリクト解決:

| キー | 動作 |
|------|------|
| `Space` `co` | oursを選択 |
| `Space` `ct` | theirsを選択 |
| `Space` `cb` | baseを選択 |
| `Space` `ca` | allを選択 |

### Octo（GitHub連携）

nvim内でGitHubのPR/Issueを操作。

| キー | 動作 |
|------|------|
| `Space` `ol` | PR一覧 |
| `Space` `oi` | Issue一覧 |
| `Space` `os` | 検索 |
| `Space` `on` | 通知一覧 |

コマンド例:
- `:Octo pr create` - PRを作成
- `:Octo pr checkout <number>` - PRをチェックアウト
- `:Octo issue create` - Issueを作成
- `:Octo review start` - PRレビューを開始

---

## 自動フォーマット

`:w`（保存）時に自動でフォーマットされる（[conform.nvim](https://github.com/stevearc/conform.nvim)使用）

### 対応フォーマッター

| ファイルタイプ | フォーマッター | インストール |
|---------------|---------------|-------------|
| JavaScript (`.js`) | prettier | `npm install -g prettier` |
| TypeScript (`.ts`) | prettier | `npm install -g prettier` |
| TypeScript React (`.tsx`) | prettier | `npm install -g prettier` |
| JavaScript React (`.jsx`) | prettier | `npm install -g prettier` |
| JSON (`.json`) | prettier | `npm install -g prettier` |
| CSS (`.css`) | prettier | `npm install -g prettier` |
| HTML (`.html`) | prettier | `npm install -g prettier` |
| Markdown (`.md`) | prettier | `npm install -g prettier` |
| Lua (`.lua`) | stylua | `brew install stylua` |
| Python (`.py`) | black | `pip install black` |
| Go (`.go`) | gofmt | Go に同梱 |
| PHP (`.php`) | pint | `composer global require laravel/pint` |

### 手動フォーマット

`<Space>f` で現在のバッファを手動フォーマット

---

## Vim / Neovim 操作ガイド

詳細は `vimhelp` コマンドで表示できます。

```bash
vimhelp
```

または直接ファイルを参照: [dot_config/nvim/doc/README.md](dot_config/nvim/doc/README.md)

---

## Karabiner（Mouse Keys Mode）

`d`キーを押しながら他のキーでマウス操作ができる。マウスに手を伸ばさずに操作可能。

### 起動方法

`d` + `h/j/k/l` のいずれかを同時押しでモード開始。キーを離すとモード終了。

### カーソル移動

| キー | 動作 |
|------|------|
| `d` + `h` | 左に移動 |
| `d` + `j` | 下に移動 |
| `d` + `k` | 上に移動 |
| `d` + `l` | 右に移動 |

### クリック

| キー | 動作 |
|------|------|
| `d` + `u` | 左クリック |
| `d` + `i` | 中クリック |
| `d` + `o` | 右クリック |

### スクロール

| キー | 動作 |
|------|------|
| `d` + `s` 押しながら `j` | 下スクロール |
| `d` + `s` 押しながら `k` | 上スクロール |
| `d` + `s` 押しながら `h` | 左スクロール |
| `d` + `s` 押しながら `l` | 右スクロール |

### 速度調整

| キー | 動作 |
|------|------|
| `d` + `f` | 速度2倍（押している間） |
| `d` + `g` | 速度0.5倍（押している間） |

### 画面移動

| キー | 動作 |
|------|------|
| `d` + `v` | 次の画面にサイクル（0→1→2→0...） |
| `d` + `n` | 現在のウィンドウ中央へ |

---

## Claude Code 設定

`.claude/` ディレクトリでClaude Codeをカスタマイズ。

### カスタムエージェント

タスクに応じて専門のサブエージェントに委譲される。

| エージェント | 役割 |
|-------------|------|
| `@.react-pro` | React専門 |
| `@.frotend-developer` | フロントエンド全般 |
| `@.golang-pro` | Go言語専門 |
| `@.backend-developer` | バックエンド全般 |
| `@.laravel-pro` | Laravel専門 |
| `@.qa-expert` | QA・テスト専門 |
| `@.task-distributor` | タスク分配 |

### カスタムコマンド

| コマンド | 説明 |
|---------|------|
| `/fetch_today` | 今日の情報を取得 |
| `/issue-child` | 子Issue作成 |
| `/review` | PRレビュー |

### インストール済みプラグイン

| プラグイン | 機能 |
|-----------|------|
| `typescript-lsp` | TypeScript言語サーバー連携 |
| `pr-review-toolkit` | PRレビュー支援 |
| `figma` | Figma DevMode連携 |

### その他の設定

- **常時Thinking有効** - 思考プロセスを常に表示
- **完了時サウンド** - タスク完了時にドラクエのレベルアップ音
- **日本語応答** - 常に日本語で応答

---

## nb（ナレッジ管理）

[nb](https://github.com/xwmx/nb)でQ&Aや学びをノートブックに蓄積。

### 基本操作

| コマンド | 動作 |
|---------|------|
| `nb list` | ノート一覧 |
| `nb add` | 新規ノート作成 |
| `nb edit <id>` | ノートを編集 |
| `nb search <query>` | ノートを検索 |
| `nb show <id>` | ノートを表示 |

### ノートブック構成

- `home:knowledge/` - 個人PCのナレッジ
- `work:knowledge/` - 仕事PCのナレッジ（`.is_work_pc`で判定）

Claude Codeとの連携で、Q&Aのやり取りが自動的にナレッジとして蓄積される。

---

## 含まれる設定ファイル

- `.zshrc` - シェル設定
- `.tmux.conf` - tmux設定
- `.config/nvim/` - Neovim設定
- `.config/ghostty/` - Ghostty設定
- `.config/karabiner/` - Karabiner設定
- `.claude/` - Claude Code設定（エージェント、コマンド、プラグイン）
- `.nbrc` - nb（ノートブック）設定
