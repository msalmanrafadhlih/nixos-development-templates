{
  description = "Flutter Template";
  outputs =
    { nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
      in
      {
        # nix develop .#default --inpure 
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            ./devenv.nix  
          ];
        };

        devenvModules.default = import ./devenv.nix {inherit pkgs inputs;};
      }
    );

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux"; # ← ditambahkan

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems"; # ← sekarang resolved
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        flake-compat.follows = "flake-compat";
        git-hooks.follows = "git-hooks";
      };
    };

    # ← ditambahkan: diperlukan oleh android-nixpkgs
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ← ditambahkan: diperlukan oleh devenv.nix
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        devshell.follows = "devshell";
        flake-utils.follows = "flake-utils";
      };
    };
  };
}
