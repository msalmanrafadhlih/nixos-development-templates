{
  description = "Nodejs Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default"; # ← default: support linux + darwin

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
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
  };

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

        # === ISI SEBELUM BUILD ===
        pname = "my-app"; # <-- samakan dengan "name" di package.json
        version = "0.1.0";

        # Hash didapat dengan menjalankan:
        # nix run nixpkgs#prefetch-npm-deps -- pnpm-lock.yaml
        # (pnpm-lock.yaml perlu di-convert dulu: pnpm import)
        # ATAU gunakan pnpmDepsHash (lihat packages.default di bawah)
        pnpmDepsHash = pkgs.lib.fakeHash; # <-- ganti dengan hash asli

      in
      {
        # devShell: untuk development sehari-hari
        # nix develop .#default --impure
        devShells = {
          default = inputs.devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [ ./devenv.nix ];
          };
        };

        # package: untuk build production dengan Nix
        # Menggunakan pnpm.fetchDeps karena devenv juga pakai pnpm
        # nix build .#<target>
        packages = {
          nextjs = pkgs.stdenv.mkDerivation (finalAttrs: {
            inherit pname version;
            src = ./.;

            pnpmDeps = pkgs.pnpm_9.fetchDeps {
              inherit (finalAttrs) pname version src;
              hash = pnpmDepsHash;
            };

            nativeBuildInputs = with pkgs; [
              nodejs_24
              pnpm_9.configHook # otomatis setup node_modules dari pnpmDeps
            ];

            buildPhase = ''
              runHook preBuild
              pnpm build
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/{bin,lib}
              cp -r .next $out/lib/
              cp -r public $out/lib/ 2>/dev/null || true
              cp package.json $out/lib/

              # Buat executable wrapper
              cat > $out/bin/${pname} << EOF
              #!/usr/bin/env bash
              cd $out/lib
              exec ${pkgs.nodejs_24}/bin/node_modules/.bin/next start "\$@"
              EOF
              chmod +x $out/bin/${pname}

              runHook postInstall
            '';
          });
        };
      }
    )
    // {
      devenvModules.default = import ./devenv.nix;
    };
}
