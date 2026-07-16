{ templateInputs }:
{ pkgs, ... }: {
  languages.javascript = {
    enable = true;
    pnpm.enable = true;
    nodejs.enable = true;
  };

  packages = with pkgs; [
    git
  ];

  enterShell = ''
    echo ""
    echo "================================================================"
    echo "   SELAMAT DATANG DI LINGKUNGAN PENGEMBANGAN JS "
    echo "================================================================"
    echo "  Node.js  : $(node --version)"
    echo "  pnpm     : $(pnpm --version)"
    echo "================================================================"
    echo ""
    echo "  Memulai proyek baru, example:"
    echo "   - NextJS : pnpm create next-app@latest ." 
    echo "   - Astro  : pnpm create astro@latest ."
    echo ""
    echo "  Perintah umum:"
    echo "    pnpm dev       - jalankan dev server"
    echo "    pnpm build     - build production"
    echo "    pnpm start     - jalankan production server"
    echo "    pnpm lint      - cek linting"
    echo ""
    echo "  Catatan NixOS: Semua dependensi terisolasi di folder ini."
    echo "  Jangan gunakan 'npm install -g' atau merusak sistem global Anda."
    echo "================================================================"
    echo ""
  '';
}
