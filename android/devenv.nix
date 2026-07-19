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
      sdkPkgs.${ndkAttr}
      cmdline-tools-latest
      platform-tools # adb, dipakai baik oleh emulator maupun device fisik via USB
      build-tools-35-0-0
      build-tools-36-0-0
      platforms-android-35
      platforms-android-36
    ]
    ++ lib.optionals cfg.emulator [
      emulator
      system-images-android-34-google-apis-playstore-x86-64
    ]
  );

  # CATATAN: pkgs.android-udev-rules sudah DIHAPUS dari nixpkgs (digantikan oleh
  # systemd built-in "uaccess" tag). Sejak systemd 247+ / udev modern, device USB
  # termasuk Android otomatis dapat akses read/write untuk user aktif di seat
  # login (logind), tanpa perlu paket udev rules terpisah atau grup "adbusers".
  # Jadi TIDAK ADA package tambahan yang perlu di-install di system config kamu.
  # udevRulesPkg = pkgs.android-udev-rules;

  udevWarning = ''
    # echo ""
    # echo "[setupAndroid] device = true — akses USB Android:"
    # echo "  Sejak nixpkgs terbaru, udev rules Android sudah built-in via systemd"
    # echo "  uaccess tag — tidak perlu setup tambahan di system config."
    # echo "  Kalau 'adb devices' tetap kosong setelah HP dicolok:"
    # echo "    1. Pastikan USB debugging aktif di HP (Developer options)."
    # echo "    2. Cek popup 'Allow USB debugging?' di layar HP, tap Allow."
    # echo "    3. Coba: adb kill-server && adb start-server && adb devices"
    # echo ""
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
      platforms.version = [ "34" "35" "36" ];
      buildTools.version = [ "35.0.0" "36.0.0" ];
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
    packages = with pkgs; [ git ] ++ lib.optional (!useNixpkgs) androidSdk;

    enterShell = ''
      if command -v adb >/dev/null 2>&1; then
        echo "adb       : $(adb --version | grep "Android Debug Bridge" | awk '{print $5}')"
      else
        echo "adb       : belum terinstal (SDK Platform Tools)"
      fi
        echo "================================================"
        echo ""
      ${lib.optionalString cfg.device udevWarning}
    '';

    # env var: manual kalau pakai android-nixpkgs, karena modul `android` devenv
    # yang biasanya set otomatis, tidak aktif di backend ini.
    env = {
      SETUP_ANDROID = "Success!!";
    }
    // lib.optionalAttrs (!useNixpkgs) {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = config.env.ANDROID_HOME;
      ANDROID_NDK_ROOT = "${config.env.ANDROID_HOME}/ndk/${ndkVersion}";
      NDK_HOME = config.env.ANDROID_NDK_ROOT;
    }
    // lib.optionalAttrs (!useNixpkgs && cfg.emulator) {
      ANDROID_AVD_HOME = "${config.env.DEVENV_STATE}/android-avd";
    };
  };
}
