> ⚠️ **ARCHIVED — 旧 chezmoi 時代のスナップショット**
> このリポジトリは chezmoi → Nix Home Manager へ移行済み。本書の大半（mise/fzf/ghq/zoxide/glow 導入、nvm 競合解消など）は移行で解決済みであり、`chezmoi apply` / `brew install` / `dot_` パス前提の手順はもう当てはまらない。未実装アイデア（git-delta, starship, atuin, btop など）の参照用としてのみ残す。

# Dotfiles 改善・新規ツール導入計画

> 作成日: 2026-02-11
> 監査対象: chezmoi管理下の全設定ファイル

---

## Part 1: 現状の問題点と改善（全22件）

### 🔴 優先度: 高（6件）

#### 1. テーマ不統一: Ghostty=Kanagawa Dragon / Neovim=Catppuccin Mocha
- `dot_config/ghostty/config:6` → Kanagawa Dragon（背景 `#181616`）
- `dot_config/nvim/lua/plugins/catppuccin.lua:7` → Catppuccin Mocha
- **対策**: どちらかに統一。Ghostty背景色がKanagawa向けなので、NvimもKanagawaにするか、Ghostty側をCatppuccin Mochaに変更

#### 2. nvm と mise の競合
- `dot_zshrc:1-6` で mise と nvm の両方を読み込んでいる
- mise未インストールで毎回 `command not found: mise` エラー
- **対策**: miseをインストールし、nvm関連（行4-6）を削除

#### 3. MySQL PATHの重複
- `dot_zshrc:8-9` で MySQL 5.7 と 8.3 のPATHが両方設定
- **対策**: 使用するバージョンのみ残す。またはmise管理に移行

#### 4. .gitconfig が chezmoi 管理外
- `core.editor = vim` だが実際はnvim（.nbrcでは `EDITOR=nvim`）
- **対策**: `dot_gitconfig.tmpl` を作成。テンプレートで仕事/個人のemail切り替えも可能に

#### 5. .ssh/config のセキュリティ問題
- 同一IP `44.205.253.128` のエントリが重複
- `IdentityFile /Users/1126buri/.sshec2key.pem` → パスに `/` が抜けている
- 3つ目のエントリで相対パス `ec2key.pem`（動作不安定）
- **対策**: パス修正、最低限chezmoiテンプレートで管理

#### 6. Claude Code settings.json にハードコードされたパス
- `dot_claude/settings.json:12` → `afplay /Users/hanabusa.kotaro/Downloads/...`
- ユーザー名 `hanabusa.kotaro` ≠ 現在の `1126buri`。動作しない
- **対策**: `.tmpl` にして `{{ .chezmoi.homeDir }}` を使用

### 🟡 優先度: 中（9件）

#### 7. zshrc起動速度の改善
- `brew --prefix` が毎回実行（行23）→ `/opt/homebrew` にハードコード
- `eval $(thefuck --alias)` が毎回実行（行107）→ 遅延ロード化
- `source /opt/homebrew/etc/bash_completion.d/git-prompt.sh` → Homebrewパスハードコード
- **対策**: 静的パス化 + thefuck遅延ロード

#### 8. chezmoiテンプレート活用不足
- 現在 `.tmpl` は `dot_textlintrc.json.tmpl` のみ
- zshrc, gitconfig等で環境依存設定をテンプレート化すべき
- `.is_work_pc` ファイルでnb notebook切り替え等も可能
- **対策**: 主要dotfilesを `.tmpl` に移行

#### 9. Brewfileに未使用ツールが含まれる
- `fish`（行23）: zshメインなのに入っている
- `bash` + `bash-completion@2`: zsh環境では不要
- `tree`（行48）: `alias tree="eza --tree --icons"` で代替済み
- **対策**: 使用しないものを削除

#### 10. nvim image.nvim の backend 設定
- `dot_config/nvim/lua/plugins/image.lua:11` → `backend = "kitty"` だがGhostty使用
- Ghosttyはkittyプロトコル互換だが、コメントで明記すべき

#### 11. nvim-autopairs の opts 二重ネスト
- `dot_config/nvim/lua/plugins/autopairs.lua:18-19`
- `opts = { opts = { ... } }` と二重にネスト
- **対策**: 外側の `opts` を削除

#### 12. lazy-lock.json の管理方針が不明確
- `.chezmoiignore` と `.gitignore` 両方で言及、だがリポジトリに存在
- **対策**: 管理する/しないを明確にする

#### 13. エージェントファイル名のtypo
- `dot_claude/agents/frotend-developer.md` → "f**ro**ntend" のスペルミス
- `dot_claude/agents/reacr-pro.md` → "rea**cr**" のスペルミス
- CLAUDE.md内でも `@.frotend-developer` と参照
- **対策**: ファイル名を修正

#### 14. catppuccin の `transparent_background = false`
- Ghosttyの `background-opacity = 0.85` で半透明にしているが
- Neovim側で不透明 → 半透明が活かせない
- **対策**: `transparent_background = true` にする

#### 15. glow が未インストールなのに .zshrc で参照
- `_show_md` 関数（行93-98）でglowを使おうとしている
- `dothelp`/`vimhelp` コマンドが意図通りに動かない
- **対策**: Brewfileにglow追加

### 🟢 優先度: 低（6件）

