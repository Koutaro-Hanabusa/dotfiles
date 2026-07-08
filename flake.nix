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
  };

  outputs =
    { nixpkgs, home-manager, hunk, nix-claude-code, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        # claude はソース非公開なので unfree 明示許可（他パッケージには波及させない）
        config.allowUnfreePredicate =
          pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude" ];
        overlays = [ nix-claude-code.overlays.default ];
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
