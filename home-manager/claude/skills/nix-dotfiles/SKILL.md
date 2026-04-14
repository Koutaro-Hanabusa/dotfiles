---
name: nix-dotfiles
description: >
  Nix Home Manager による dotfiles 管理スキル。設定ファイルの追加・編集・モジュール作成・パッケージ管理の
  手順とパターンを提供する。dotfiles リポジトリ内のファイル編集時に自動で適用・コミット・プッシュを行う。
  トリガー: dotfiles リポジトリ内でファイルを編集したとき、Nix/Home Manager に関する質問を受けたとき、
  新しいツールや設定を追加したいとき。
allowed-tools:
  - Bash(home-manager switch *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git push*)
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"nix-dotfiles"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

このスキルは `~/dotfiles` リポジトリを Nix Home Manager で管理するためのガイドラインを提供する。

## アーキテクチャ

```
~/dotfiles/
├── flake.nix                    # Flake定義（nixpkgs-unstable + home-manager）
├── flake.lock                   # 入力ロック
└── home-manager/
    ├── home.nix                 # メイン（imports, home.packages, home.file）
    ├── zsh.nix                  # programs.zsh
    ├── git.nix                  # programs.lazygit, programs.gh
    ├── cli-tools.nix            # programs.bat, eza, fzf, zoxide, ripgrep
    ├── ghostty.nix              # Ghostty（home.file のみ）
    ├── nvim/                    # Neovim設定ディレクトリ
    ├── claude/                  # Claude Code設定
    ├── karabiner/               # Karabiner設定
    └── ...                      # その他の設定ファイル
```

## 適用ワークフロー

dotfiles リポジトリ内のファイルを編集したら、**必ず以下の順で実行する**:

```bash
# 1. ビルド・適用
home-manager switch --flake ~/dotfiles

# 2. コミット・プッシュ
cd ~/dotfiles && git add <changed-files> && git commit -m "message" && git push
```

**重要**: `mkOutOfStoreSymlink` で管理されているファイル（nvim, claude, karabiner 等）は、
ファイル編集が即座に反映されるため `home-manager switch` は不要。
ただし `.nix` ファイルを変更した場合は必ず `home-manager switch` を実行すること。

## パターン別ガイド

### 1. 新しいパッケージを追加する

設定ファイルが不要なツールは `home.nix` の `home.packages` に追加:

```nix
# home-manager/home.nix
home.packages = with pkgs; [
  # 既存パッケージ...
  新しいパッケージ名
];
```

### 2. programs.\<package\> でツールを管理する

パッケージと設定を一体管理する場合。既存モジュールに追加するか、新規 `.nix` を作成:

```nix
# 既存モジュール（例: cli-tools.nix）に追加
programs.新しいツール = {
  enable = true;
  # 設定オプション...
};
```

### 3. 設定ファイルをシンボリックリンクで管理する

`programs.<package>` に対応がないツールの設定ファイルは `home.file` + `mkOutOfStoreSymlink`:

```nix
# home-manager/home.nix の home.file に追加
"配置先パス".source = config.lib.file.mkOutOfStoreSymlink
  "${config.home.homeDirectory}/dotfiles/home-manager/設定ファイル";
```

- `mkOutOfStoreSymlink` は Nix ストア外へのシンボリックリンクを作成する
- ファイル編集が即座に反映される（`home-manager switch` 不要）
- ディレクトリ丸ごとリンクも可能

### 4. 新しい Nix モジュールを作成する

大きな設定は独立した `.nix` ファイルに分離:

```nix
# home-manager/新しいモジュール.nix
{ config, pkgs, ... }:
{
  programs.ツール名 = {
    enable = true;
    # 設定...
  };
}
```

`home.nix` の imports に追加:

```nix
imports = [
  ./zsh.nix
  # ...
  ./新しいモジュール.nix
];
```

### 5. Flake の入力を更新する

```bash
cd ~/dotfiles && nix flake update
home-manager switch --flake ~/dotfiles
```

## 判断基準

| やりたいこと | 方法 |
|-------------|------|
| CLI ツールを入れるだけ | `home.packages` に追加 |
| ツール + 設定を一体管理 | `programs.<package>` |
| 設定ファイルだけリンク | `home.file` + `mkOutOfStoreSymlink` |
| 大きな設定グループ | 新規 `.nix` モジュール作成 |

## 注意事項

- **システム**: aarch64-darwin (Apple Silicon Mac)
- **Nix チャネル**: nixpkgs-unstable
- macOS で Nix パッケージ未対応のアプリ（Ghostty 等）は `home.file` でシンボリックリンクのみ管理
- `.nix` ファイルの構文エラーは `home-manager switch` 時にビルドエラーとして検出される
- ビルドエラーが発生したらエラーメッセージを確認し、修正してから再度 `home-manager switch` を実行