| # | 問題 | ファイル |
|---|------|----------|
| 16 | nvc()関数にコメントアウトが散在 | dot_zshrc:69-90 |
| 17 | `vim.loop.fs_stat` は deprecated (→ `vim.uv`) | init.lua:103 |
| 18 | yazi.nvim が `enabled=false` で残っている | plugins/yazi.lua:3 |
| 19 | conform.nvim の timeout_ms=500 が短い（大きなファイルでタイムアウト） | conform.lua:20 |
| 20 | lazygit の設定ファイルが chezmoi 管理外 | ~/.config/lazygit/ |
| 21 | gitconfig の core.editor が nvim でなく vim | ~/.gitconfig |

---

## Part 2: 新規ツール導入候補

### Phase 1: 即導入（効果大・導入簡単）

| ツール | 概要 | 既存との関係 | Homebrew |
|--------|------|-------------|----------|
| **starship** | Rust製モダンプロンプト。TOML設定、Nerd Font対応 | git-prompt.sh + カスタムPROMPTを置換 | `brew install starship` |
| **zoxide** | 学習型cd。frecencyアルゴリズム | `z foo` でスマートジャンプ。fzf統合あり | `brew install zoxide` |
| **delta** | git diff/blame のシンタックスハイライトページャー | batと同テーマ、side-by-side表示 | `brew install git-delta` |
| **mise** | 多言語ランタイム管理 + タスクランナー + 環境変数管理 | nvm/asdf置換。zshrcで既に参照 | `brew install mise` |
| **glow** | ターミナルMarkdownレンダラー | zshrcで既に参照済み。nb/pandocと相性良 | `brew install glow` |

### Phase 2: 近日導入（ワークフロー改善）

| ツール | 概要 | 既存との関係 | Homebrew |
|--------|------|-------------|----------|
| **atuin** | SQLiteベースのシェル履歴。暗号化同期、全文検索 | fzf Ctrl+R を強化/置換 | `brew install atuin` |
| **btop** | C++製リッチシステムモニター | htop上位互換、マウス対応 | `brew install btop` |
| **jq + yq** | JSON/YAML/XML/TOML等の構造化データ処理 | 新規（必須級） | `brew install jq yq` |
| **lazydocker** | Docker/Compose TUI（lazygitと同作者） | Docker使用時に操作感統一 | `brew install lazydocker` |
| **age** | モダンなファイル暗号化。GPG代替 | chezmoi暗号化と相性抜群 | `brew install age` |

### Phase 3: 余裕があれば（Nice to have）

| ツール | 概要 | Homebrew |
|--------|------|----------|
| **difftastic** | AST解析による構造的diff | `brew install difftastic` |
| **just** | Rust製タスクランナー（Makefile代替） | `brew install just` |
| **hyperfine** | コマンドベンチマーク（統計分析付き） | `brew install hyperfine` |
| **tokei** | コード統計（150+言語対応） | `brew install tokei` |
| **dust** | du代替（視覚的ディスク使用量） | `brew install dust` |
| **procs** | ps代替（カラフル、Docker/ポート対応） | `brew install procs` |
| **git-absorb** | fixupコミット自動割当 | `brew install git-absorb` |

---

## Part 3: 導入ロードマップ

### Step 1: 既存dotfilesの修正（即時）

```bash
# 1. Brewfile更新（不要削除 + 新規追加）
# 2. dot_zshrc: mise有効化、nvm削除、thefuck遅延化、brew --prefix静的化
# 3. dot_gitconfig.tmpl 新規作成
# 4. エージェントファイル名typo修正
# 5. Claude settings.json のパス修正
```

### Step 2: Phase 1ツールの導入・設定

```bash
# 1. brew bundle でインストール
brew bundle --file=~/.local/share/chezmoi/Brewfile

# 2. starship設定
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
# → git-prompt.sh / カスタムPROMPT削除
# → ~/.config/starship.toml 作成してchezmoi管理

# 3. zoxide設定
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc

# 4. delta設定（gitconfigに追加）
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    dark = true
    side-by-side = true

# 5. mise設定
mise use --global node@lts python@3.12 go@latest
```

### Step 3: Phase 2ツール導入（1週間以内）

1. atuin導入・Ctrl+R連携設定
2. btop, lazydocker導入
3. age導入 → chezmoi暗号化設定
4. Brewfile更新・chezmoi apply

### Step 4: 検証

```bash
# zsh起動速度
hyperfine 'zsh -i -c exit'

# chezmoi状態確認
chezmoi diff && chezmoi verify

# 全ツール動作確認
starship --version && zoxide --version && delta --version && mise --version && glow --version
```

---

## Brewfile 変更案

```ruby
# === 削除 ===
# brew "fish"              # 未使用
# brew "bash-completion@2" # zshメインなら不要
# brew "tree"              # eza --tree で代替済み

# === Phase 1 追加 ===
brew "starship"      # モダンプロンプト
brew "zoxide"        # スマートcd
brew "git-delta"     # Git diffハイライト
brew "glow"          # Markdownレンダラー
brew "mise"          # ランタイムバージョン管理

# === Phase 2 追加 ===
brew "atuin"         # シェル履歴管理
brew "btop"          # システムモニター
brew "lazydocker"    # Docker TUI
brew "yq"            # YAML/JSONプロセッサ
brew "age"           # ファイル暗号化

# === Phase 3 追加（任意）===
brew "hyperfine"     # ベンチマーク
brew "tokei"         # コード統計
brew "dust"          # ディスク使用量
brew "procs"         # プロセス表示
brew "just"          # タスクランナー
brew "difftastic"    # 構造的diff
brew "git-absorb"    # fixup自動化
```
