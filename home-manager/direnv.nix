{ ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    stdlib = ''
      # 一覧にある repo だけ、キャッシュのない Nix toolchain のビルドを避ける。
      # 一覧は社内 repo 名を公開しないため git 管理外（1 行 1 パス）。
      vite_plus_repos="''${XDG_CONFIG_HOME:-$HOME/.config}/direnv/vite-plus-repos"
      if [[ -f "$vite_plus_repos" ]] && grep -qxF "$(dirname "$(find_up .envrc)")" "$vite_plus_repos"; then
        use_flake() {
          local vp_bin="''${VP_HOME:-$HOME/.vite-plus}/bin" node_env
          if [[ ! -x "$vp_bin/vp" ]]; then
            log_error "個人用環境には Vite+ のグローバル CLI が必要です。"
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
          log_status "個人用 Vite+ 環境を使用（Nix devShell は読み込まない）"
        }
      fi
    '';
  };
}
