{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
lib.genAttrs lib.systems.flakeExposed (
  system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
      };
    };
  in
  {

    # Default : nix develop github:msalmanrafadhlih/nixdev#default --impure
    default = inputs.devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        {
          languages.nix.enable = true;
          packages = with pkgs; [
            devenv
            cargo
          ];
        }
      ];
    };

    # nodejs : nix develop github:msalmanrafadhlih/flexinix#nodejs --impure
    nodejs = inputs.devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        ./nodejs/devenv.nix
      ];
    };
  }
)
