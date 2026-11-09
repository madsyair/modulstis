# modulstis

> Generator **modul praktikum** dan **buku kunci jawaban** bernuansa warna logo BPS
> dari satu spesifikasi deklaratif (YAML). Backend **bookdown** atau **Quarto**, PDF lewat XeLaTeX.

Politeknik Statistika STIS · Penyusun: Achmad Syahrul Choir

## Untuk apa paket ini

Menyusun empat belas modul praktikum secara manual berarti menyalin preamble, mengganti nomor,
menulis ulang struktur, dan menjaga kunci jawaban tetap cocok dengan soalnya. `modulstis`
mengubahnya menjadi satu langkah: Anda menulis **satu berkas YAML per modul**, dan paket
membuatkan tiga keluaran yang selalu sinkron:

- **modul praktikum** (PDF) dengan sampul, daftar isi, sebelas bagian baku, dan kode R/Python
  yang benar-benar dijalankan saat render;
- **kunci jawaban** (PDF) yang dirakit dari spesifikasi yang sama;
- **data latihan** (CSV) yang dibangkitkan dari resep dengan `seed` tetap, atau disalin dari
  berkas data nyata.

## Pemasangan

Paket belum ada di CRAN. Pasang dari GitHub:

```r
install.packages("remotes")
remotes::install_github("madsyair/modulstis")
```

Perangkat yang diperlukan untuk merender PDF:

| Kebutuhan | Cara memasang |
|---|---|
| R ≥ 4.1 dan RStudio | <https://cran.r-project.org>, <https://posit.co/download/rstudio-desktop/> |
| XeLaTeX (TinyTeX) | `install.packages("tinytex"); tinytex::install_tinytex()` |
| Pola pemenggalan bahasa Indonesia | `tinytex::tlmgr_install("hyphen-indonesian")`; pada TeX Live Debian/Ubuntu: paket `texlive-lang-other` |
| Font Carlito | Linux: `fonts-crosextra-carlito`; Windows/macOS: pasang berkas TTF Carlito |
| `rmarkdown`, `bookdown` | `install.packages(c("rmarkdown", "bookdown"))` |
| Quarto (opsional, untuk backend Quarto) | <https://quarto.org/docs/get-started/> dan `install.packages("quarto")` |
| Penggabung PDF (untuk buku gabungan) | `install.packages(c("pdftools", "qpdf"))`, atau poppler-utils (`pdfunite`) |

Pola pemenggalan mudah terlewat karena ketiadaannya **tidak menimbulkan galat**: modul tetap
tersusun, hanya kata-katanya dipenggal menurut kaidah bahasa Inggris. Periksa dengan
`kpsewhich hyph-id.tex` di terminal.

Setelah semuanya terpasang, periksa dengan:

```r
modulstis::cek_kesiapan()
```

Langkah lengkap untuk Windows, macOS, dan Linux ada di Bab 2 Buku Pedoman.

## Mulai cepat

### Proyek baru

Di RStudio pilih **File → New Project → New Directory → Proyek Modul Praktikum (modulstis)**,
atau dari konsol:

```r
library(modulstis)
buat_proyek_modul("pemrograman-statistika",
                  matkul = "Pemrograman Statistika", kode = "K242310",
                  prodi = "D-IV Statistika", semester = "3 (Ganjil)",
                  penyusun = "Nama Anda")
```

Folder proyek berisi `spec/modul-01-contoh.yml` yang siap dirender, `render_modul.R`, dan
README. Dari folder proyek, jalankan:

```bash
Rscript render_modul.R        # semua spesifikasi di spec/
Rscript render_modul.R 3 5    # modul 3 sampai 5 saja
```

Hasilnya ada di `modul/Modul01_contoh/`: PDF modul, PDF kunci, dan folder `data/`.

### Satu modul dari spesifikasi bawaan paket

```r
library(modulstis)

spec <- module_spec_from_yaml(
  system.file("specs_ps", "modul-07-deskriptif.yml", package = "modulstis"))
spec$validate()
#> ✔ Spesifikasi valid.

hasil <- render_module(spec, backend = "bookdown", output_dir = "build")
hasil$modul$path
#> [1] "build/modul-07/Modul_07_deskriptif.pdf"
hasil$kunci$path
#> [1] "build/kunci-07/Kunci_07_deskriptif.pdf"
```

