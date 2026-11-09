# Sumber Buku Pedoman `modulstis`

*Aplikasi modulstis: Paket R Penyusun Modul Praktikum dan Kunci Jawaban dari Satu Spesifikasi*

Folder ini berisi sumber Quarto Buku Pedoman. Folder ini dikecualikan dari paket
(`.Rbuildignore`); hasilnya, `Pedoman_modulstis.pdf`, dipasang di `inst/pedoman/` dan dibuka
pengguna dengan `buka_pedoman()`.

Buku Pedoman versi sebelumnya, *Menyusun Modul Praktikum dengan modulstis: Pedoman Langkah demi
Langkah untuk Dosen* (lima belas bab), diarsipkan di
[`arsip/pedoman-langkah-demi-langkah/`](../arsip/pedoman-langkah-demi-langkah/).

## Sistematika

Buku mengikuti sistematika buku pedoman aplikasi (sekaligus manual program komputer untuk
pencatatan ciptaan): sampul, latar belakang, penjelasan model/program, bahasa pemrograman dan
perangkat beserta contoh penggunaan, serta lampiran kode sumber inti.

| Berkas | Isi |
|---|---|
| `_quarto.yml` | konfigurasi buku: urutan bab, bahasa, gaya PDF |
| `index.qmd` | kata pengantar dan sistematika buku |
| `bab1-latar-belakang.qmd` | Bab 1 Latar Belakang |
| `bab2-program.qmd` | Bab 2 Penjelasan Model dan Program (diagram arsitektur TikZ) |
| `bab3-penggunaan.qmd` | Bab 3 Bahasa Pemrograman, Perangkat, dan Contoh Penggunaan |
| `lampiran-a.qmd` … `lampiran-d.qmd` | kode sumber inti, dibaca langsung dari `../R/` |
| `lampiran-e.qmd` | spesifikasi lengkap Modul 7 |
| `_setup.R` | pembantu bersama; mesin chunk `rproyek` yang menjalankan kode di proses R terpisah |
| `siapkan.R` | dijalankan Quarto sebelum render: menulis versi paket, mengosongkan `_kerja/` |
| `contoh/` | `modul-07-deskriptif.yml`, `bagian_awal.Rmd`, `susun_buku.R` |
| `tex/preamble.tex`, `partials/before-body.tex` | gaya, sampul, dan halaman identitas |
| `gambar/` | tangkapan layar RStudio (`rstudio/`), logo, dan latar sampul |
| `bangun.R` | membangun buku, menyalinnya ke `inst/pedoman/`, lalu memadatkannya |

## Semua kode dijalankan sungguhan

Chunk berlabel `{rproyek}` dijalankan di proses `Rscript` terpisah, karena paket memanggil
R Markdown sendiri dan render bersarang di dalam knitr tidak dapat diandalkan. Objek dan paket
disimpan antar-chunk dalam satu bab, sehingga chunk-chunk itu berperilaku seperti satu sesi R.
Opsi chunk tambahan:

- `wd`: direktori kerja (bawaan: folder proyek contoh `_kerja/pemrograman-statistika/`);
- `tampil`: ekspresi indeks baris keluaran yang ditampilkan, misalnya `"c(1, length(hasil))"`;
- `stderr: true`: sertakan baris `WARN`/`ERROR` logger dan `Quitting from` yang ditulis ke stderr.

Keluaran semua chunk dicatat di `_kerja/log-chunk.txt` untuk penelusuran.

## Membangun

```bash
cd pedoman
Rscript bangun.R
```

Pembangunan penuh memerlukan beberapa menit, karena modul dan buku dirender sungguhan.
