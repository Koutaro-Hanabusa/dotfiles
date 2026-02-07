# fzf + ghq 導入計画書

## 概要

fzf（ファジーファインダー）と ghq（Gitリポジトリ管理）を現在のdotfiles環境に導入し、
ターミナル操作の効率を大幅に向上させる。

### 現在の環境サマリー

| 項目 | 内容 |
|------|------|
| シェル | zsh |
| ターミナル | Ghostty |
| エディタ | Neovim (init.lua + lazy.nvim) |
| Git連携 | git, gh CLI, lazygit, tig |
| モダンCLI | bat, eza, fd, ripgrep |
| ツール管理 | Homebrew |
| dotfiles管理 | chezmoi |
| Neovim検索 | telescope.nvim + telescope-fzf-native |

### 導入ステータス

- fzf: **未インストール**
- ghq: **未インストール**

---

## 1. fzf 導入計画

### 1.1 インストール

```bash
brew install fzf
```

> **注意**: `$(brew --prefix)/opt/fzf/install` は実行しない。
> キーバインドと補完は `.zshrc` で直接管理する（chezmoi管理との相性が良い）。

### 1.2 .zshrc への追加設定

以下を `.zshrc` の末尾（`eval $(thefuck --alias)` の前あたり）に追加する。

```zsh
# ============================================================
# fzf
# ============================================================

# fzf初期化（キーバインド + 補完）
source <(fzf --zsh)

# --- テーマ・レイアウト ---
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline
  --margin=1
  --padding=1
  --prompt='> '
  --pointer='▶'
  --marker='✓'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --preview-window=right:50%:wrap
"
```

> カラーテーマは Catppuccin Mocha に合わせている（Neovimで catppuccin.lua を使用しているため）。
> 好みに応じて変更可能。

### 1.3 FZF_DEFAULT_COMMAND（fd連携）

```zsh
# fd をデフォルト検索コマンドに（隠しファイルも含む、.gitignore準拠）
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
```

### 1.4 Ctrl+T: ファイル検索（bat プレビュー付き）

```zsh
# Ctrl+T: ファイル検索 + bat プレビュー
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"
```

### 1.5 Alt+C: ディレクトリ移動（eza プレビュー付き）

```zsh
# Alt+C: ディレクトリ移動 + eza ツリープレビュー
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --icons --level=2 --color=always {}'
"
```

### 1.6 Ctrl+R: コマンド履歴検索の強化

```zsh
# Ctrl+R: 履歴検索の強化
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'Ctrl-Y: コマンドをコピー'
"
```

### 1.7 Neovim との連携

現在 `telescope.nvim` + `telescope-fzf-native.nvim` が導入済みのため、
Neovim内のファジー検索は telescope がそのまま担当する。追加のNeovimプラグインは不要。

telescope-fzf-native は libfzf を使っているため、シェル側の fzf インストールとは独立して動作する。

---

## 2. ghq 導入計画

### 2.1 インストール

```bash
brew install ghq
```

### 2.2 gitconfig の設定

```bash
git config --global ghq.root ~/src
```

これにより `~/src` 配下にリポジトリが以下の構造で配置される:

```
~/src/
  github.com/
    buri1126/
      project-a/
      project-b/
    other-org/
      project-c/
```

> **注意**: `ghq.root` は `.gitconfig` に書き込まれる。
> `.gitconfig` を chezmoi 管理に入れる場合は、テンプレート化を検討すること。
> 現時点では chezmoi 管理外のため、`git config --global` で直接設定する。

### 2.3 基本的な使い方

```bash
# リポジトリをクローン
ghq get https://github.com/user/repo
ghq get user/repo  # 省略形（GitHubの場合）

# リポジトリ一覧を表示
ghq list

# リポジトリのフルパスを表示
ghq list --full-path

# リポジトリのディレクトリに移動
cd $(ghq root)/$(ghq list | head -1)
```

---

## 3. fzf + ghq 連携

### 3.1 インタラクティブなリポジトリ移動関数

`.zshrc` に以下を追加する:

```zsh
# ============================================================
# ghq + fzf 連携
# ============================================================

# ghq + fzf でリポジトリにジャンプ
repo() {
  local selected
  selected=$(ghq list | fzf --preview "eza --tree --icons --level=2 --color=always $(ghq root)/{}" --header "リポジトリを選択")
  if [ -n "$selected" ]; then
    cd "$(ghq root)/$selected"
  fi
}

# ghq get + fzf: GitHubのリポジトリを検索してクローン
repo-get() {
  local query="$1"
  if [ -z "$query" ]; then
    echo "Usage: repo-get <search-query>"
    return 1
  fi
  gh repo list --limit 100 --json nameWithOwner -q '.[].nameWithOwner' | \
    fzf --header "クローンするリポジトリを選択" | \
    xargs -I {} ghq get {}
}

# ghq管理リポジトリをNeovimで開く
repo-vim() {
  local selected
  selected=$(ghq list | fzf --preview "eza --tree --icons --level=2 --color=always $(ghq root)/{}" --header "Neovimで開くリポジトリを選択")
  if [ -n "$selected" ]; then
    cd "$(ghq root)/$selected" && nvim .
  fi
}
```

### 3.2 使い方

