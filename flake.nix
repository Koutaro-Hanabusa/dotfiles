{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHome =
        {
          username,
          isWork ? false,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit isWork username; };
          modules = [ ./home-manager/home.nix ] ++ extraModules;
        };
    in
    {
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
