{
  description = "Bun Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default"; # ← support linux + darwin

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
            allowUnfree = true;
          };
        };

        # === ISI SEBELUM BUILD ===
        pname = "my-app"; # <-- samakan dengan "name" di package.json
        version = "0.1.0";

        # Hash untuk dependencies bun.
        # Cara mendapatkan hash yang benar (lakukan setelah `bun install` di dev):
        # 1. Pastikan file `bun.lock` sudah ada dan ter-commit ke git
        # 2. Biarkan nilai di bawah tetap `pkgs.lib.fakeHash`
        # 3. Jalankan: nix build .#nextjs 2>&1 | grep "got:"
        # 4. Copy hash yang muncul, ganti `pkgs.lib.fakeHash` di bawah
        # Contoh hasil: "got:    sha256-xxxxx..."  → pakai bagian "sha256-xxxxx..."
        bunDepsHash = pkgs.lib.fakeHash;

        # Derivasi khusus untuk fetch dependencies bun.
        # Fixed-output derivation = boleh akses internet saat build.
        # Nix akan meng-cache hasilnya, jadi hanya fetch sekali selama hash tidak berubah.
        bunDeps = pkgs.stdenv.mkDerivation {
          name = "${pname}-${version}-bun-deps";
          src = ./.;

          nativeBuildInputs = [
            pkgs.bun
            pkgs.cacert # SSL certificate untuk koneksi HTTPS
          ];

          # Fixed-output derivation: izinkan akses jaringan, tapi hash output harus cocok
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = bunDepsHash;

          buildPhase = ''
            export HOME=$TMPDIR
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache

            # --frozen-lockfile: pastikan bun.lock tidak berubah (reproducible build)
            # --no-progress: output lebih bersih di log nix
            bun install --frozen-lockfile --no-progress
          '';

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/
          '';
        };

      in
      {
        # devShell: untuk development sehari-hari
        # Cara pakai: nix develop --impure
        devShells = {
          default = inputs.devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              (import ./devenv.nix { templateInputs = inputs; })
            ];
          };
        };

        # packages: untuk build production dengan Nix (reproducible)
        # Cara pakai: nix build .#nextjs
        # Hasil build ada di: ./result/bin/my-app dan ./result/lib/
        packages = {
          nextjs = pkgs.stdenv.mkDerivation (finalAttrs: {
            inherit pname version;
            src = ./.;

            nativeBuildInputs = [ pkgs.bun ];

            buildPhase = ''
              runHook preBuild

              # Salin node_modules dari derivasi bunDeps yang sudah di-fetch
              cp -r ${bunDeps}/node_modules .
              chmod -R u+w node_modules # pastikan writable

              # Build Next.js (akan menghasilkan folder .next/)
              bun run build

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/{bin,lib}

              # Salin hasil build Next.js
              cp -r .next $out/lib/
              cp -r public $out/lib/ 2>/dev/null || true # opsional, boleh tidak ada
              cp package.json $out/lib/

              # Salin node_modules agar server bisa berjalan
              cp -r node_modules $out/lib/

              # Buat executable wrapper script
              # Script ini yang dipanggil saat kamu menjalankan hasil build
              cat > $out/bin/${pname} << 'WRAPPER'
              #!/usr/bin/env bash
              exec ${pkgs.bun}/bin/bun --cwd "$out/lib" run start "$@"
              WRAPPER
              chmod +x $out/bin/${pname}

              runHook postInstall
            '';

            meta = {
              description = "Next.js app built with Bun";
              mainProgram = pname;
            };
          });
        };
      }
    )
    // {
      devenvModules.default = import ./devenv.nix { templateInputs = inputs; };
    };
}
