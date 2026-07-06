{
  description = "Tauri + React + Tailwind (Bun) — Mobile Dev Template";

  inputs = {
    systems.url = "github:nix-systems/default";
    crane-tauri.url = "github:JPHutchins/crane-tauri";

    rust.url = "github:msalmanrafadhlih/nixos-development-templates/main?dir=rust";
    bun.url = "github:msalmanrafadhlih/nixos-development-templates/main?dir=bun";
    android.url = "github:msalmanrafadhlih/nixos-development-templates/main?dir=android";

    flake-utils = {
      follows = "rust/flake-utils";
      inputs.systems.follows = "systems";
    };

    nixpkgs.follows = "rust/nixpkgs";
    devenv.follows = "rust/devenv";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      crane-tauri,
      ...
    }@inputs:
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
        inherit (pkgs) lib;
        crane = inputs.rust.inputs.crane;
        craneLib = crane.mkLib pkgs;

        frontend =
          let
            nodeModules = pkgs.stdenvNoCC.mkDerivation {
              pname = "my-app-frontend-deps";
              version = "0.1.0";
              src = lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.unions [
                  ./package.json
                  ./bun.lock
                ];
              };
              nativeBuildInputs = [ pkgs.bun ];
              dontConfigure = true;
              buildPhase = ''
                export HOME=$TMPDIR
                bun install --frozen-lockfile --no-progress
              '';
              installPhase = "mkdir -p $out: cp -r node_modules $out/";
              outputHasMode = "recursive";
              outputHashAlgo = "sha256";
              outputHash = lib.fakeHash; # change to the real one after `nix build`
            };
          in
          pkgs.stdenvNoCC.mkDerivation {
            pname = "my-app-frontend";
            version = "0.1.0";
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./package.json
                ./bun.lock
                ./tsconfig.json
                ./astro.config.mjs
                ./index.html
                ./public
                ./src
              ];
            };
            nativeBuildInputs = [ pkgs.bun ];
            dontConfigure = true;
            buildPhase = ''
              export HOME=$TMPDIR
              cp -r ${nodeModules}/node_modules .
              chmod -R u+w node_modules
              bun run build
            '';
            installPhase = "cp -r dist $out";
          };

        tauri = crane-tauri.lib.buildTauriApp { inherit pkgs craneLib; } {
          pname = "my-app";
          version = "0.1.0";
          src = ./.;
          # cargoRoot = ./.; # if `src-tauri/Cargo.toml` depends on sibling creates by relative path
          inherit frontend;
        };
      in
      {
        packages.default = tauri.app;
        checks = {
          inherit (tauri) app;

          clippy = craneLib.cargoClippy (
            tauri.commonArgs
            // {
              cargoArtifacts = tauri.cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- -D warnings";
              TAURI_CONFIG = tauri.tauriConfig;
            }
          );
        };

        devShells = {
          default = inputs.devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              (import ./devenv.nix { templateInputs = inputs; })
            ];
          };
        };
      }
    )
    // {
      devenvModules.default = import ./devenv.nix { templateInputs = inputs; };
    };
}
