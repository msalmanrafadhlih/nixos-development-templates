{
  description = "Rust Learning Environment";

  inputs = {
    nixpkgs.follows = "root-flake/nixpkgs";
    flake-utils.follows = "root-flake/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    {
      nixpkgs,
      devenv,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            ({ pkgs, ... }: {
              packages = [
                pkgs.rustlings
              ];
            })
            ./devenv.nix
          ];
        };
      }
    );
}
