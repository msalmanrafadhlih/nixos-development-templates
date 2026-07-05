{ templateInputs }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  useNixpkgs = true;
  androidSdk = templateInputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      platform-tools
      build-tools-35-0-0
      platforms-android-35
      ndk-26-1-10909125 # versi NDK spesifik, bukan "latest" yang bisa berubah-ubah
      emulator
      system-images-android-34-google-apis-playstore-x86-64
    ]
  );
in
{

  languages.javascript = {
    enable = true;
    bun.enable = true;
  };

  # Gradle butuh JDK
  languages.java.enable = true;

  # === Android SDK/NDK/emulator, modul bawaan devenv ===
  android = {
    enable = useNixpkgs;
    platforms.version = [ "34" ];
    buildTools.version = [ "34.0.0" ];
    abis = [
      "arm64-v8a"
      "x86_64"
    ]; # sesuaikan kalau laptop kamu ARM
    systemImageTypes = [ "google_apis_playstore" ];
    ndk.enable = true;
    googleAPIs.enable = true;
    emulator.enable = true;
    # android-studio.enable = true; # aktifkan kalau mau install Android Studio juga
  };

  packages =
    with pkgs;
    [
      git
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
    ]
    ++ lib.optional (!useNixpkgs) androidSdk;

  # env var yang sebelumnya di-set otomatis oleh modul `android`,
  # sekarang harus manual karena kita pakai SDK dari input lain:
  env = {
    GREET = "Tauri + React + Tailwind (Bun) — Mobile Dev";
  }
  // lib.optionalAttrs (!useNixpkgs) {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/26.1.10909125";
  }
  // {
    ANDROID_SDK_ROOT = config.env.ANDROID_HOME;
    LD_LIBRARY_PATH = lib.makeLibraryPath (
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
  };

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
    echo "🦀⚛️  Tauri Mobile Dev Shell aktif"
    echo "bun       : $(bun --version)"
    echo "cargo     : $(cargo --version)"
    echo "adb       : $(adb --version 2>/dev/null | head -n1 || echo 'belum ada device/emulator')"
    echo ""
    echo "tauri-init    : bun create tauri-app@latest"
    echo "android-init  : bun run tauri android init"
    echo "android-dev   : bun run tauri android dev"
    echo "android-build : bun run tauri android build"
    echo "make-avd      : bikin emulator sekali saja"
    if [ ! -f package.json ]; then
      echo "Belum ada project di folder ini. Jalankan: tauri-init"
    fi
  '';
}
