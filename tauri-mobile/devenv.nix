{ templateInputs }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  fenix = templateInputs.rust.inputs.fenix;
  rustToolChain = fenix.packages.${system}.combine [
    fenix.packages.${system}.targets.aarch64-linux-android.stable.rust-std
    fenix.packages.${system}.targets.x86_64-linux-android.stable.rust-std
    fenix.packages.${system}.targets.armv7-linux-androideabi.stable.rust-std
    fenix.packages.${system}.targets.i686-linux-android.stable.rust-std
  ];
in
{
  imports = [
    templateInputs.rust.devenvModules.default
    templateInputs.bun.devenvModules.default
    templateInputs.android.devenvModules.default
  ];

  setupAndroid = {
    enable = true;
    useNixpkgs = false;
    withEmulator = true;
  };

  packages = with pkgs; [
    rustToolChain
    git
    bun
    pkg-config
    openssl
    webkitgtk_4_1
    gtk3
    libsoup_3
    librsvg
    at-spi2-atk
    glib-networking

    gdk-pixbuf
    cairo
    dbus
  ];

  env.LD_LIBRARY_PATH = lib.makeLibraryPath (
    with pkgs;
    [
      webkitgtk_4_1
      gtk3
      libsoup_3
      librsvg
      at-spi2-atk
      glib
      openssl

      gdk-pixbuf
      cairo
      dbus
    ]
  );

  scripts = {
    tauri-init.exec = "bun create tauri-app@latest .";
    android-init.exec = "bun run tauri android init";
    android-dev.exec = "bun run tauri android dev";
    android-build.exec = "bun run tauri android build";
    make-avd.exec = ''
      avdmanager create avd --force \
        --name tauri-dev \
        --package 'system-images;android-34;google_apis_playstore;x86_64'
    '';
  };

  enterShell = ''
    _help() {
      echo "🦀⚛ Tauri Mobile Dev Shell Aktif"
      echo "bun       : $(bun --version 2>/dev/null || echo 'belum terinstal')"
      echo "cargo     : $(cargo --version 2>/dev/null | awk '{print $2}' || echo 'belum terinstal')"
      echo "rustc     : $(rustc --version 2>/dev/null | awk '{print $2}' || echo 'belum terinstal')"
      echo "target    : aarch64-linux-android, x86_64-linux-android siap!"

      if command -v adb >/dev/null 2>&1; then
        echo "adb       : $(adb --version | grep "Android Debug Bridge" | awk '{print $5}')"
      else
        echo "adb       : belum terinstal (SDK Platform Tools)"
      fi

      echo ""
      echo "Panduan Inisialisasi Cepat:"
      echo "  1. Jalankan inisialisasi Astro frontend terlebih dahulu."
      echo "  2. Jalankan: bun create tauri-app@latest"
      echo "  3. Jalankan: android-init  (setup android config)"
      echo "  4. Jalankan: make-avd      (bikin emulator AVD sekali saja)"
      echo "  5. Jalankan: android-dev   (run app di emulator)"

      if [ ! -f package.json ]; then
        echo ""
        echo "  Peringatan: Belum ada project di folder ini!"
        echo "   Silakan ikuti Panduan Inisialisasi Cepat di atas."
      fi
    }
    _help
  '';
}
