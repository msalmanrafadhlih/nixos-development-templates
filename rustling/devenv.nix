{
  # Contoh Scripts untuk mempermudah belajar
  scripts.hint.exec = "rustlings hint $1";
  scripts.watch.exec = "rustlings watch";

  # Menampilkan pesan saat masuk shell
  enterShell = ''
    echo "--- 📚 RUST LEARNING MODE ---"
    echo "Toolchain: $(rustc --version)"
    echo "Tersedia command: 'watch' untuk mulai, 'hint <no>' untuk bantuan."
  '';

  # Jika nanti belajar database, tinggal tambah di sini
  # services.postgres.enable = true;
}
