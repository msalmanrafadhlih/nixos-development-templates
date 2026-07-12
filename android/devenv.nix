{ templateInputs }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.setupAndroid;

  useNixpkgs = cfg.backend == "devenv";

  # NDK version dipin eksplisit biar reproducible, dipakai di kedua backend
  ndkVersion = "26.1.10909125";
  ndkAttr = "ndk-${lib.replaceStrings [ "." ] [ "-" ] ndkVersion}";

  androidSdk = templateInputs.android-nixpkgs.sdk.${system} (
    sdkPkgs:
    with sdkPkgs;
    [
      cmdline-tools-latest
      platform-tools # adb, dipakai baik oleh emulator maupun device fisik via USB
      build-tools-35-0-0
      platforms-android-35
    ]
    ++ lib.optionals cfg.emulator [
      sdkPkgs.${ndkAttr}
      emulator
      system-images-android-34-google-apis-playstore-x86-64
    ]
  );

  # Paket android-udev-rules dari nixpkgs: aturan udev standar supaya
  # `adb`/`fastboot` bisa akses device Android via USB tanpa sudo.
  # PENTING: ini cuma bisa efektif kalau ter-install di /etc/udev/rules.d
  # (lewat NixOS module `services.udev.packages`), bukan cuma via devshell.
  udevRulesPkg = pkgs.android-udev-rules;

  udevWarning = ''
    echo ""
    echo "[setupAndroid] device = true — reminder buat akses USB tanpa sudo:"
    echo "  Devshell TIDAK BISA memasang udev rules system-wide."
    echo "  Tambahkan ini ke konfigurasi NixOS kamu (bukan devenv.nix ini):"
    echo ""
    echo "    services.udev.packages = [ pkgs.android-udev-rules ];"
    echo "    users.users.<username>.extraGroups = [ \"adbusers\" ];"
    echo ""
    echo "  Lalu rebuild switch & re-login. Cek dengan: adb devices"
    echo ""
  '';
in
{
  options.setupAndroid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable konfigurasi Android untuk template ini.
      '';
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "android-nixpkgs"
        "devenv"
      ];
      default = "devenv";
      description = ''
        Sumber Android SDK yang dipakai:
        - "android-nixpkgs": SDK deklaratif dari input flake tadfisher/android-nixpkgs.
        - "devenv": pakai modul `android` bawaan devenv (yang menarik dari nixpkgs).
      '';
    };

    emulator = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Apakah Android Emulator + system image diinstall. Berlaku untuk kedua backend.
      '';
    };

    device = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apakah dukungan adb/USB untuk physical device diaktifkan. platform-tools
        (adb) selalu ter-include terlepas dari opsi ini; opsi ini menambahkan
        paket udev rules (backend android-nixpkgs) dan reminder setup di enterShell.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Gradle butuh JDK
    languages.java.enable = lib.mkForce true;

    # === Backend: devenv (modul android bawaan devenv, sumbernya nixpkgs) ===
    android = lib.mkIf useNixpkgs {
      enable = true;
      platforms.version = [ "34" ];
      buildTools.version = [ "34.0.0" ];
      abis = [
        "arm64-v8a"
        "x86_64"
      ]; # sesuaikan kalau laptop kamu ARM
      systemImageTypes = [ "google_apis_playstore" ];
      ndk.enable = cfg.emulator;
      googleAPIs.enable = true;
      emulator.enable = cfg.emulator;
      # android-studio.enable = true; # aktifkan kalau mau install Android Studio juga
    };

    # === Backend: android-nixpkgs (SDK deklaratif dari flake input) ===
    packages =
      with pkgs;
      [ git ]
      ++ lib.optional (!useNixpkgs) androidSdk
      ++ lib.optional (cfg.device && !useNixpkgs) udevRulesPkg;

    enterShell = lib.mkIf cfg.device udevWarning;

    # env var: manual kalau pakai android-nixpkgs, karena modul `android` devenv
    # yang biasanya set otomatis, tidak aktif di backend ini.
    env = {
      SETUP_ANDROID = "Success!!";
    }
    // lib.optionalAttrs (!useNixpkgs) {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = config.env.ANDROID_HOME;
    }
    // lib.optionalAttrs (!useNixpkgs && cfg.emulator) {
      ANDROID_NDK_ROOT = "${config.env.ANDROID_HOME}/ndk/${ndkVersion}";
      NDK_HOME = config.env.ANDROID_NDK_ROOT;
      ANDROID_AVD_HOME = "${config.env.DEVENV_STATE}/android-avd";
    };
  };
}