| コマンド | 説明 |
|----------|------|
| `repo` | fzfでリポジトリを選択して `cd` |
| `repo-get <query>` | GitHubリポジトリを検索・選択してクローン |
| `repo-vim` | fzfでリポジトリを選択してNeovimで開く |

---

## 4. 具体的な .zshrc 追加コード（完全版）

以下のコードを `.zshrc` の `eval $(thefuck --alias)` の **直前** に追加する。

```zsh
# ============================================================
# fzf
# ============================================================

# fzf初期化（キーバインド + 補完）
source <(fzf --zsh)

# テーマ・レイアウト（Catppuccin Mocha）
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline
  --margin=1
  --padding=1
  --prompt='> '
  --pointer='▶'
  --marker='✓'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --preview-window=right:50%:wrap
"

# fd をデフォルト検索コマンドに
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Ctrl+T: ファイル検索 + bat プレビュー
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

# Alt+C: ディレクトリ移動 + eza ツリープレビュー
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --icons --level=2 --color=always {}'
"

# Ctrl+R: 履歴検索の強化
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'Ctrl-Y: コマンドをコピー'
"

# ============================================================
# ghq + fzf 連携
# ============================================================

# ghq + fzf でリポジトリにジャンプ
repo() {
  local selected
  selected=$(ghq list | fzf --preview "eza --tree --icons --level=2 --color=always $(ghq root)/{}" --header "リポジトリを選択")
  if [ -n "$selected" ]; then
    cd "$(ghq root)/$selected"
  fi
}

# ghq管理リポジトリをNeovimで開く
repo-vim() {
  local selected
  selected=$(ghq list | fzf --preview "eza --tree --icons --level=2 --color=always $(ghq root)/{}" --header "Neovimで開くリポジトリを選択")
  if [ -n "$selected" ]; then
    cd "$(ghq root)/$selected" && nvim .
  fi
}
```

---

## 5. 導入ステップ（優先順位付き）

### Phase 1: fzf 導入（最優先）

fzf単体でも即座に恩恵が得られる。既存の fd, bat, eza, ripgrep と連携させることで
コマンドライン操作が劇的に改善する。

1. `brew install fzf`
2. `.zshrc` に fzf 設定ブロックを追加（上記セクション4のコード）
3. `chezmoi apply` で反映
4. 新しいシェルセッションを開いて動作確認:
   - `Ctrl+T` でファイル検索（bat プレビュー付き）
   - `Alt+C` でディレクトリ移動（eza ツリープレビュー付き）
   - `Ctrl+R` で履歴検索

### Phase 2: ghq 導入

1. `brew install ghq`
2. `git config --global ghq.root ~/src`
3. 既存リポジトリを ghq 管理に移行（任意）:
   ```bash
   # 既存リポジトリを ghq の管理ディレクトリにクローンし直す
   ghq get https://github.com/buri1126/your-repo
   ```
4. `.zshrc` に ghq + fzf 連携関数を追加（上記セクション4のコード）
5. `chezmoi apply` で反映
6. 動作確認:
   - `repo` でリポジトリ選択 & 移動
   - `repo-vim` でリポジトリを Neovim で開く

### Phase 3: chezmoi管理の整備（任意）

1. `.gitconfig` をchezmoi管理に追加する場合:
   ```bash
   chezmoi add ~/.gitconfig
   ```
2. Brewfile に fzf, ghq を追加して `brew bundle` で再現可能にする

---

## 6. キーバインド早見表

導入後に使えるキーバインドの一覧。

### シェル（zsh + fzf）

| キーバインド | 機能 | プレビュー |
|-------------|------|-----------|
| `Ctrl+T` | ファイルをファジー検索してパスを挿入 | bat（シンタックスハイライト付き） |
| `Alt+C` | ディレクトリをファジー検索して cd | eza（ツリー表示） |
| `Ctrl+R` | コマンド履歴をファジー検索 | コマンド全文表示 |
| `**<Tab>` | fzf補完（例: `cd **<Tab>`, `vim **<Tab>`） | - |

### カスタム関数

| コマンド | 機能 |
|----------|------|
| `repo` | ghqリポジトリをfzf選択して cd |
| `repo-vim` | ghqリポジトリをfzf選択して Neovim で開く |

### Neovim（telescope.nvim, 変更なし）

| キーバインド | 機能 |
|-------------|------|
| `<Space>ff` | ファイル検索 |
| `<Space>fg` | テキスト検索（live grep） |
| `<Space>fb` | バッファ一覧 |
| `<Space>fh` | ヘルプタグ検索 |

---

## 7. 注意事項

### Ghostty ターミナルでの Alt キー

Ghostty では `Alt+C` が正しく動作するために、ターミナルの設定で `Alt` キーを
`Meta` として送信する必要がある場合がある。動作しない場合は Ghostty の設定で
`macos-option-as-alt = true` を確認すること。

### 既存ツールとの衝突

- `telescope-fzf-native` は Neovim 内部で libfzf を使用しており、シェルの fzf とは独立。衝突なし。
- `ripgrep` は `grep` エイリアスで使用中。fzf は独自にファイル検索を行うため衝突なし。
- `fd` は `FZF_DEFAULT_COMMAND` で活用。相互補完の関係。

### パフォーマンス

- `source <(fzf --zsh)` はシェル起動時にfzfの初期化スクリプトを動的生成する。
  起動速度が気になる場合はキャッシュ化を検討（通常は問題ない）。
