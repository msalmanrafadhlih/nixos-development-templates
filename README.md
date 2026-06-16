```
{
  description = "My Flutter App";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url  = "github:cachix/devenv";
    flexinix.url = "github:msalmanrafadhlih/flexinix";
  };

  outputs = { self, nixpkgs, devenv, flexinix, ... }:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        flexinix.devenvModules.flutter   # ← base dari flexinix

        # tambahan project-spesifik
        {
          packages = with pkgs; [
            git
            fzf
            ripgrep
            # tools lain khusus project ini
          ];

          enterShell = ''
            echo "My Flutter App - ready!"
          '';
        }
      ];
    };
  };
}

```
