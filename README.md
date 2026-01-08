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

## nvim + Claude Code 統合環境

`vim`や`code`コマンドでnvimとClaude Codeが左右分割で起動する。

```
┌──────────────────────┬──────────┐
│                      │          │
│        nvim          │  Claude  │
│       (2/3)          │  Code    │
│                      │  (1/3)   │
│                      │          │
└──────────────────────┴──────────┘
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

## 含まれる設定ファイル

- `.zshrc` - シェル設定
- `.tmux.conf` - tmux設定
- `.config/nvim/` - Neovim設定
- `.config/ghostty/` - Ghostty設定
- `.config/karabiner/` - Karabiner設定
