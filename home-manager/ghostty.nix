{ config, pkgs, ... }:

{
  # Ghostty は macOS 向け Nix パッケージが未対応のため、
  # programs.ghostty は使わず home.file + mkOutOfStoreSymlink で管理
  home.file = {
    ".config/ghostty/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/ghostty/config";
    ".config/ghostty/tmux-auto.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home-manager/ghostty/tmux-auto.sh";
  };
}
