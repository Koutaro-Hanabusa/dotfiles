{ config, pkgs, lib, username, isWork, hunkPkg, dbmlLspPkg, dbmlRendererPkg, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles/home-manager";
  # ~/dotfiles/home-manager/<rel> への out-of-store symlink を作る（編集が即時反映される）
  mkLink = rel: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${rel}";
in
{
  imports = [
    ./zsh.nix
    ./git.nix
    ./cli-tools.nix
    ./ghostty.nix
    ./direnv.nix
    ./karabiner.nix
    ./macskk.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  home.stateVersion = "25.11";

  # nixpkgs の mermaid-cli は puppeteer で Chrome を起動するが、Chromium を
  # 同梱していないため実行時に「Could not find Chrome」で落ちる。
  # macOS 側にインストール済みの Google Chrome を puppeteer に教える。
  home.sessionVariables = {
    PUPPETEER_EXECUTABLE_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
  };

  # CLIツール群（programs.<package> で管理しないもののみ）
  home.packages = with pkgs; [
    # Editor / IDE
    neovim
    neovim-remote
    stylua

    # Modern CLI Tools
    fd
    ghq
    glow
    hunkPkg

    # Development Languages / Runtimes
    go
    go-task

    # Network / Utilities
    curl
    nmap
    pandoc
    jq # claude/scripts・grafana-cloud skill 等のフック/スクリプトが依存

    # AI CLI
    # Anthropic 公式の pre-built バイナリ（overlay は flake.nix で適用）。
    # 実行本体は zsh.nix の claude() ラッパー経由で --mcp-config を注入する。
    claude-code
    # OpenAI Codex CLI（./codex-cli.nix の inline overlay）。
    # vp shim (~/.vite-plus/bin/codex) が PATH で先勝ちするため、
    # zsh.nix の codex() ラッパーで Nix ストア実体を直接叩く。
    codex-cli
    # Herdr（Agent multiplexer）。config は home-manager/herdr/config.toml で管理済み。
    # zsh.nix の _open_herdr_editor_split が `command -v herdr` で存在チェックしてから使う。
    herdr

    # DBML Language Server（自作 fork。バイナリは graphviz を PATH 注入済み wrap）。
    # nvim では ftplugin/dbml.lua で LSP 起動。
    dbmlLspPkg

    # DBML Renderer (自作 fork。viz.js ベースで自作 render より見栄えの良い
    # SVG を生成。日本語 ident 対応済み)。ftplugin/dbml.lua の :Er で使用。
    dbmlRendererPkg

    # Mermaid CLI (mmdc)。nvim の diagram.nvim が markdown 内 mermaid ブロックを
    # レンダするために PATH に必要。
    mermaid-cli

    # tree-sitter CLI。nvim-treesitter main ブランチが parser を install/compile
    # する際に必須。diagram.nvim は markdown parser で code block を検出するので
    # これが無いと mermaid ブロックが認識されない。
    tree-sitter
  ];

  # 設定ファイルのシンボリックリンク（programs.<package> で管理できないもの）
  home.file = {
    # nb
    ".nbrc".source = mkLink "nbrc";

    # Prettier
    ".prettierrc".source = mkLink "prettierrc";

    # textlint
    ".textlintrc.json".source = mkLink "textlintrc.json";
    ".textlintignore".source = mkLink "textlintignore";
    ".textlint-rules".source = mkLink "textlint-rules";

    # Neovim
    ".config/nvim".source = mkLink "nvim";

    # Karabiner: karabiner.json は ./karabiner.nix で Nix から生成

    # Keymap (Vial)
    ".config/keymap.vil".source = mkLink "keymap.vil";

    # Claude Code
    ".claude".source = mkLink "claude";

    # Claude Code MCP のサーバー定義（source of truth）。
    # 注意: ~/.mcp.json は **project スコープ**で、CWD がホームのときだけ拾われる。
    # 全プロジェクトで効く user スコープは ~/.claude.json の top-level mcpServers
    # （Nix 管理外の可変ファイル）に登録する必要がある。新マシンや mcp.json 更新時は
    # 下記を再実行して user スコープへ反映する:
    #   cd ~ && for name in $(jq -r '.mcpServers | keys[]' ~/dotfiles/home-manager/mcp.json); do
    #     claude mcp add-json -s user "$name" "$(jq -c ".mcpServers[\"$name\"]" ~/dotfiles/home-manager/mcp.json)"
    #   done
    ".mcp.json".source = mkLink "mcp.json";

    # Codex CLI（個別ファイルのみ。~/.codex/ にはランタイムファイルがあるため丸ごと symlink しない）
    ".codex/config.toml".source = mkLink "codex/config.toml";
    ".codex/hooks.json".source = mkLink "codex/hooks.json";
    ".codex/hooks".source = mkLink "codex/hooks";
    ".codex/instructions.md".source = mkLink "codex/instructions.md";

    # Herdr（config.toml のみ管理。~/.config/herdr/ にはログ・ソケット等のランタイムファイルがあるため丸ごと symlink しない）
    ".config/herdr/config.toml".source = mkLink "herdr/config.toml";

    # Claude OTel Monitoring
    ".config/claude-otel-monitoring".source = mkLink "claude-otel-monitoring";

    # gh-dash（config.yml のみ管理。Nixストア経由で読み取り専用にし、ランタイム状態の書き戻しを防止）
    ".config/gh-dash/config.yml".source = ./gh-dash/config.yml;
  };

  programs.home-manager.enable = true;

  # Hunk の SKILL.md を Claude Code のスキルとして参照可能にする。
  # `.claude` は mkLink で out-of-store symlink なので、その配下は dotfiles ツリー側に
  # 実体を置く必要がある。activation で Nix ストア内の skill を指すシンボリックリンクを
  # 貼り直し、hunk のバージョンアップに追従する。gitignore 済み。
  home.activation.linkHunkSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/dotfiles/home-manager/claude/skills"
    run ln -sfn "${hunkPkg}/skills/hunk-review" \
      "$HOME/dotfiles/home-manager/claude/skills/hunk-review"
  '';
}
