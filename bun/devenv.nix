{ templateInputs }:
{ pkgs, ... }:

{

  # Bun adalah all-in-one toolkit:
  # ✓ Runtime JavaScript/TypeScript (seperti Node.js, tanpa perlu transpiler)
  # ✓ Package manager (pengganti npm / pnpm / yarn)
  # ✓ Bundler (pengganti webpack / esbuild / rollup)
  # ✓ Test runner (pengganti Jest / Vitest)
  # ✓ Bisa langsung jalankan file .ts tanpa konfigurasi apapun
  languages.javascript = {
    enable = true;
    nodejs.enable = true;
  };

  packages = with pkgs; [
    git
    bun
  ];

  enterShell = ''
    echo ""
    echo "================================================================"
    echo "   SELAMAT DATANG DI LINGKUNGAN PENGEMBANGAN BUN"
    echo "================================================================"
    echo "  Bun  : $(bun --version)"
    echo "  Node : $(node --version)"
    echo "  Git  : $(git --version | cut -d' ' -f3)"
    echo "================================================================"
    echo ""
    echo "  [ MULAI PROYEK BARU ]"
    echo "    bunx create-next-app@latest .   - buat proyek Next.js"
    echo "    bunx create-astro@latest .      - buat proyek Astro"
    echo "    bun init                        - buat proyek kosong"
    echo ""
    echo "  [ PACKAGE MANAGER ]"
    echo "    bun install              - install semua deps dari package.json"
    echo "    bun add <nama>           - tambah package baru"
    echo "    bun add -d <nama>        - tambah package sebagai devDependency"
    echo "    bun remove <nama>        - hapus package"
    echo "    bun update               - update semua package ke versi terbaru"
    echo "    bun update <nama>        - update satu package saja"
    echo "    bun pm ls                - lihat daftar package yang terinstall"
    echo ""
    echo "  [ MENJALANKAN PROYEK ]"
    echo "    bun dev                  - jalankan dev server (hot reload otomatis)"
    echo "    bun build                - build untuk production"
    echo "    bun start                - jalankan production server"
    echo "    bun run <nama-script>    - jalankan script dari package.json"
    echo "    bun run <file.ts>        - jalankan file TypeScript langsung"
    echo ""
    echo "  [ TESTING ]"
    echo "    bun test                 - jalankan semua file *.test.ts"
    echo "    bun test <file>          - jalankan file test tertentu"
    echo "    bun test --watch         - test otomatis saat file berubah"
    echo "    bun test --coverage      - tampilkan code coverage"
    echo ""
    echo "  [ TOOLS LAINNYA ]"
    echo "    bunx <nama>              - jalankan CLI package tanpa install global"
    echo "                               (sama seperti npx, tapi lebih cepat)"
    echo "    bun --hot <file.ts>      - jalankan file dengan hot reload"
    echo "    bun repl                 - buka JavaScript REPL interaktif"
    echo "    bun --version            - cek versi bun"
    echo "    bun upgrade              - upgrade bun ke versi terbaru"
    echo ""
    echo "  [ NIX BUILD (untuk production) ]"
    echo "    nix build .#nextjs       - build app dengan Nix (reproducible)"
    echo "    ./result/bin/my-app      - jalankan hasil build"
    echo ""
    echo "  [ TIPS UNTUK PEMULA ]"
    echo "    - Setelah 'bun install', jangan hapus folder node_modules"
    echo "    - File 'bun.lock' harus di-commit ke git (penting!)"
    echo "    - Bun bisa baca file .env otomatis, simpan rahasia di sana"
    echo "    - Gunakan 'bunx' bukan 'npx' agar lebih cepat"
    echo "================================================================"
    echo ""
  '';
}
