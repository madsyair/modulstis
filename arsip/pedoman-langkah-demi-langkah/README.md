# Arsip: Pedoman Langkah demi Langkah `modulstis`

*Menyusun Modul Praktikum dengan modulstis: Pedoman Langkah demi Langkah untuk Dosen*

Folder ini adalah **arsip** Buku Pedoman versi pertama untuk `modulstis` 0.3.11, yang ditulis
dalam bentuk panduan langkah demi langkah sepanjang lima belas bab (125 halaman). Buku ini
digantikan oleh Buku Pedoman Aplikasi di folder [`pedoman/`](../../pedoman/), yang mengikuti
sistematika buku pedoman aplikasi: sampul, latar belakang, penjelasan model/program, bahasa
pemrograman dan perangkat beserta contoh penggunaan, serta lampiran kode sumber inti.

Arsip ini tidak dipelihara lagi dan dikecualikan dari paket (`.Rbuildignore`).

| Berkas | Isi |
|---|---|
| `Pedoman_modulstis_langkah_demi_langkah.pdf` | PDF terakhir yang dibangun (125 halaman) |
| `_quarto.yml`, `index.qmd`, `bab01.qmd` … `bab15.qmd`, `lampiran-a.qmd` … `lampiran-e.qmd` | sumber Quarto |
| `_setup.R`, `siapkan.R`, `bangun.R` | pembantu dan skrip pembangun |
| `contoh/` | spesifikasi Modul 7 bertahap, katalog kotak, templat kosong, `bagian_awal.Rmd`, `susun_buku.R` |
| `tex/`, `partials/`, `gambar/` | gaya, sampul, dan gambar |

## Isi buku

| Bagian | Bab | Isi |
|:--|:--|:--|
| I Memulai | 1--3 | peran paket; pemasangan di Windows, macOS, dan Linux; modul pertama |
| II Menyusun Isi | 4--10 | YAML; identitas modul; sebelas bagian isi; contoh berkode; data latihan; latihan dan kunci; kotak, rumus, dan tabel |
| III Menerbitkan | 11--15 | merender; buku modul dan buku kunci; tampilan; penanganan galat; alur kerja satu semester |
| Lampiran | A--E | rujukan YAML, templat, katalog kotak, daftar fungsi, kunci uji pemahaman |

## Membangun ulang

Memerlukan `modulstis` 0.3.11 terpasang. Dari folder ini:

```bash
Rscript bangun.R
```

PDF ditulis ke folder ini, tidak ke `inst/pedoman/`.
