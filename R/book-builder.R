#' Sampul buku bernuansa warna logo BPS/STIS
#'
#' Membangkitkan potongan LaTeX sampul buku (logo STIS, latar gedung, pita
#' diagonal) dari templat bawaan paket. Dipakai pada bagian awal buku gabungan.
#'
#' @param judul1,judul2 dua baris judul besar pada sampul
#' @param kode kode mata kuliah
#' @param semester keterangan semester, mis. `"3 (Ganjil)"`
#' @param penyusun vektor nama penyusun (boleh lebih dari satu)
#' @param jenis label di atas judul, mis. `"BUKU MODUL PRAKTIKUM"`
#' @param ringkas satu baris keterangan singkat isi buku
#' @param varian `"modul"` (pita biru) atau `"kunci"` (pita hijau)
#' @param img_dir folder berisi `logo_stis.png` dan `gedung_bg.png`; bawaannya
#'   folder aset di dalam paket
#' @return string LaTeX siap disisipkan pada blok `{=latex}` sebuah R Markdown
#' @export
sampul_buku <- function(judul1, judul2 = "", kode = "", semester = "",
                        penyusun = "Achmad Syahrul Choir",
                        jenis = "BUKU MODUL PRAKTIKUM",
                        ringkas = "",
                        varian = c("modul", "kunci"),
                        img_dir = NULL) {
  varian <- match.arg(varian)
  tmpl <- readLines(
    system.file("templates", "buku", "sampul_buku.tex.tmpl", package = "modulstis"),
    warn = FALSE)
  tmpl <- paste(tmpl, collapse = "\n")
  if (is.null(img_dir)) {
    img_dir <- system.file("themes", "bps", "img", package = "modulstis")
  }
  baris <- paste(sprintf("\n     {\\fontsize{12}{15}\\selectfont \\textbf{%s}}", penyusun),
                 collapse = "\\\\[1pt]")
  out <- tmpl
  gg <- function(a, b) out <<- gsub(a, b, out, fixed = TRUE)
  gg("@@JENIS@@", jenis)
  gg("@@JUDUL1@@", judul1)
  gg("@@JUDUL2@@", judul2)
  gg("@@KODEMK@@", kode)
  gg("@@RINGKAS@@", ringkas)
  gg("@@SEMESTER@@", semester)
  gg("@@PENYUSUN@@", baris)
  gg("@@AKSENPITA@@", if (varian == "kunci") "bpshijau" else "bpsbiru")
  gg("@@IMGDIR@@", normalizePath(img_dir, winslash = "/", mustWork = FALSE))
  out
}

#' Render sekumpulan modul dengan penomoran halaman berlanjut
#'
#' Menjalankan alur dua tahap: tahap pertama merender untuk mengukur jumlah
#' halaman tiap modul, tahap kedua merender ulang dengan `halaman_awal` yang
#' sesuai sehingga nomor halaman berjalan terus lintas modul dan tidak dimulai
#' ulang. Halaman pertama tiap modul (sampul pembatas) ikut terhitung namun
#' nomornya tidak dicetak.
#'
#' @param specs vektor path berkas spesifikasi YAML, terurut sesuai buku
#' @param out_dirs vektor folder keluaran, sepanjang `specs`
#' @param jenis `"modul"` atau `"kunci"`
#' @param theme objek [LatexTheme]; bila `NULL` dipakai [theme_factory()]
#' @param mulai nomor halaman pertama buku (bawaan 1)
#' @return data.frame berisi kolom `spec`, `hal`, `mulai`, `akhir`
#' @export
render_berlanjut <- function(specs, out_dirs, jenis = c("modul", "kunci"),
                             theme = NULL, mulai = 1) {
  jenis <- match.arg(jenis)
  stopifnot(length(specs) == length(out_dirs))
  th <- theme %||% theme_factory()
  rnd <- renderer_factory("bookdown", theme = th)

  bangun <- function(sp) {
    if (jenis == "modul") ModuleBuilder$new(theme = th)$build(sp)
    else AnswerKeyBuilder$new(theme = th)$build(sp)
  }
  pola <- if (jenis == "modul") "^Modul_.*\\.pdf$" else "^Kunci_.*\\.pdf$"

  # Tahap 1 - ukur jumlah halaman
  hal <- integer(length(specs))
  for (i in seq_along(specs)) {
    sp <- module_spec_from_yaml(specs[i])
    # Kode contoh dan solusi membaca "data/...": data harus ada di folder
    # keluaran sebelum render, sama seperti pada render_module().
    if (length(sp$datasets)) generate_module_data(sp, output_dir = out_dirs[i])
    sp$course$halaman_awal <- 1
    rnd$render(bangun(sp), out_dirs[i])
    f <- list.files(out_dirs[i], pola, full.names = TRUE)[1]
    hal[i] <- pdf_halaman(f)
  }

  # Tahap 2 - terapkan offset berlanjut
  off <- cumsum(c(0, utils::head(hal, -1))) + mulai + 1
  for (i in seq_along(specs)) {
    sp <- module_spec_from_yaml(specs[i])
    sp$course$halaman_awal <- off[i]
    rnd$render(bangun(sp), out_dirs[i])
  }
  data.frame(spec = basename(specs), hal = hal,
             mulai = off - 1, akhir = off + hal - 2, stringsAsFactors = FALSE)
}

