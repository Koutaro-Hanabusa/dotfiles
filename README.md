# dotfiles

Nix Home Manager で管理している dotfiles

## セットアップ

```bash
# Nix をインストール（公式インストーラー）
curl -L https://nixos.org/nix/install | sh

# dotfiles をクローン
git clone https://github.com/Koutaro-Hanabusa/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Home Manager で設定を適用
home-manager switch --flake .
```

---

## Home Manager の使い方

### 構成

設定は `home-manager/` 配下でモジュール分割されている。

```
home-manager/
├── home.nix          # メイン（imports + home.packages + 残りのhome.file）
├── zsh.nix           # programs.zsh（エイリアス、関数、プロンプト）
├── tmux.nix          # programs.tmux（prefix、ペイン操作、ステータスバー）
├── git.nix           # programs.lazygit + programs.gh
├── cli-tools.nix     # programs.bat, eza, fzf, zoxide, ripgrep
├── ghostty.nix       # Ghostty設定（home.file）
├── nvim/             # Neovim設定
├── karabiner/        # Karabiner設定
├── claude/           # Claude Code設定
└── ...               # その他の設定ファイル
```

### 基本コマンド

| コマンド | 動作 |
|----------|------|
| `home-manager switch --flake .` | 設定をビルド・適用 |
| `home-manager generations` | 過去の世代一覧 |
| `home-manager packages` | インストール済みパッケージ一覧 |
| `nix flake update` | flake入力（nixpkgs, home-manager）を更新 |

### 典型的なワークフロー

```bash
# 1. 設定ファイルを編集（例: zsh.nixを変更）
vim ~/dotfiles/home-manager/zsh.nix

# 2. ビルド・適用
home-manager switch --flake ~/dotfiles

# 3. 変更をコミット・プッシュ
cd ~/dotfiles
git add -A && git commit -m "update zsh config" && git push
```

### programs.\<package\> で管理しているツール

以下のツールは `programs.<package>.enable = true` で宣言的に管理されている。
パッケージのインストールと設定が一体で管理される。

| モジュール | 管理対象 |
|-----------|---------|
| `zsh.nix` | zsh, zsh-autosuggestions, zsh-syntax-highlighting |
| `tmux.nix` | tmux |
| `git.nix` | lazygit, gh |
| `cli-tools.nix` | bat, eza, fzf, zoxide, ripgrep |

### home.packages で管理しているツール

設定ファイルが不要なツールは `home.packages` でインストールのみ管理。

neovim, neovim-remote, stylua, tig, fd, ghq, glow, go, go-task, curl, nmap, pandoc

### home.file で管理している設定

`programs.<package>` に対応するモジュールがないものは `home.file` + `mkOutOfStoreSymlink` でシンボリックリンク管理。
ファイルを直接編集すると即時反映される。

- `.config/nvim` — Neovim
- `.config/ghostty` — Ghostty（macOSでNixパッケージ未対応のため）
- `.config/karabiner` — Karabiner
- `.claude` — Claude Code
- `.config/claude-otel-monitoring` — Claude OTel Monitoring
- `.config/gh-dash` — gh-dash
- `.nbrc`, `.prettierrc`, `.textlintrc.json` 等

---

## nvim + Claude Code 統合環境

`vim`や`nvc`コマンドでnvimとClaude Codeが左右分割で起動する。

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
| `nvc` | 同上 |

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
| `Ctrl+a` `M` | マウスモード ON/OFF |
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

### gco（ブランチ切り替え）

fzfでブランチをファジー検索して切り替え。

```bash
gco cheese    # → sen/8122-cheese にマッチして切り替え
```

### ブランチ名規約チェック

`git checkout -b` / `git switch -c` 時にブランチ名が推奨パターンに沿っているか自動チェック。

```
推奨: <type>/<TICKET番号>-<short-summary>
例:   feature/55-add-login-page
```

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
| Lua (`.lua`) | stylua | Nix で管理 |
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
| `@.frontend-developer` | フロントエンド全般 |
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
全て Nix Home Manager の `programs.<package>` で宣言的に管理。

### bat（catの代替）

シンタックスハイライト、行番号表示、Git差分統合を備えたファイル表示ツール。

**エイリアス:** `cat` → `bat`

| コマンド | 動作 |
|---------|------|
| `bat file.txt` | シンタックスハイライト付きでファイルを表示 |
| `bat -n file.txt` | 行番号のみ表示（ヘッダーなし） |
| `bat -p file.txt` | プレーンモード（装飾なし） |
| `bat -l json file.txt` | 言語を指定して表示 |
| `bat --diff file.txt` | Git差分をハイライト表示 |

### eza（lsの代替）

アイコン表示、Git状態表示、ツリー表示に対応したファイル一覧ツール。

**エイリアス:** `ls` → `eza --icons --git`, `ll` → `eza -la --icons --git`, `la` → `eza -a --icons --git`, `tree` → `eza --tree --icons`

| コマンド | 動作 |
|---------|------|
| `ls` | アイコン・Git状態付きでファイル一覧 |
| `ll` | 詳細表示（パーミッション、サイズ等） |
| `la` | 隠しファイル含む一覧 |
| `tree` | ツリー形式で表示 |
| `tree -L 2` | 深さ2までのツリー表示 |

### fzf（ファジーファインダー）

`programs.fzf` でZsh統合を有効化。`Ctrl+R`（履歴検索）、`Ctrl+T`（ファイル検索）が自動設定される。

| キー | 動作 |
|------|------|
| `Ctrl+R` | コマンド履歴をファジー検索 |
| `Ctrl+T` | ファイルをファジー検索してパスを挿入 |
| `Ctrl+G` | ghqリポジトリをファジー検索してcd |

### zoxide（cdの代替）

`programs.zoxide` でZsh統合を有効化。`cd` コマンドが zoxide に置き換わる。

| コマンド | 動作 |
|---------|------|
| `cd <dir>` | 通常のcd（初回）/ スマートジャンプ（2回目以降） |
| `cdi <query>` | インタラクティブに候補を選択してcd |

### ripgrep（grepの代替）

高速な全文検索ツール。`.gitignore`を自動的に尊重する。

**エイリアス:** `grep` → `rg`

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

ターミナル内で動作するTUI Gitクライアント。`programs.lazygit` で設定管理。
`C` キーでAIコミットメッセージ生成（Claude Haiku使用）。

| キー | 動作 |
|------|------|
| `space` | ファイルのステージング/アンステージング |
| `c` | コミット |
| `C` | AIコミット（Conventional Commits形式） |
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

直前のコマンドのタイポや間違いを自動で検出・修正してくれるツール（Homebrew管理、遅延ロード）。

| コマンド | 動作 |
|---------|------|
| `fuck` | 直前のコマンドを修正して再実行 |

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
