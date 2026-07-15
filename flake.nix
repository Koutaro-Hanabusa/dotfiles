{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Claude Code CLI（Anthropic 公式の pre-built バイナリを毎時追随）
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    # DBML Language Server（自作 fork。ER 図プレビュー用 render サブコマンド入り）
    dbml-language-server = {
      url = "github:Koutaro-Hanabusa/dbml-language-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # DBML Renderer (softwaretechnik-berlin/dbml-renderer の fork。viz.js
    # ベースで自作 render より綺麗な SVG を吐く。日本語 ident 対応を追加)
    dbml-renderer = {
      url = "github:Koutaro-Hanabusa/dbml-renderer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, hunk, nix-claude-code, dbml-language-server, dbml-renderer, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        # claude はソース非公開なので unfree 明示許可（他パッケージには波及させない）
        config.allowUnfreePredicate =
          pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude" ];
        overlays = [
          nix-claude-code.overlays.default
          # Codex CLI（公式 pre-built バイナリのインライン overlay）
          (_final: prev: {
            codex-cli = prev.callPackage ./home-manager/codex-cli.nix { };
          })
        ];
      };
      mkHome =
        {
          username,
          isWork ? false,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit isWork username;
            hunkPkg = hunk.packages.${system}.default;
            dbmlLspPkg = dbml-language-server.packages.${system}.default;
            dbmlRendererPkg = dbml-renderer.packages.${system}.default;
          };
          modules = [ ./home-manager/home.nix ] ++ extraModules;
        };
    in
    {
      # `nix fmt` で Nix ファイルを整形（nixfmt = RFC 166 スタイル）
      formatter.${system} = pkgs.nixfmt;

      homeConfigurations."1126buri" = mkHome {
        username = "1126buri";
      };

      homeConfigurations."hanabusa.kotaro" = mkHome {
        username = "hanabusa.kotaro";
        isWork = true;
        extraModules = [ ./home-manager/work.nix ];
      };
    };
}
