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

  # Gunakan false agar kita murni memakai deklaratif Android SDK dari flake inputs
  useNixpkgs = cfg.useNixpkgs;

  androidSdk = templateInputs.android-nixpkgs.sdk.${system} (
    sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      platform-tools
      build-tools-35-0-0
      platforms-android-35
    ] ++  lib.optional cfg.withEmulator [
      ndk-26-1-10909125 # versi NDK spesifik, bukan "latest" yang bisa berubah-ubah
      emulator
      system-images-android-34-google-apis-playstore-x86-64
    ]
  );
in
{
  options.setupAndroid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        enable android configurations for android template 
      '';
    };

    useNixpkgs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whenever to use android pkgs from nixpkgs or from devenv
      '';
    };

    withEmulator = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        whenever to use Emulator for android
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Gradle butuh JDK
    languages.java.enable = lib.mkForce true;

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
      [ git ]
      ++ lib.optional (!useNixpkgs) androidSdk;

    # env var yang sebelumnya di-set otomatis oleh modul `android`,
    # sekarang harus manual karena kita pakai SDK dari input lain:
    env = {
      SETUP_ANDROID = "Success!!";
    }
    // lib.optionalAttrs (!useNixpkgs) {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = config.env.ANDROID_HOME;

      ANDROID_NDK_ROOT = "${config.env.ANDROID_HOME}/ndk/26.1.10909125";
      NDK_HOME = config.env.ANDROID_NDK_ROOT;
    };
  };
}
