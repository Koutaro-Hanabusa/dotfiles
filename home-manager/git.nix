{ pkgs, herdrPkg, ... }:

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
    msg=$(claude -p --model haiku "以下のgit diffを見て、Conventional Commits形式の変更のWHYを記載したコミットメッセージを1行だけ生成してください。メッセージ本文のみを出力してください。形式: <type>(<scope>): <説明> typeは feat/fix/docs/style/refactor/test/chore/ci/perf/build のいずれか。scopeは変更されたパッケージ名(packages/やapps/配下のディレクトリ名)を使ってください。複数パッケージにまたがる場合は主要なものを1つ選んでください。ルート直下の設定ファイルのみの変更はscopeなしでOKです。日本語で書いてください。$(git diff --cached)" < /dev/null)

    if [ -z "$msg" ]; then
      echo "❌ メッセージ生成に失敗しました" >&2
      exit 1
    fi

    echo "📝 $msg" >&2
    git commit -m "$msg"
  '';

  # herdr のカスタムコマンド（prefix+shift+g の popup）から呼ばれる。
  # リポジトリ内 <repo>/.worktrees/<branch> に git worktree を作成し、
  # herdr ワークスペースとして開く（herdr 組み込みの worktrees.directory 方式ではなく
  # リポジトリ内に置きたいので --path で明示する）。
  herdr-worktree-new = pkgs.writeShellScriptBin "herdr-worktree-new" ''
    set -eu

    cwd="''${HERDR_ACTIVE_PANE_CWD:-$PWD}"
    if ! root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
      echo "❌ git リポジトリではありません: $cwd" >&2
      read -r _
      exit 1
    fi

    printf "🌱 ブランチ名（既存なら checkout、なければ作成）: "
    read -r branch
    [ -n "$branch" ] || exit 0

    # ブランチ名の "/" はディレクトリ名として安全な "-" に置換
    slug=$(printf %s "$branch" | tr '/' '-')

    # .worktrees/ を各リポジトリの .git/info/exclude で無視する
    # （グローバル gitconfig なし方針のため、リポジトリローカルに追記する）
    exclude=$(git -C "$root" rev-parse --git-path info/exclude)
    if ! grep -qxF ".worktrees/" "$exclude" 2>/dev/null; then
      echo ".worktrees/" >> "$exclude"
    fi

    herdr worktree create --cwd "$cwd" --branch "$branch" \
      --path "$root/.worktrees/$slug" --focus
  '';

  # zsh の precmd から非同期で呼び、現在ブランチの open PR を Herdr の
  # workspace metadata に反映する。通信失敗時は既存表示を維持する。
  herdr-pr-metadata = pkgs.writeShellScriptBin "herdr-pr-metadata" ''
    set -u

    workspace_id="''${HERDR_WORKSPACE_ID:-}"
    [ -n "$workspace_id" ] || exit 0

    root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null) || exit 0
    branch=$(${pkgs.git}/bin/git -C "$root" branch --show-current 2>/dev/null) || exit 0

    if [ -z "$branch" ]; then
      ${herdrPkg}/bin/herdr workspace report-metadata "$workspace_id" \
        --source dotfiles:pr-metadata --clear-token pr >/dev/null 2>&1 || true
      exit 0
    fi

    state_dir="''${TMPDIR:-/tmp}/herdr-pr-metadata"
    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
    workspace_slug=$(printf '%s' "$workspace_id" | ${pkgs.coreutils}/bin/tr -c 'A-Za-z0-9._-' '_')
    cache="$state_dir/$workspace_slug"
    lock="$cache.lock"

    ${pkgs.coreutils}/bin/mkdir "$lock" 2>/dev/null || exit 0
    trap '${pkgs.coreutils}/bin/rmdir "$lock" 2>/dev/null || true' EXIT

    cached_root=
    cached_branch=
    if [ -f "$cache" ]; then
      {
        IFS= read -r cached_root || true
        IFS= read -r cached_branch || true
      } < "$cache"
    fi
    fresh=$(${pkgs.findutils}/bin/find "$cache" -mmin -1 -print -quit 2>/dev/null || true)
    if [ "$cached_root" = "$root" ] && [ "$cached_branch" = "$branch" ] && [ -n "$fresh" ]; then
      exit 0
    fi

    if ! pr_json=$(
      cd "$root" &&
        ${pkgs.gh}/bin/gh pr list --head "$branch" --state open --limit 1 \
          --json number,url 2>/dev/null
    ); then
      exit 0
    fi

    current_branch=$(${pkgs.git}/bin/git -C "$root" branch --show-current 2>/dev/null) || exit 0
    [ "$current_branch" = "$branch" ] || exit 0

    pr_number=$(printf '%s' "$pr_json" | ${pkgs.jq}/bin/jq -r '.[0].number // empty')
    if [ -n "$pr_number" ]; then
      ${herdrPkg}/bin/herdr workspace report-metadata "$workspace_id" \
        --source dotfiles:pr-metadata --token "pr=PR #$pr_number" >/dev/null 2>&1 || exit 0
    else
      ${herdrPkg}/bin/herdr workspace report-metadata "$workspace_id" \
        --source dotfiles:pr-metadata --clear-token pr >/dev/null 2>&1 || exit 0
    fi

    printf '%s\n%s\n' "$root" "$branch" > "$cache"
  '';
in
{
  # programs.git はスキップ（グローバル gitconfig なしの現状維持）

  home.packages = [
    gac
    herdr-worktree-new
    herdr-pr-metadata
  ];

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
