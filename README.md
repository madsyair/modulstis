# modulstis

> Generator template **modul praktikum** dan **buku kunci jawaban** bernuansa warna logo BPS
> dari satu spesifikasi deklaratif — backend **bookdown** / **Quarto** + LaTeX (XeLaTeX) → PDF.

Politeknik Statistika STIS · D-IV Komputasi Statistik
Penyusun: Achmad Syahrul Choir

## Mengapa package ini

Membangun banyak modul praktikum secara manual (menyalin preamble, mengganti nomor,
menulis ulang struktur) rawan galat dan sulit dipelihara. `modulstis` mengubahnya menjadi
proses **deklaratif, terprogram, dan teruji**: satu `ModuleSpec` → modul + kunci + data,
di dua backend, dengan tema warna BPS yang sama.

## Prinsip desain

- **OOP (R6)** dengan pola **Strategy** (renderer), **Builder** (konten),
  **Template Method** (bagian), **Facade** (proyek), **Factory**, **Registry**.
- **SOLID & DRY**: satu sumber kebenaran (`ModuleSpec`); soal & solusi tak mungkin
  tidak sinkron karena berasal dari spec yang sama.
- **Looping/functional engineering**: `purrr` untuk membangkitkan banyak modul.
- **Logging engineering**: `Logger` terstruktur berjenjang.
- **Harness engineering**: uji `testthat`, pipeline `targets`, CI GitHub Actions.

## Instalasi

```r
# dari sumber
R CMD INSTALL .
# atau saat pengembangan
devtools::load_all()
```

Prasyarat render PDF: **XeLaTeX** (TeX Live/TinyTeX) dengan paket `lmodern`, `carlito`,
serta `rmarkdown`/`bookdown` atau `quarto`.

## Contoh cepat

```r
library(modulstis)

# 1) Muat & validasi spesifikasi
spec <- module_spec_from_yaml(
  system.file("specs", "modul-13-cca.yml", package = "modulstis"))
spec$validate()

# 2) Render modul + kunci (bookdown atau quarto)
render_module(spec, backend = "bookdown", theme = "bps",
              output_dir = "build")
#> build/modul-13/Modul_13_CCA.pdf
#> build/kunci-13/Kunci_13_CCA.pdf
```

### Banyak modul sekaligus (Facade + looping)

```r
proj <- ModuleProject$new(
  specs_dir = system.file("specs", package = "modulstis"),
  theme = "bps", backend = "quarto", log_level = "info",
  output_dir = "build")

proj$validate_all()     # fail-fast agregat
proj$generate_data()    # tulis data/*.csv per modul
proj$render_all()       # modul + kunci untuk semua spec
```

## Struktur spesifikasi (YAML)

```yaml
number: 13
title: "Analisis Korelasi Kanonik"
short_code: "CCA"
pertemuan: 14
sub_cpmk: "Sub-CPMK 10: ..."
datasets:
  - name: kabkota_cca
    role: contoh
    recipe: { kind: mvn, vars: [RLS, HLS, AHH, Sanitasi], n: 100, seed: 2025 }
body:
  contoh:
    - contoh: "Judul contoh"
      kode: "cancor(X, Y)"
      interpretasi: "..."
exercises:
  - { id: L13.1, points: 40, solution: "..." }
```

## Ekstensibilitas (Open/Closed)

- Backend baru (mis. Typst) → subclass `Renderer` + daftar di `renderer_factory()`.
- Jenis bagian baru → subclass `Section` + `make_section()`.
- Tema kampus lain → `LatexTheme$new(palette = list(...))`.
- Generator data baru → tambah `kind` di `generate_dataset()`.

## Lisensi

MIT © 2025 Achmad Syahrul Choir dan Politeknik Statistika STIS.


## Dokumentasi

Buku pedoman lengkap tersedia sebagai vignette:

```r
vignette("pedoman-modulstis", package = "modulstis")
```

**79 halaman**, 11 bab dan 5 lampiran:

| Bagian | Isi |
|--------|-----|
| I Memulai | pemasangan, modul pertama dalam 15 menit |
| II Menyusun Isi | anatomi YAML, sebelas bagian modul, contoh dan latihan |
| III Sintaks | LaTeX (14 kotak, rumus, tabel, preamble), R Markdown dan knitr |
| IV Menerbitkan | tema, sampul, buku gabungan berpenomoran berlanjut |
| Lampiran A–E | rujukan YAML, kartu LaTeX, API, pemecahan masalah, studi kasus |

Buku Pedoman disimpan sebagai PDF di `inst/pedoman/` --- **bukan** sebagai vignette
PDF di `inst/doc/` --- beserta seluruh sumber dan skrip `bangun_pedoman.R` untuk
membangunnya ulang. Buka dengan `buka_pedoman()`.

> Penempatan itu disengaja: `R CMD check` memeriksa ukuran PDF di bawah `inst/doc`
> dan memberi WARNING bila `gs+qpdf` masih dapat memampatkannya secara berarti.
> Buku ini memuat sampul dan ilustrasi beresolusi cetak (~1,5 Mb sebelum
> dipadatkan), sehingga menaruhnya di luar `inst/doc` membuat peringatan itu tidak
> mungkin muncul --- pada mesin siapa pun, dengan atau tanpa
> `--compact-vignettes=both`.

Vignette kedua, `contoh-penerapan-penuh`, memperagakan penerapan paket dari awal
hingga akhir pada dua mata kuliah yang spesifikasinya disertakan: Pemrograman
Statistika D-IV lewat backend bookdown dan D-III lewat backend Quarto.
