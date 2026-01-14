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

## Vim 基本操作

### モード

| モード | 説明 | 入り方 |
|-------|------|-------|
| Normal | 通常モード（コマンド実行） | `Esc` または `jj` |
| Insert | 入力モード | `i`, `a`, `o` など |
| Visual | 選択モード | `v`, `V`, `Ctrl+v` |
| Command | コマンドラインモード | `:` |

### カーソル移動

| キー | 動作 |
|-----|------|
| `h` | 左 |
| `j` | 下 |
| `k` | 上 |
| `l` | 右 |
| `w` | 次の単語の先頭 |
| `b` | 前の単語の先頭 |
| `e` | 単語の末尾 |
| `0` | 行頭 |
| `$` | 行末 |
| `gg` | ファイル先頭 |
| `G` | ファイル末尾 |
| `Ctrl+d` | 半ページ下 |
| `Ctrl+u` | 半ページ上 |

### 編集

| キー | 動作 |
|-----|------|
| `i` | カーソル位置で挿入 |
| `a` | カーソルの後ろで挿入 |
| `o` | 下に新しい行を作って挿入 |
| `O` | 上に新しい行を作って挿入 |
| `x` | 1文字削除 |
| `dd` | 行削除（カット） |
| `yy` | 行コピー（ヤンク） |
| `p` | ペースト（下/後ろ） |
| `P` | ペースト（上/前） |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `ciw` | 単語を削除して挿入モード |
| `ci"` | `"..."` の中身を削除して挿入 |
| `di(` | `(...)` の中身を削除 |

### 検索・置換

| キー | 動作 |
|-----|------|
| `/検索語` | 前方検索 |
| `?検索語` | 後方検索 |
| `n` | 次の検索結果 |
| `N` | 前の検索結果 |
| `:%s/old/new/g` | 全置換 |
| `:%s/old/new/gc` | 確認しながら全置換 |

---

## nvim操作

Leaderキーは `Space`

### 基本

| キー | 動作 |
|------|------|
| `jj` | Insertモードを抜ける |
| `:q` | 終了（最後のバッファなら全終了） |
| `:Q` | 強制全終了 |

### ウィンドウ操作

| キー | 動作 |
|------|------|
| `Ctrl+h/j/k/l` | ウィンドウ移動 |
| `Ctrl+↑/↓/←/→` | ウィンドウリサイズ |
| `Space` `sv` | 縦分割 |
| `Space` `sh` | 横分割 |
| `Space` `se` | 分割サイズを均等に |
| `Space` `sx` | 現在の分割を閉じる |

### バッファ（タブ）操作

| キー | 動作 |
|------|------|
| `Shift+l` | 次のバッファへ |
| `Shift+h` | 前のバッファへ |
| `Space` `x` | バッファを選んで閉じる |

### ファイル検索（Telescope）

| キー | 動作 |
|------|------|
| `Space` `ff` | ファイル名検索 |
| `Space` `fg` | ファイル内容検索（grep） |
| `Space` `fb` | 開いてるバッファ一覧 |
| `Space` `fh` | ヘルプ検索 |

### ファイルツリー（NvimTree）

| キー | 動作 |
|------|------|
| `Space` `e` | ファイルツリーを開く/閉じる |
| `a` | 新規ファイル/フォルダ作成 |
| `d` | 削除 |
| `r` | リネーム |
| `x` | カット |
| `c` | コピー |
| `p` | ペースト |
| `Enter` | ファイルを開く |

### ターミナル（ToggleTerm）

| キー | 動作 |
|------|------|
| `Ctrl+\` | ターミナル開く/閉じる |
| `Space` `t` | ターミナル開く/閉じる |
| `Space` `th` | 水平ターミナル |
| `Space` `tv` | 垂直ターミナル |
| `Space` `tf` | フロートターミナル |
| `Esc` or `jj` | ターミナルでノーマルモードへ |

### gh-dash（GitHub Dashboard）

`Space` `gh` でGitHub PR/Issueダッシュボードを起動。

| キー | 動作 |
|------|------|
| `Space` `gh` | gh-dash起動 |

#### gh-dash内の操作

| キー | 動作 |
|------|------|
| `j/k` | 上下移動 |
| `Tab` | 次のセクションへ |
| `Enter` | プレビュー表示 |
| `o` | ブラウザで開く |
| `d` | Diff表示 |
| `C` | ブランチをチェックアウト |
| `a` | PRを承認 |
| `m` | PRをマージ |
| `c` | コメント |
| `?` | ヘルプ表示 |
| `q` | 終了 |

インストール: `gh extension install dlvhdr/gh-dash`

### LSP（コード支援）

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバー（ドキュメント表示） |
| `Space` `rn` | リネーム |
| `Space` `ca` | コードアクション |

### 診断（Trouble）

| キー | 動作 |
|------|------|
| `Space` `xx` | 全診断を表示 |
| `Space` `xX` | 現在ファイルの診断のみ |
| `Space` `cs` | シンボル一覧 |
| `Space` `cl` | LSP定義/参照 |

### パスコピー

| キー | 動作 |
|------|------|
| `Space` `yp` | 相対パスをコピー |
| `Space` `yP` | 絶対パスをコピー |
| `Space` `yn` | ファイル名をコピー |
| `Space` `yd` | ディレクトリパスをコピー |

---

## LazyGit

nvim内で `Space` `gg` でLazyGitを起動。

### 起動

| キー | 動作 |
|------|------|
| `Space` `gg` | LazyGit起動 |
| `Space` `gf` | ファイル履歴 |
| `Space` `gc` | 現在ファイルのコミット履歴 |

### LazyGit内の操作

#### パネル移動

| キー | 動作 |
|------|------|
| `h/l` or `1-5` | パネル切替（Status/Files/Branches/Commits/Stash） |
| `j/k` | 項目移動 |
| `q` | 終了 |
| `?` | ヘルプ |

#### ファイル操作（Filesパネル）

| キー | 動作 |
|------|------|
| `Space` | ステージ/アンステージ |
| `a` | 全ファイルをステージ/アンステージ |
| `c` | コミット |
| `A` | amend（直前コミットを修正） |
| `d` | 変更を破棄 |
| `e` | ファイルを編集 |
| `Enter` | 差分を見る |

#### ブランチ操作（Branchesパネル）

| キー | 動作 |
|------|------|
| `Space` | チェックアウト |
| `n` | 新規ブランチ |
| `d` | ブランチ削除 |
| `M` | マージ |
| `r` | リベース |
| `P` | プッシュ |
| `p` | プル |

#### コミット操作（Commitsパネル）

| キー | 動作 |
|------|------|
| `Enter` | コミット詳細 |
| `r` | reword（メッセージ変更） |
| `f` | fixup |
| `s` | squash |
| `d` | コミット削除 |
| `g` | リセットオプション |
| `c` | cherry-pick用にコピー |
| `v` | cherry-pickをペースト |

#### Stash操作

| キー | 動作 |
|------|------|
| `s` | stash作成 |
| `Space` | stash適用 |
| `g` | stash pop |
| `d` | stash削除 |

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

## 含まれる設定ファイル

- `.zshrc` - シェル設定
- `.tmux.conf` - tmux設定
- `.config/nvim/` - Neovim設定
- `.config/ghostty/` - Ghostty設定
- `.config/karabiner/` - Karabiner設定
