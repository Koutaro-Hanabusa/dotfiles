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

### Claude Code連携キーバインド（claudecode.nvim）

nvim内でClaude Codeと連携するためのキーバインド。

| キー | 動作 |
|------|------|
| `Space` `ac` | tmux右分割ターミナルを開く（40%幅） |
| `Space` `ar` | Claude Codeセッション再開（ピッカー） |
| `Space` `ao` | 直前のセッションを継続 |
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
| JavaScript (`.js`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| TypeScript (`.ts`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| TypeScript React (`.tsx`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| JavaScript React (`.jsx`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| JSON (`.json`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| CSS (`.css`) | biome → prettier | `npm install -g @biomejs/biome prettier` |
| HTML (`.html`) | prettier | `npm install -g prettier` |
| Markdown (`.md`) | prettier | `npm install -g prettier` |
| Lua (`.lua`) | stylua | `brew install stylua` |
| Python (`.py`) | black | `pip install black` |
| Go (`.go`) | gofmt | Go に同梱 |
| PHP (`.php`) | pint | `composer global require laravel/pint` |

※ `biome → prettier` はbiomeを優先し、なければprettierにフォールバック

### 手動フォーマット

`<Space>f` で現在のバッファを手動フォーマット

---

## LSP（言語サーバー）

Mason経由で自動インストール。

| 言語 | LSP | 対象ファイル |
|------|-----|-------------|
| Lua | lua_ls | `.lua` |
| TypeScript / JavaScript | ts_ls | `.ts`, `.tsx`, `.js`, `.jsx` |
| Python | pyright | `.py` |
| Go | gopls | `.go`, `go.mod` |
| PHP | intelephense | `.php` |

### LSPキーバインド

| キー | 動作 |
|------|------|
| `gd` | 定義にジャンプ |
| `K` | ホバードキュメント |
| `gr` | 参照を検索 |
| `Space` `rn` | シンボルをリネーム |
| `Space` `ca` | コードアクション |

---

## textlint（日本語校正）

[textlint](https://textlint.github.io/)で日本語の文章をチェック。

### インストール

```bash
npm install -g textlint \
  textlint-rule-preset-ja-technical-writing \
  textlint-rule-preset-japanese \
  @textlint-ja/textlint-rule-preset-ai-writing \
  textlint-plugin-jsx
```

### 対象ファイル

| ファイルタイプ | 拡張子 |
|---------------|--------|
| Markdown | `.md` |
| Text | `.txt` |
| JSX | `.jsx` |
| TSX | `.tsx` |

### Neovimでの使い方

#### 自動実行

ファイルを開いた時、保存時、Insert離脱時に自動でlint実行。

#### キーバインド

| キー | 動作 |
|------|------|
| `<Space>ll` | 現在のファイルをlint |
| `<Space>lf` | 現在のファイルを自動修正 |
| `<Space>la` | リポジトリ全体の`.md`をチェック（quickfix） |

#### エラー確認

- `:copen` - quickfixウィンドウを開く
- `:cnext` / `:cprev` - 次/前のエラーへ移動
- `:Trouble quickfix` - Troubleでエラー一覧表示

### CLIでの使い方

```bash
# ファイルをチェック
textlint README.md

# 自動修正
textlint --fix README.md

# 複数ファイル
textlint "docs/**/*.md"
```

### 適用ルール

| ルール | 説明 |
|--------|------|
| `preset-ja-technical-writing` | 技術文書向け（文長、句読点など） |
| `preset-japanese` | 一般的な日本語ルール |
| `@textlint-ja/preset-ai-writing` | AI生成テキストの癖を検出 |

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

## モダンCLIツール

従来のUnixコマンドをより高機能なツールに置き換えるエイリアスを設定している。

### bat（catの代替）

シンタックスハイライト、行番号表示、Git差分統合を備えたファイル表示ツール。

**エイリアス設定:**

```bash
alias cat="bat"
```

| コマンド | 動作 |
|---------|------|
| `bat file.txt` | シンタックスハイライト付きでファイルを表示 |
| `bat -n file.txt` | 行番号のみ表示（ヘッダーなし） |
| `bat -p file.txt` | プレーンモード（装飾なし） |
| `bat -l json file.txt` | 言語を指定して表示 |
| `bat --diff file.txt` | Git差分をハイライト表示 |

### eza（lsの代替）

アイコン表示、Git状態表示、ツリー表示に対応したファイル一覧ツール。

**エイリアス設定:**

```bash
alias ls="eza --icons --git"
alias ll="eza -la --icons --git"
alias la="eza -a --icons --git"
alias tree="eza --tree --icons"
```

| コマンド | 動作 |
|---------|------|
| `ls` | アイコン・Git状態付きでファイル一覧 |
| `ll` | 詳細表示（パーミッション、サイズ等） |
| `la` | 隠しファイル含む一覧 |
| `tree` | ツリー形式で表示 |
| `tree -L 2` | 深さ2までのツリー表示 |

### ripgrep（grepの代替）

高速な全文検索ツール。`.gitignore`を自動的に尊重する。

**エイリアス設定:**

```bash
alias grep="rg"
```

| コマンド | 動作 |
|---------|------|
| `rg "pattern"` | カレントディレクトリ以下を再帰検索 |
| `rg "pattern" -t py` | Pythonファイルのみ検索 |
| `rg "pattern" -i` | 大文字小文字を区別しない検索 |
| `rg "pattern" -l` | マッチしたファイル名のみ表示 |
| `rg "pattern" -C 3` | 前後3行のコンテキスト付き表示 |

### fd（findの代替）

高速でユーザーフレンドリーなファイル検索ツール。直感的な構文で`.gitignore`を自動尊重する。

| コマンド | 動作 |
|---------|------|
| `fd "pattern"` | ファイル名をパターンで検索 |
| `fd -e md` | 拡張子で検索（`.md`ファイル） |
| `fd -t d` | ディレクトリのみ検索 |
| `fd -t f` | ファイルのみ検索 |
| `fd -H "pattern"` | 隠しファイルも含めて検索 |

### lazygit

ターミナル内で動作するTUI（テキストユーザーインターフェース）のGitクライアント。キーボードだけでステージング、コミット、ブランチ操作などができる。

| コマンド | 動作 |
|---------|------|
| `lazygit` | TUI Gitクライアントを起動 |
| `lazygit -p` | パッチモードで起動 |

主な操作キー:

| キー | 動作 |
|------|------|
| `space` | ファイルのステージング/アンステージング |
| `c` | コミット |
| `p` | プッシュ |
| `P` | プル |
| `]` / `[` | 次/前のタブ |

### tig

テキストモードのGitインターフェース。コミットログの閲覧やdiff表示に優れる。

| コマンド | 動作 |
|---------|------|
| `tig` | コミットログを表示 |
| `tig blame file.txt` | ファイルのblameを表示 |
| `tig status` | ステータスビュー |
| `tig stash` | stash一覧 |
| `tig refs` | ブランチ・タグ一覧 |

### thefuck（コマンド自動修正）

直前のコマンドのタイポや間違いを自動で検出・修正してくれるツール。

**エイリアス設定:**

```bash
eval $(thefuck --alias)
```

| コマンド | 動作 |
|---------|------|
| `fuck` | 直前のコマンドを修正して再実行 |

使用例:

```bash
$ git brnach
git: 'brnach' is not a git command.

$ fuck
git branch  # 自動修正されて実行される
```

---

## Neovimプラグイン一覧

lazy.nvimで管理。1日1回バックグラウンドで更新チェックし、更新があれば通知表示（`:Lazy update` で手動更新）。

### エディタ・UI

| プラグイン | 機能 |
|-----------|------|
| catppuccin | カラースキーム |
| lualine.nvim | ステータスライン |
| bufferline.nvim | バッファタブ |
| indent-blankline.nvim | インデントガイド |
| nvim-web-devicons | ファイルアイコン |
| nvim-tree.lua | ファイルエクスプローラー |
| which-key.nvim | キーマップヒント表示 |
| trouble.nvim | 診断・エラー一覧 |

### コーディング

| プラグイン | 機能 |
|-----------|------|
| nvim-treesitter | シンタックスハイライト |
| nvim-ts-autotag | HTMLタグ自動閉じ |
| nvim-cmp | 自動補完 |
| LuaSnip | スニペットエンジン |
| nvim-autopairs | 括弧の自動補完 |
| Comment.nvim | コメントトグル（`gc`） |
| conform.nvim | 自動フォーマット |
| nvim-lint | Linter統合（textlint等） |

### Git

| プラグイン | 機能 |
|-----------|------|
| gitsigns.nvim | Git差分表示（行単位） |
| git-blame.nvim | Git blame表示 |
| diffview.nvim | 差分ビューア |
| lazygit.nvim | lazygit統合 |
| octo.nvim | GitHub PR/Issue操作 |

### ツール

| プラグイン | 機能 |
|-----------|------|
| telescope.nvim | ファジーファインダー |
| toggleterm.nvim | ターミナル管理 |
| claudecode.nvim | Claude Code統合 |
| img-clip.nvim | クリップボードから画像ペースト（`Space` `p`） |
| image.nvim | ターミナル内画像表示 |

---

## 含まれる設定ファイル

- `.zshrc` - シェル設定
- `.tmux.conf` - tmux設定
- `.config/nvim/` - Neovim設定
- `.config/ghostty/` - Ghostty設定
- `.config/karabiner/` - Karabiner設定
- `.claude/` - Claude Code設定（エージェント、コマンド、プラグイン）
- `.nbrc` - nb（ノートブック）設定
- `.textlintrc.json` - textlint設定
