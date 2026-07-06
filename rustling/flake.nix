{
  description = "Rust Learning Environment";

  inputs = {
    rust.url = "github:msalmanrafadhlih/nixos-development-templates/main?dir=rust";
    nixpkgs.follows = "rust/nixpkgs";
    flake-utils.follows = "rust/flake-utils";
    devenv.follows = "rust/devenv";
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
            ({ pkgs, ... }: {
              packages = [
                pkgs.rustlings
              ];
              # Contoh Scripts untuk mempermudah belajar
              scripts.hint.exec = "rustlings hint $1";
              scripts.watch.exec = "rustlings watch";

              # Menampilkan pesan saat masuk shell
              enterShell = ''
                echo "--- 📚 RUST LEARNING MODE ---"
                echo "Toolchain: $(rustc --version)"
                echo "Tersedia command: 'watch' untuk mulai, 'hint <no>' untuk bantuan."
              '';
            })
          ];
        };
      }
    );
}
