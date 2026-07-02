{ templateInputs }:
{ pkgs, ... }:
let
  # Latest Flutter (3.29+) butuh:
  # - platforms-android-35 (Android 15)
  # - build-tools-35-0-0
  # - JDK 17 minimum, 21 direkomendasikan
  androidSdk = templateInputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      platform-tools
      platforms-android-35 # ← update dari 33
      build-tools-35-0-0 # ← update dari 30.0.3
      # emulator             # uncomment jika butuh emulator
    ]
  );

  androidSdkSubPath = "share/android-sdk";
in
{
  packages = with pkgs; [
    androidSdk
    flutter
    # androidStudioPackages.stable  # uncomment jika butuh Android Studio
  ];

  languages.java = {
    enable = true; # otomatis set JAVA_HOME
    jdk.package = pkgs.jdk21; # ← update ke 21 (direkomendasikan Flutter 3.29+)
  };

  env = rec {
    ANDROID_HOME     = "${androidSdk}/${androidSdkSubPath}";
    ANDROID_SDK_ROOT = ANDROID_HOME; # deprecated tapi masih dipakai beberapa tools
  };

  enterShell = ''
    echo ""
    echo "================================================================"
    echo "  Flutter Development Environment"
    echo "================================================================"
    echo "  Flutter  : $(flutter --version 2>/dev/null | head -1 || echo 'not ready')"
    echo "  Java     : $(java -version 2>&1 | head -1)"
    echo "  Android  : $ANDROID_HOME"
    echo "================================================================"
    echo ""
    echo "  SDK paths (untuk Android Studio — tidak baca env vars):"
    echo "  android  : $(pwd)/.devenv/profile/${androidSdkSubPath}"
    echo "  flutter  : $(pwd)/.devenv/profile"
    echo "  java     : $(pwd)/.devenv/profile/lib/openjdk"
    echo ""
    echo "  Jalankan 'flutter doctor' untuk cek setup."
    echo ""
    echo "  Catatan: jika muncul error gradlew, hapus file android/gradlew"
    echo "  lalu jalankan ulang 'flutter build'"
    echo "================================================================"
    echo ""
  '';
}
