{
  # nix flake init -t github:msalmanrafadhlih/nixos-development-templates#<template>
  description = "Extended gihtub:nix-community/nix-templates with devenv and devshell supports";
  inputs.nix-templates.url = "github:the-nix-way/dev-templates";
  outputs = { nix-templates, ... }: {
    templates = import ./templates.nix { inherit nix-templates; };
  };
}
