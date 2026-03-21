# Neovim Configuration

[パクリ元](https://zenn.dev/vim_jp/articles/1b4344e41b9d5b)

## プラグイン一覧

### ファイル操作

| プラグイン | 説明 |
|-----------|------|
| nvim-tree | ファイルエクスプローラー |
| telescope | ファジーファインダー |
| yazi.nvim | Yaziファイルマネージャー（無効化中） |

### Git連携

| プラグイン | 説明 |
|-----------|------|
| lazygit.nvim | LazyGit統合 |
| gitsigns.nvim | Gitの変更をサイン表示 |
| git-blame.nvim | Git Blame表示 |
| diffview.nvim | Diff表示・コンフリクト解消 |
| octo.nvim | GitHub PR/Issue管理 |

### LSP・補完

| プラグイン | 説明 |
|-----------|------|
| mason.nvim | LSPサーバー管理 |
| nvim-lspconfig | LSP設定 |
| nvim-cmp | 自動補完 |
| LuaSnip | スニペット |

### UI・表示

| プラグイン | 説明 |
|-----------|------|
| catppuccin | カラースキーム（mocha） |
| bufferline | タブ/バッファライン |
| lualine.nvim | ステータスライン（ブランチ・ディレクトリ表示） |
| indent-blankline | インデントガイド |

### ユーティリティ

| プラグイン | 説明 |
|-----------|------|
| toggleterm | ターミナル統合 |
| trouble.nvim | Diagnostics一覧 |
| conform.nvim | フォーマッター |
| nvim-lint | Linter（textlint連携） |
| Comment.nvim | コメントトグル |

---

## キーマップ一覧

Leader key: `<Space>`

### 基本操作

| キー | 説明 |
|------|------|
| `jj` | Insert → Normalモード |
| `<C-h/j/k/l>` | ウィンドウ間移動 |
| `<C-Up/Down/Left/Right>` | ウィンドウリサイズ |

### ファイル操作 (nvim-tree / telescope)

| キー | 説明 |
|------|------|
| `<leader>e` | ファイルエクスプローラー開閉 |
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | テキスト検索（grep） |
| `<leader>fb` | バッファ一覧 |
| `<leader>fh` | ヘルプタグ検索 |

### バッファ操作 (bufferline)

| キー | 説明 |
|------|------|
| `<S-l>` | 次のバッファ |
| `<S-h>` | 前のバッファ |
| `<leader>x` | バッファを閉じる |
| `<leader>bn` | 新規バッファ |
| `<leader>bv` | 新規バッファ（縦分割） |
| `<leader>bh` | 新規バッファ（横分割） |

### ウィンドウ分割

| キー | 説明 |
|------|------|
| `<leader>sv` | 縦分割 |
| `<leader>sh` | 横分割 |
| `<leader>se` | 分割サイズ均等化 |
| `<leader>sx` | 現在のウィンドウを閉じる |

### パスコピー

| キー | 説明 |
|------|------|
| `<leader>yp` | 相対パスをコピー |
| `<leader>yP` | 絶対パスをコピー |
| `<leader>yn` | ファイル名をコピー |
| `<leader>yd` | ディレクトリパスをコピー |

### Git操作 (lazygit / gitsigns / git-blame)

| キー | 説明 |
|------|------|
| `<leader>gg` | LazyGitを開く |
| `<leader>gf` | LazyGit ファイル履歴フィルター |
| `<leader>gc` | LazyGit 現在ファイルのコミット |
| `<leader>gb` | Git Blameトグル |
| `<leader>gh` | gh-dashを開く |

### Diffview（コンフリクト解消）

| キー | 説明 |
|------|------|
| `<leader>dv` | Diffviewを開く |
| `<leader>dc` | Diffviewを閉じる |
| `<leader>dh` | 現在ファイルの変更履歴 |
| `<leader>dH` | 全ファイルの変更履歴 |

**Diffview内でのコンフリクト解消:**

| キー | 説明 |
|------|------|
| `[x` / `]x` | 前/次のコンフリクト箇所へ |
| `<leader>co` | OURSを選択 |
| `<leader>ct` | THEIRSを選択 |
| `<leader>cb` | BASEを選択 |
| `<leader>ca` | 全てを採用 |

### GitHub操作 (octo.nvim)

| キー | 説明 |
|------|------|
| `<leader>ol` | PR一覧 |
| `<leader>oi` | Issue一覧 |
| `<leader>os` | 検索 |
| `<leader>on` | 通知一覧 |

### LSP

| キー | 説明 |
|------|------|
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバードキュメント |
| `<leader>rn` | リネーム |
| `<leader>ca` | コードアクション |

### Diagnostics (trouble.nvim)

| キー | 説明 |
|------|------|
| `<leader>xx` | 全diagnostics一覧 |
| `<leader>xX` | 現在バッファのdiagnosticsのみ |
| `<leader>cs` | シンボル一覧 |
| `<leader>cl` | LSP定義/参照一覧 |
| `<leader>xL` | Location List |
| `<leader>xQ` | Quickfix List |

### Lint (nvim-lint + textlint)

| キー | 説明 |
|------|------|
| `<leader>ll` | 現在のファイルをLint |
| `<leader>lf` | 現在のファイルをtextlintで自動修正 |
| `<leader>la` | リポジトリ全体のmd/ts/tsx/js/jsxをチェック（quickfixに出力） |

**対応ファイル:** Markdown (.md), TypeScript (.ts/.tsx), JavaScript (.js/.jsx), Text (.txt)

#### 結果の見方

**Diagnostics表示:**
- ファイルを開くと自動でLintが実行され、問題箇所に波線が表示される
- `K` でカーソル位置のエラー詳細を確認
- `[d` / `]d` で前後のDiagnosticsへジャンプ

**Quickfix表示 (`<leader>la` 実行後):**
- quickfixウィンドウに全ファイルのエラー一覧が表示される
- `<CR>` で該当箇所へジャンプ
- `:cnext` / `:cprev` で次/前のエラーへ移動
- `:cclose` でquickfixを閉じる

**Trouble.nvim連携:**
- `<leader>xx` でDiagnostics一覧をTroubleで表示
- `<leader>xQ` でQuickfixをTroubleで表示

---

### フォーマット (conform.nvim)

| キー | 説明 |
|------|------|
| `<leader>f` | 手動フォーマット |
| （保存時に自動フォーマット） | |

**対応言語:** JavaScript, TypeScript, JSON, CSS, HTML, Markdown, Lua, Python, Go, PHP

### コメント (Comment.nvim)

| キー | 説明 |
|------|------|
| `<leader>cc` | 行コメントトグル |
| `<leader>cb` | ブロックコメントトグル |
| `<leader>c{motion}` | モーション範囲を行コメント |
| `<leader>b{motion}` | モーション範囲をブロックコメント |

### ターミナル (toggleterm)

| キー | 説明 |
|------|------|
| `<C-\>` | ターミナル開閉 |
| `<leader>t` | ターミナルトグル |
| `<leader>th` | 横分割ターミナル |
| `<leader>tv` | 縦分割ターミナル |
| `<leader>tf` | フロートターミナル |
| `<Esc>` / `jj` | ターミナル → Normalモード |

### 補完 (nvim-cmp)

| キー | 説明 |
|------|------|
| `<Tab>` | 次の候補 / スニペット展開 |
| `<S-Tab>` | 前の候補 |
| `<CR>` | 確定 |
| `<C-Space>` | 補完メニュー表示 |
| `<C-e>` | 補完キャンセル |
| `<C-b>` / `<C-f>` | ドキュメントスクロール |

### その他

| キー | 説明 |
|------|------|
| `<leader>z` | Tmuxペインズームトグル |
| `:q` | バッファが1つなら全終了、複数なら現在のみ閉じる |
| `:Q` | 全終了 |

---

## 対応LSP

- **Lua:** lua_ls
- **TypeScript/JavaScript:** ts_ls
- **Python:** pyright
- **Go:** gopls