#' Banyaknya halaman sebuah berkas PDF
#'
#' Memakai paket `pdftools` atau `qpdf` bila terpasang, sehingga bekerja juga di
#' Windows tanpa perangkat baris perintah. Bila keduanya tidak ada, fungsi ini
#' memanggil `pdfinfo` dari poppler-utils.
#'
#' @param path path berkas PDF
#' @return integer banyaknya halaman, atau `NA` bila gagal dibaca
#' @export
pdf_halaman <- function(path) {
  if (length(path) != 1L || is.na(path) || !file.exists(path)) return(NA_integer_)
  if (requireNamespace("pdftools", quietly = TRUE)) {
    n <- tryCatch(pdftools::pdf_info(path)$pages, error = function(e) NA_integer_)
    return(as.integer(n))
  }
  if (requireNamespace("qpdf", quietly = TRUE)) {
    n <- tryCatch(qpdf::pdf_length(path), error = function(e) NA_integer_)
    return(as.integer(n))
  }
  if (!nzchar(Sys.which("pdfinfo"))) return(NA_integer_)
  baris <- suppressWarnings(tryCatch(
    system2("pdfinfo", shQuote(path), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)))
  baris <- grep("^Pages:", baris, value = TRUE)
  if (!length(baris)) return(NA_integer_)
  as.integer(sub("^Pages:\\s*(\\d+).*", "\\1", baris[1]))
}

#' Gabungkan beberapa PDF menjadi satu buku
#'
#' Memakai `pdfunite` dari poppler-utils bila tersedia di PATH. Bila tidak ada
#' (umumnya di Windows), fungsi ini memakai paket `qpdf`.
#'
#' @param berkas vektor path PDF sesuai urutan yang diinginkan
#' @param keluaran path berkas hasil
#' @return `keluaran` secara tak terlihat
#' @export
gabung_pdf <- function(berkas, keluaran) {
  ada <- berkas[file.exists(berkas)]
  if (!length(ada)) stop("Tidak ada berkas PDF yang dapat digabungkan.")
  if (nzchar(Sys.which("pdfunite"))) {
    status <- system2("pdfunite", c(shQuote(ada), shQuote(keluaran)))
    if (!identical(as.integer(status), 0L)) {
      stop("pdfunite gagal menggabungkan PDF (status ", status, ").", call. = FALSE)
    }
  } else if (requireNamespace("qpdf", quietly = TRUE)) {
    qpdf::pdf_combine(ada, output = keluaran)
  } else {
    stop("Untuk menggabungkan PDF diperlukan poppler-utils (pdfunite) atau ",
         "paket R 'qpdf'. Pasang salah satunya, misalnya install.packages(\"qpdf\").",
         call. = FALSE)
  }
  invisible(keluaran)
}
