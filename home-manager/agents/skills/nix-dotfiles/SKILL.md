---
name: nix-dotfiles
description: この dotfiles リポジトリで Nix Home Manager の設定、管理ファイル、パッケージを追加・変更・適用するときに使う。一般的な Nix の質問だけには使わない。
allowed-tools:
  - Bash(home-manager switch *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git push*)
---

# Nix Dotfiles

`home-manager/` を設定の正本とし、aarch64-darwin の macOS 環境で編集前に既存の `.nix` 設定と対象ファイルの参照先を確認する。パッケージのみなら既存の `home.packages`、Home Manager が扱うツールなら既存の `programs.<package>`、設定ファイルなら既存の `home.file` と `mkOutOfStoreSymlink` を優先する。必要な場合にだけ新しいモジュールを作る。個人の常時指示を共有 `home-manager/agents/` に置かない。

`.nix` を変更したら、コミット前に `home-manager switch --flake ~/dotfiles` で適用を確認する。既存の out-of-store リンク先のファイルだけを編集した場合は、実際のリンク先と内容の反映を確認する。管理方法やリンク自体を変えた場合は switch で適用する。

変更後は `git diff --check` と `git status` を確認し、ユーザーが指定した到達点を優先する。指定がなければ、検証後に依頼した変更だけをステージ、コミット、プッシュする。認証情報、ランタイム状態、キャッシュ、未依頼の既存変更を含めない。switch や push が失敗した場合は完了とせず、原因と未適用・未送信の状態を伝える。
