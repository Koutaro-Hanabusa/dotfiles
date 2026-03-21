{ config, pkgs, ... }:

{
  home.username = "1126buri";
  home.homeDirectory = "/Users/1126buri";

  home.stateVersion = "25.11";

  # CLIツール群（Nixで管理）
  home.packages = with pkgs; [
    # Editor / IDE
    neovim
    neovim-remote
    stylua

    # Shell / Terminal
    tmux
    # thefuck はNixpkgsから削除済み（python 3.12+非対応）→ Brewfileで管理

    # Git
    gh
    lazygit
    tig

    # Modern CLI Tools
    bat
    eza
    fd
    fzf
    ghq
    glow
    ripgrep
    zoxide

    # Development Languages / Runtimes
    go
    go-task

    # Network / Utilities
    curl
    nmap
    pandoc
  ];

  # 設定ファイルのシンボリックリンク（mkOutOfStoreSymlink で即時反映）
  home.file = {
    # Shell
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/zshrc";
    ".zshenv".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/zshenv";

    # tmux
    ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/tmux.conf";

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

    # Ghostty
    ".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/ghostty";

    # lazygit
    ".config/lazygit".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/lazygit";

    # Karabiner
    ".config/karabiner".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/karabiner";

    # Keymap (Vial)
    ".config/keymap.vil".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/keymap.vil";

    # Claude Code
    ".claude".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude";

    # Claude OTel Monitoring
    ".config/claude-otel-monitoring".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/claude-otel-monitoring";

    # gh-dash
    ".config/gh-dash".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/gh-dash";
  };

  home.sessionVariables = { };

  programs.home-manager.enable = true;
}
