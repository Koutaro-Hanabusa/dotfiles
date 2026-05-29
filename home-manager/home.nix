{ config, pkgs, username, ... }:

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
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  home.stateVersion = "25.11";

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

    # Development Languages / Runtimes
    go
    go-task

    # Network / Utilities
    curl
    nmap
    pandoc
    jq # claude/scripts・grafana-cloud skill 等のフック/スクリプトが依存
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

    # Karabiner
    ".config/karabiner".source = mkLink "karabiner";

    # Keymap (Vial)
    ".config/keymap.vil".source = mkLink "keymap.vil";

    # Claude Code
    ".claude".source = mkLink "claude";

    # Claude Code MCP（user スコープとして読まれる ~/.mcp.json）
    ".mcp.json".source = mkLink "mcp.json";

    # Codex CLI（個別ファイルのみ。~/.codex/ にはランタイムファイルがあるため丸ごと symlink しない）
    ".codex/config.toml".source = mkLink "codex/config.toml";
    ".codex/instructions.md".source = mkLink "codex/instructions.md";

    # Claude OTel Monitoring
    ".config/claude-otel-monitoring".source = mkLink "claude-otel-monitoring";

    # gh-dash（config.yml のみ管理。Nixストア経由で読み取り専用にし、ランタイム状態の書き戻しを防止）
    ".config/gh-dash/config.yml".source = ./gh-dash/config.yml;
  };

  programs.home-manager.enable = true;
}
