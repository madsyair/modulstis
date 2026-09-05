# Buku Pedoman `modulstis`

**Menyusun Modul Praktikum dengan Paket R `modulstis`**
Panduan R Markdown, Quarto, LaTeX, dan Otomatisasi

Penyusun: Achmad Syahrul Choir · Politeknik Statistika STIS
Untuk paket versi 0.3.8

## Hasil

**`Pedoman_modulstis.pdf` — 82 halaman**

| Bagian | Isi | Hlm |
|--------|-----|:---:|
| **Bagian awal** | sampul, hak cipta, kata pengantar, daftar isi, cara membaca | i–vii |
| **I Memulai** | Bab 1–3 | 1–13 |
| **II Menyusun Isi** | Bab 4–6 | 14–30 |
| **III Sintaks** | Bab 7–8 | 31–43 |
| **IV Menerbitkan** | Bab 9–11 | 44–54 |
| **Lampiran A–E** | rujukan YAML, kartu LaTeX, API, pemecahan masalah, studi kasus | 55–70 |
| **Bagian akhir** | glosarium, indeks perintah, daftar pustaka | 71–75 |

Penomoran halaman **berlanjut 1–75** untuk isi; bagian awal memakai angka romawi.

## Daftar Bab

| Bab | Judul | Hlm |
|:--:|-------|:--:|
| 1 | Mengapa `modulstis` | 1 |
| 2 | Menyiapkan Lingkungan | 4 |
| 3 | Modul Pertama dalam 15 Menit | 10 |
| 4 | Anatomi Spesifikasi YAML | 14 |
| 5 | Sebelas Bagian Modul | 20 |
| 6 | Contoh, Kode, dan Latihan | 25 |
| 7 | Sintaks LaTeX yang Dipakai Modul | 31 |
| 8 | Sintaks R Markdown dan Knitr | 39 |
| 9 | Menyesuaikan Tampilan | 44 |
| 10 | Menyusun Buku Gabungan | 48 |
| 11 | Alur Kerja Sehari-hari | 52 |
| A–E | Lampiran | 55 |

## Isi Folder

| Berkas | Keterangan |
|--------|------------|
| `Pedoman_modulstis.pdf` | **buku lengkap (79 hlm)** |
| `bagian_0.Rmd` | bagian awal: sampul, hak cipta, kata pengantar, daftar isi |
| `bagian_1.Rmd` … `bagian_5.Rmd` | naskah Bab 1–11 dan Lampiran |
| `bagian_6.Rmd` | bagian akhir: glosarium, indeks, daftar pustaka |
| `preamble_pedoman*.tex` | preamble tiap bagian (nomor bab dan halaman berlanjut) |
| `gambar/tataletak_rstudio.tex` | sumber ilustrasi RStudio |
| `img/` | logo STIS dan latar gedung |

## Cara Merender

```bash
# ilustrasi (bila disunting)
cd gambar && xelatex tataletak_rstudio.tex && xelatex tataletak_rstudio.tex && cd ..

# seluruh bagian
for i in 0 1 2 3 4 5 6; do
  Rscript -e "rmarkdown::render('bagian_$i.Rmd')"
done

# gabungkan
pdfunite bagian_0.pdf bagian_1.pdf bagian_2.pdf bagian_3.pdf \
         bagian_4.pdf bagian_5.pdf bagian_6.pdf Pedoman_modulstis.pdf
```

## Catatan Penomoran

Setiap `preamble_pedoman*.tex` memuat `\setcounter{page}{N}` dan `\setcounter{section}{N}`
agar nomor halaman dan nomor bab berlanjut antar-bagian. Bila panjang salah satu bagian
berubah, hitung ulang offsetnya lalu render ulang bagian sesudahnya.

## Tentang Ilustrasi RStudio

Gambar antarmuka RStudio adalah **ilustrasi tata letak** (TikZ), bukan tangkapan layar.
RStudio Server terbukti tidak dapat melayani di lingkungan penyusunan. Ilustrasi diberi
keterangan tegas sebagai skema dan dapat digantikan tangkapan layar asli kapan saja tanpa
mengubah naskah — cukup ganti `gambar/tataletak_rstudio.pdf`.

## Membangun ulang

```bash
cd inst/pedoman && Rscript bangun_pedoman.R      # atau: make pedoman
```

Skrip merender ketujuh bagian, menggabungkannya dengan `pdfunite`, **memadatkan** PDF
(`tools::compactPDF(gs_quality = "ebook")`, ~1,5 Mb → ~0,7 Mb), lalu membersihkan berkas
antara. Buku tetap berada di folder ini dan **tidak** disalin ke `vignettes/`: `R CMD check`
hanya memeriksa ukuran PDF di bawah `inst/doc`, sehingga penempatan ini membuat WARNING
*sizes of PDF files under inst/doc* tidak mungkin muncul. Pemakai membukanya dengan
`buka_pedoman()`.

Bila jumlah halaman suatu bagian berubah, jalankan `Rscript bangun_pedoman.R hitung` lebih
dahulu, setel `\setcounter{page}{}` pada tiap `preamble_pedoman_*.tex` sesuai keluarannya,
lalu bangun ulang.
