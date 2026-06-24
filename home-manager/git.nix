{ pkgs, ... }:

let
  # AI コミットメッセージ生成 + commit を一発で行う CLI。
  # lazygit を開いていなくても `gac` でターミナルから直接実行できる。
  gac = pkgs.writeShellScriptBin "gac" ''
    set -e

    if git diff --cached --quiet 2>/dev/null; then
      echo "❌ ステージ済みの変更がありません。先に git add してください。" >&2
      exit 1
    fi

    echo "🤖 AI がコミットメッセージを生成中..." >&2
    msg=$(claude -p --model haiku "以下のgit diffを見て、Conventional Commits形式のコミットメッセージを1行だけ生成してください。メッセージ本文のみを出力してください。形式: <type>(<scope>): <説明> typeは feat/fix/docs/style/refactor/test/chore/ci/perf/build のいずれか。scopeは変更されたパッケージ名(packages/やapps/配下のディレクトリ名)を使ってください。複数パッケージにまたがる場合は主要なものを1つ選んでください。ルート直下の設定ファイルのみの変更はscopeなしでOKです。日本語で書いてください。$(git diff --cached)" < /dev/null)

    if [ -z "$msg" ]; then
      echo "❌ メッセージ生成に失敗しました" >&2
      exit 1
    fi

    echo "📝 $msg" >&2
    git commit -m "$msg"
  '';
in
{
  # programs.git はスキップ（グローバル gitconfig なしの現状維持）

  home.packages = [ gac ];

  programs.lazygit = {
    enable = true;
    settings = {
      customCommands = [
        {
          key = "C";
          context = "files";
          description = "AI commit (Conventional Commits)";
          command = "gac";
          loadingText = "AIがコミットメッセージを生成中...";
          output = "popup";
        }
      ];
    };
  };

  programs.gh = {
    enable = true;
  };
}
