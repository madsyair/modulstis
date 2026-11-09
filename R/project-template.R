#' Membuat kerangka proyek modul praktikum
#'
#' Menyiapkan folder proyek berisi struktur baku modulstis: folder `spec/`
#' untuk spesifikasi modul, folder `modul/` untuk keluaran, skrip render, dan
#' berkas README. Fungsi ini juga menjadi templat proyek RStudio; setelah paket
#' terpasang, pilih **File > New Project > New Directory > Proyek Modul
#' Praktikum (modulstis)**.
#'
#' @param path folder proyek yang akan dibuat
#' @param matkul nama mata kuliah
#' @param kode kode mata kuliah
#' @param prodi program studi
#' @param semester semester penyelenggaraan
#' @param penyusun nama penyusun
#' @param n_modul banyaknya modul yang direncanakan
#' @param contoh_spec bila `TRUE`, sertakan satu spesifikasi contoh yang siap dirender
#' @param ... argumen tambahan dari RStudio (diabaikan)
#'
#' @return Jalur proyek, secara tersembunyi.
#' @export
buat_proyek_modul <- function(path,
                              matkul      = "Nama Mata Kuliah",
                              kode        = "K000000",
                              prodi       = "D-IV Komputasi Statistik",
                              semester    = "6 (Genap)",
                              penyusun    = "Nama Penyusun",
                              n_modul     = 14,
                              contoh_spec = TRUE,
                              ...) {
  # RStudio mengirim nilai kotak centang sebagai teks "TRUE"/"FALSE"
  if (is.character(contoh_spec)) contoh_spec <- toupper(contoh_spec) %in% c("TRUE", "ON", "YES")
  n_modul <- suppressWarnings(as.integer(n_modul))
  if (is.na(n_modul) || n_modul < 1) n_modul <- 14L

  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  for (sub in c("spec", "modul", "buku")) {
    dir.create(file.path(path, sub), recursive = TRUE, showWarnings = FALSE)
    # penanda agar folder kosong tetap terbawa saat proyek disalin atau di-zip
    writeLines(character(0), file.path(path, sub, ".gitkeep"))
  }

  if (isTRUE(contoh_spec)) {
    writeLines(contoh_spec_yaml(matkul, kode, prodi, semester, penyusun),
               file.path(path, "spec", "modul-01-contoh.yml"))
  }
  writeLines(skrip_render_proyek(),        file.path(path, "render_modul.R"))
  writeLines(readme_proyek(matkul, kode, prodi, semester, penyusun, n_modul),
             file.path(path, "README.md"))

  invisible(path)
}

# ---- pembantu internal -------------------------------------------------------

# Versi paket yang sedang terpasang; dipakai agar README proyek tidak menulis
# nomor versi yang usang.
versi_modulstis <- function() {
  tryCatch(as.character(utils::packageVersion("modulstis")),
           error = function(e) "terbaru")
}

