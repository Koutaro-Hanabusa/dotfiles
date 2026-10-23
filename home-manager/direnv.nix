{ ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    stdlib = ''
      # Cheese の通常 checkout だけ、キャッシュのない Nix toolchain のビルドを避ける。
      if [[ "$(find_up .envrc)" == "$HOME/sen/8122-cheese/.envrc" ]]; then
        use_flake() {
          local vp_bin="''${VP_HOME:-$HOME/.vite-plus}/bin" node_env
          if [[ ! -x "$vp_bin/vp" ]]; then
            log_error "Cheese の個人用環境には Vite+ のグローバル CLI が必要です。"
            return 1
          fi
          watch_file .node-version package.json pnpm-lock.yaml
          PATH_add "$PWD/node_modules/.bin"
          PATH_add "$vp_bin"
          "$vp_bin/vp" env install || return 1
          node_env="$("$vp_bin/vp" env print)" || return 1
          eval "$node_env"

          if [[ ! -f node_modules/.pnpm/lock.yaml || pnpm-lock.yaml -nt node_modules/.pnpm/lock.yaml ]]; then
            "$vp_bin/vp" install --frozen-lockfile || return 1
          fi
          log_status "Cheese: 個人用 Vite+ 環境を使用（Nix devShell は読み込まない）"
        }
      fi
    '';
  };
}
