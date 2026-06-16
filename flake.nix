{
  description = "Merge nix-templates with mine";
  outputs =
    { nix-templates, ... }@inputs:
    {
      # nix flake init -t github:msalmanrafadhlih/nixdev#<template>
      templates = import ./templates.nix { inherit nix-templates; };

      # nix develop github:msalmanrafadhlih/nixdev#<template> --impure
      devShells = import ./devShells.nix inputs;

      # inputs.nixdev.devenvModules.<template>
      devenvModules = import ./devenv.nix ;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
    nix-templates.url = "github:nix-community/templates";

    # Utilities
    flake-utils.url = "github:numtide/flake-utils"; # MultiSystem helper

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    }; # tool = Modular Flake

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    }; # tool = nonflake

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-lib";
        flake-compat.follows = "flake-compat";
      };
    };

    # development_tools
    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        flake-compat.follows = "flake-compat";
        git-hooks.follows = "git-hooks";
      };
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-lib";
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