contoh_spec_yaml <- function(matkul, kode, prodi, semester, penyusun) {
  c(
    "number: 1",
    "title: \"Judul Modul Pertama\"",
    "short_code: \"contoh\"",
    "topic: \"Topik Singkat\"",
    "pertemuan: 1",
    "sub_cpmk: >",
    "  Sub-CPMK 1: Mahasiswa mampu menjelaskan dan menerapkan pokok bahasan",
    "  pada modul ini.",
    "packages: [dplyr]",
    "contoh_title: \"Contoh Praktikum dengan R\"",
    "course:",
    sprintf("  matkul: \"%s\"", matkul),
    sprintf("  matkul_besar: \"%s\"", toupper(matkul)),
    sprintf("  kode: \"%s\"", kode),
    sprintf("  semester: \"%s\"", semester),
    sprintf("  prodi: \"%s\"", prodi),
    "  penyusun:",
    sprintf("    - \"%s\"", penyusun),
    "",
    "datasets:",
    "  - name: data_contoh",
    "    role: contoh",
    "    recipe:",
    "      kind: tabular",
    "      \"n\": 200",
    "      seed: 2025",
    "      columns:",
    "        id: {type: integer, min: 1, max: 200}",
    "        wilayah: {type: category, levels: [Perkotaan, Perdesaan], probs: [0.5, 0.5]}",
    "        nilai: {type: numeric, min: 0, max: 100, digits: 1}",
    "",
    "body:",
    "  deskripsi:",
    "    - >",
    "      Tuliskan di sini gambaran modul: apa yang dibahas, mengapa penting,",
    "      dan bagaimana kaitannya dengan modul sebelum maupun sesudahnya.",
    "    - \"\\\\begin{kotakperhatian}[Tentang data]\\nBerkas data pada modul ini adalah \\\\textbf{data simulasi}, \\\\textbf{bukan data nyata} dan \\\\textbf{bukan data resmi} instansi mana pun.\\n\\\\end{kotakperhatian}\"",
    "  tujuan:",
    "    - \"Setelah menyelesaikan praktikum ini, mahasiswa diharapkan mampu:\"",
    "    - \"1. **Menjelaskan** pokok bahasan modul ini.\"",
    "    - \"2. **Menerapkan** langkahnya dengan R.\"",
    "  alat:",
    "    - \"Perangkat dan bahan yang diperlukan:\"",
    "    - \"- **R** (RStudio) dengan paket `dplyr`.\"",
    "    - \"- Berkas data: `data/data_contoh.csv`.\"",
    "  instruksi:",
    "    - \"Kerjakan Contoh berurutan, lalu selesaikan Latihan dan Penugasan.\"",
    "  teori:",
    "    - \"### Pokok Bahasan\"",
    "    - >",
    "      Tuliskan teori singkat di sini, disertai rumus bila diperlukan.",
    "  contoh:",
    "    - contoh: \"Membaca dan mengenali data\"",
    "      kode_r: \"d <- read.csv(\\\"data/data_contoh.csv\\\", stringsAsFactors = TRUE)\\ndim(d)\\nstr(d)\"",
    "      judul_r: \"dim dan str\"",
    "      eval: true",
    "      penjelasan: >",
    "        Jelaskan apa yang dikerjakan kode ini, baris demi baris.",
    "      interpretasi: >",
    "        Tafsirkan keluarannya: apa artinya bagi persoalan yang dibahas.",
    "  latihan:",
    "    - \"\\\\latihan{Penjelajahan awal}\"",
    "    - \"```{r eval=FALSE}\\nd <- read.csv(\\\"data/data_contoh.csv\\\")\\n____(d)   # banyaknya baris dan kolom\\n```\"",
    "  penugasan:",
    "    - \"\\\\begin{kotaktugas}\\nTuliskan konteks penugasan di sini.\\n\\\\end{kotaktugas}\"",
    "    - \"1. Butir pertama penugasan.\"",
    "  ringkasan:",
    "    - \"Tuliskan rangkuman modul dan kaitannya dengan modul berikutnya.\"",
    "  referensi:",
    "    - \"Nama, A. (Tahun). *Judul Buku*. Penerbit.\"",
    "",
    "exercises:",
    "  - id: \"L1.1\"",
    "    points: 20",
    "    solution: \"Ringkasan jawaban dalam satu kalimat.\"",
    "    judul_r: \"Solusi Latihan (R)\"",
    "    solusi_r: |",
    "      d <- read.csv(\"data/data_contoh.csv\", stringsAsFactors = TRUE)",
    "      dim(d)",
    "    interpretasi: >",
    "      Jelaskan mengapa jawaban itu benar dan apa yang perlu diperhatikan.",
    "",
    "references:",
    "  - \"Nama, A. (Tahun). Judul Buku. Penerbit.\""
  )
}

