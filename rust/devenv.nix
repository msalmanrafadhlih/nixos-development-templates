{ templateInputs }:
{ pkgs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
  fenix = templateInputs.fenix;
  toolchain = fenix.packages.${system}.combine [
    fenix.packages.${system}.stable.cargo
    fenix.packages.${system}.stable.rustc
    fenix.packages.${system}.stable.rust-src
    fenix.packages.${system}.stable.rust-analyzer
    fenix.packages.${system}.stable.clippy
    fenix.packages.${system}.stable.rustfmt
  ];
in {
  packages = [ toolchain ] ++ (with pkgs; [
    cargo-watch    # auto-rebuild saat file berubah
    cargo-edit   # cargo add/rm/upgrade
    cargo-audit   # audit depedency
    pkg-config
    openssl
  ]);

  # Tambahkan ini agar rust-analyzer bisa resolve stdlib
  env.RUST_SRC_PATH   = "${toolchain}/lib/rustlib/src/rust/library";
  env.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

  enterShell = ''
    echo "🦀 Rust Dev Shell (${pkgs.stdenv.hostPlatform.system})"
    echo ""
    rustc --version
    cargo --version
  '';
}
