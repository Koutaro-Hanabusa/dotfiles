# dotfiles

chezmoiで管理しているdotfiles

## セットアップ

```bash
# chezmoiをインストール
brew install chezmoi

# dotfilesを適用
chezmoi init --apply Koutaro-Hanabusa
```

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

### コマンド

| コマンド | 動作 |
|----------|------|
| `vim` | nvim + Claude Code 起動 |
| `code` | nvim + Claude Code 起動 |
| `nvc` | 同上 |
| `nvim-raw` | 純粋なnvimのみ起動 |

### 終了方法

nvimで`:q`すればtmuxセッションごと終了する。

### tmux操作

prefixキーは `Ctrl+a`

| キー | 動作 |
|------|------|
| `Ctrl+a` `h` | 左ペインへ移動 |
| `Ctrl+a` `l` | 右ペインへ移動 |
| `Ctrl+a` `j` | 下ペインへ移動 |
| `Ctrl+a` `k` | 上ペインへ移動 |
| `Ctrl+a` `H/J/K/L` | ペインリサイズ |
| `Ctrl+a` `\|` | 縦分割 |
| `Ctrl+a` `-` | 横分割 |
| `Ctrl+a` `d` | デタッチ（セッション維持） |
| `tmux attach` | セッションに再接続 |
| マウス | ペイン選択・リサイズ可 |

## 含まれる設定

- `.zshrc` - シェル設定
- `.tmux.conf` - tmux設定
- `.config/nvim/` - Neovim設定
- `.config/ghostty/` - Ghostty設定
- `.config/karabiner/` - Karabiner設定