### Semua modul satu mata kuliah

```r
proj <- ModuleProject$new(
  specs_dir  = system.file("specs_ps", package = "modulstis"),
  backend    = "bookdown",        # atau "quarto"
  output_dir = "build")

proj$validate_all()   # TRUE bila semua spesifikasi valid
proj$render_all()     # modul + kunci untuk setiap spesifikasi
```

## Spesifikasi yang disertakan

| Folder | Mata kuliah | Program studi | Jumlah modul |
|---|---|---|:-:|
| `specs_ps` | Pemrograman Statistika (K242310) | D-IV Statistika | 14 |
| `specs_d3` | Pemrograman Statistika (K242310) | D-III Statistika | 14 |
| `specs_dm` | Data Mining dan Big Data (K202505) | D-IV Statistika | 15 |

Lihat isinya dengan `list.files(system.file("specs_ps", package = "modulstis"))`.

## Bentuk spesifikasi (YAML)

```yaml
number: 7
title: "Statistik Deskriptif dan Eksplorasi Data"
short_code: "deskriptif"
pertemuan: 7
sub_cpmk: >
  Sub-CPMK 7: Mahasiswa mampu menjelaskan dan menerapkan statistik deskriptif dengan R.
course:
  matkul: "Pemrograman Statistika"
  kode: "K242310"
  semester: "3 (Ganjil)"
  prodi: "D-IV Statistika"
  penyusun: ["Nama Anda"]
datasets:
  - name: data_rumahtangga
    role: contoh
    recipe:
      kind: tabular
      "n": 60
      seed: 2025
      columns:
        wilayah: {type: category, levels: [Perkotaan, Perdesaan], probs: [0.45, 0.55]}
        pengeluaran: {type: numeric, min: 500, max: 5000, digits: 1}
body:
  deskripsi:
    - "Modul ini membahas ..."
  contoh:
    - contoh: "Ringkasan numerik"
      kode_r: "d <- read.csv(\"data/data_rumahtangga.csv\")\nsummary(d$pengeluaran)"
      eval: true
      penjelasan: "..."
      interpretasi: "..."
exercises:
  - id: "L7.1"
    points: 20
    solution: "..."
```

Rujukan lengkap semua kunci ada di Lampiran A Buku Pedoman.

## Buku Pedoman

```r
buka_pedoman()                         # membuka PDF Buku Pedoman
vignette("pedoman-modulstis")          # ringkasan isi dan cara membukanya
vignette("contoh-penerapan-penuh")     # dua mata kuliah, dua backend
```

Buku Pedoman *Aplikasi modulstis: Paket R Penyusun Modul Praktikum dan Kunci Jawaban dari Satu Spesifikasi* disusun sebagai dokumen pendamping program komputer. Isinya: latar
belakang; penjelasan model dan program (arsitektur, komponen, alur kerja); bahasa pemrograman,
perangkat, pemasangan di Windows, macOS, dan Linux, serta contoh penggunaan dengan Modul 7
Pemrograman Statistika D-IV; dan lampiran kode sumber inti. Sumber Quarto buku ini ada di folder
[`pedoman/`](pedoman/) repositori.

## Rancangan paket

- **OOP (R6)** dengan pola Strategy (renderer), Builder (konten), Template Method (bagian),
  Facade (proyek), dan Factory.
- **Satu sumber kebenaran**: soal dan solusi berasal dari spesifikasi yang sama.
- **Pipeline fungsional** dengan `purrr` untuk membangkitkan banyak modul; satu modul yang gagal
  tidak menghentikan modul lain.
- **Logging** terstruktur berjenjang dan **uji** `testthat`.

Perluasan:

- Backend baru → subclass `Renderer` dan daftarkan di `renderer_factory()`.
- Jenis bagian baru → subclass `Section` dan `make_section()`.
- Tema lain → `LatexTheme$new(palette = list(...))`.
- Generator data baru → tambah `kind` di `generate_dataset()`.

## Lisensi

MIT © 2025 Achmad Syahrul Choir dan Politeknik Statistika STIS.