skrip_render_proyek <- function() {
  c(
    "# ===========================================================================",
    "# render_modul.R -- Membangun modul dan kunci jawaban dari spesifikasi YAML.",
    "#",
    "# Cara pakai:",
    "#   Rscript render_modul.R          seluruh spesifikasi di folder spec/",
    "#   Rscript render_modul.R 3 5      modul 3 sampai 5 saja",
    "# ===========================================================================",
    "suppressMessages(library(modulstis))",
    "",
    "spec_files <- sort(list.files(\"spec\", \"\\\\.yml$\", full.names = TRUE))",
    "if (!length(spec_files)) stop(\"Belum ada spesifikasi .yml di folder spec/\")",
    "",
    "arg    <- commandArgs(TRUE)",
    "dari   <- if (length(arg) >= 1) as.integer(arg[1]) else 1L",
    "sampai <- if (length(arg) >= 2) as.integer(arg[2]) else length(spec_files)",
    "",
    "th <- theme_factory()",
    "r  <- renderer_factory(\"bookdown\", theme = th)",
    "",
    "for (f in spec_files[seq(dari, min(sampai, length(spec_files)))]) {",
    "  sp  <- module_spec_from_yaml(f)",
    "  cek <- sp$validate()",
    "  if (!isTRUE(cek$ok)) {",
    "    message(\"Spesifikasi bermasalah: \", basename(f))",
    "    print(cek$messages)",
    "    next",
    "  }",
    "  out <- file.path(\"modul\", sprintf(\"Modul%02d_%s\", sp$number, sp$short_code))",
    "  dir.create(out, recursive = TRUE, showWarnings = FALSE)",
    "",
    "  generate_module_data(sp, output_dir = out)",
    "  r$render(ModuleBuilder$new(theme = th)$build(sp), out)",
    "  r$render(AnswerKeyBuilder$new(theme = th)$build(sp), out)",
    "  message(\"  selesai: \", basename(out))",
    "}"
  )
}

readme_proyek <- function(matkul, kode, prodi, semester, penyusun, n_modul) {
  c(
    sprintf("# Modul Praktikum %s", matkul), "",
    sprintf("**Kode mata kuliah:** %s  ", kode),
    sprintf("**Program studi:** %s  ", prodi),
    sprintf("**Semester:** %s  ", semester),
    sprintf("**Penyusun:** %s  ", penyusun),
    sprintf("**Rencana:** %d modul", n_modul), "",
    "---", "",
    "## Tata letak", "",
    "```",
    "spec/     spesifikasi modul dalam YAML (satu berkas per modul)",
    "modul/    keluaran render: PDF modul, kunci, dan data",
    "buku/     bagian awal dan akhir buku gabungan",
    "```", "",
    "## Alur kerja", "",
    "1. Susun atau sunting spesifikasi di folder `spec/`.",
    "2. Periksa kesahihannya sebelum merender:", "",
    "```r",
    "library(modulstis)",
    "sp <- module_spec_from_yaml(\"spec/modul-01-contoh.yml\")",
    "sp$validate()$ok      # harus TRUE",
    "```", "",
    "3. Render seluruh modul:", "",
    "```bash",
    "Rscript render_modul.R",
    "```", "",
    "## Prasyarat", "",
    "| Kebutuhan | Keterangan |",
    "|---|---|",
    "| R 4.1+ | mesin penjalan kode |",
    sprintf("| `modulstis` %s | generator template modul |", versi_modulstis()),
    "| XeLaTeX | mesin penyusun PDF |",
    "| Font Carlito | font tata letak modul |",
    "| poppler-utils | menyediakan `pdfunite`, `pdfinfo` |",
    "| Pola pemenggalan Indonesia | `texlive-lang-other` atau `tinytex::tlmgr_install(\"hyphen-indonesian\")` |", "",
    "Prasyarat terakhir mudah terlewat karena ketiadaannya **tidak menimbulkan galat** ---",
    "modul tetap tersusun, hanya kata-katanya terpenggal menurut kaidah bahasa Inggris",
    "(`meny-atakan` alih-alih `me-nyatakan`). Periksa dengan `kpsewhich hyph-id.tex`.", "",
    "## Panduan lengkap", "",
    "```r",
    "buka_pedoman()              # Buku Pedoman (PDF)",
    "vignette(\"pedoman-modulstis\")   # keterangan ringkas + daftar isi",
    "vignette(\"contoh-penerapan-penuh\")",
    "```"
  )
}
