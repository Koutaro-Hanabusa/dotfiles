{ config, pkgs, username, isWork, ... }:

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

    # Git
    tig

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
  ];

  # 設定ファイルのシンボリックリンク（programs.<package> で管理できないもの）
  home.file = {
    # nb
    ".nbrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/nbrc";

    # Prettier
    ".prettierrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/prettierrc";

    # textlint
    ".textlintrc.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/textlintrc.json";
    ".textlintignore".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/textlintignore";
    ".textlint-rules".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/textlint-rules";

    # Neovim
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/nvim";

    # Karabiner
    ".config/karabiner".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/karabiner";

    # Keymap (Vial)
    ".config/keymap.vil".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/keymap.vil";

    # Claude Code
    ".claude".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude";

    # Claude Code MCP（user スコープとして読まれる ~/.mcp.json）
    ".mcp.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/mcp.json";

    # Codex CLI（個別ファイルのみ。~/.codex/ にはランタイムファイルがあるため丸ごと symlink しない）
    ".codex/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/codex/config.toml";
    ".codex/instructions.md".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/codex/instructions.md";

    # Claude OTel Monitoring
    ".config/claude-otel-monitoring".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude-otel-monitoring";

    # gh-dash（config.yml のみ管理。Nixストア経由で読み取り専用にし、ランタイム状態の書き戻しを防止）
    ".config/gh-dash/config.yml".source = ../home-manager/gh-dash/config.yml;
  };

  programs.home-manager.enable = true;
}
