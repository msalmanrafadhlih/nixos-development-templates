{
  description = "Rust Learning Environment";

  inputs = {
    nixpkgs.follows = "root-flake/nixpkgs";
    flake-utils.follows = "root-flake/flake-utils";
    rust = "github:msalmanrafadhlih/nixos-development-templates/main?dir=rust";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            inputs.rust.devenvModules.default
            (import ./devenv.nix { templateInputs = inputs; })
            ({ pkgs, ... }: {
              packages = [
                pkgs.rustlings
              ];
            })
          ];
        };
      }
    );
}
