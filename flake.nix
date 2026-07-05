{
  description = "Merge nix-templates with mine";

  inputs = {
    nix-templates.url = "github:nix-community/templates";
  };

  outputs =
    { nix-templates, ... }: {
      # nix flake init -t github:msalmanrafadhlih/nixos-development-templates#<template>
      templates = import ./templates.nix { inherit nix-templates; };
    };

}
