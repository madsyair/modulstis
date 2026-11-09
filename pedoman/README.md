# Sumber Buku Pedoman `modulstis`

*Menyusun Modul Praktikum dengan modulstis: Pedoman Langkah demi Langkah untuk Dosen*

Folder ini berisi sumber Quarto Buku Pedoman. Folder ini dikecualikan dari paket
(`.Rbuildignore`); hasilnya, `Pedoman_modulstis.pdf`, dipasang di `inst/pedoman/` dan dibuka
pengguna dengan `buka_pedoman()`.

## Isi

| Berkas | Isi |
|---|---|
| `_quarto.yml` | konfigurasi buku: urutan bab, bahasa, gaya PDF |
| `index.qmd` | kata pengantar dan cara membaca buku |
| `bab01.qmd` … `bab15.qmd` | lima belas bab dalam tiga bagian |
| `lampiran-a.qmd` … `lampiran-e.qmd` | rujukan YAML, templat, katalog kotak, daftar fungsi, kunci uji pemahaman |
| `_setup.R` | pembantu bersama; mesin chunk `rproyek` yang menjalankan kode di proses R terpisah |
| `siapkan.R` | dijalankan Quarto sebelum render: menulis versi paket, mengosongkan `_kerja/` |
| `contoh/` | spesifikasi Modul 7 bertahap (`modul-07-tahap-NN.yml`), katalog kotak, templat kosong, `bagian_awal.Rmd`, `susun_buku.R` |
| `tex/preamble.tex`, `partials/before-body.tex` | gaya, sampul, dan halaman hak cipta |
| `gambar/` | skema tata letak RStudio, logo, dan latar sampul |
| `bangun.R` | membangun buku, menyalinnya ke `inst/pedoman/`, lalu memadatkannya |

## Contoh berjalan

Buku membangun ulang **Modul 7 Pemrograman Statistika D-IV** secara bertahap. Setiap bab
memasang tahapnya ke proyek contoh di `_kerja/pemrograman-statistika/` dengan
`pasang_tahap()`, sehingga setiap bab dapat dirender sendiri-sendiri.

## Semua kode dijalankan sungguhan

Chunk berlabel `{rproyek}` dijalankan di proses `Rscript` terpisah, karena paket memanggil
R Markdown sendiri dan render bersarang di dalam knitr tidak dapat diandalkan. Objek dan paket
disimpan antar-chunk dalam satu bab, sehingga chunk-chunk itu berperilaku seperti satu sesi R.
Opsi chunk tambahan:

- `wd`: direktori kerja (bawaan: folder proyek contoh);
- `tampil`: ekspresi indeks baris keluaran yang ditampilkan, misalnya `"c(1, length(hasil))"`;
- `stderr: true`: sertakan baris `WARN`/`ERROR` logger dan `Quitting from` yang ditulis ke stderr.

Keluaran semua chunk dicatat di `_kerja/log-chunk.txt` untuk penelusuran.

## Membangun

```bash
cd pedoman
Rscript bangun.R
```

Pembangunan penuh memerlukan sekitar sepuluh menit, karena puluhan modul dirender sungguhan.
