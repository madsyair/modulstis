# Pembantu bersama untuk semua bab. Disisipkan di awal setiap bab dengan
# chunk tersembunyi:  source("_setup.R")
#
# Kode yang memanggil render modul tidak dapat dijalankan langsung di dalam knitr,
# karena paket sendiri memanggil rmarkdown/knitr (render bersarang). Karena itu
# chunk berlabel engine `rproyek` dijalankan di proses Rscript terpisah. Objek dan
# paket yang dimuat disimpan ke berkas sesi per bab, sehingga chunk-chunk dalam
# satu bab berperilaku seperti satu sesi R yang berlanjut.

suppressPackageStartupMessages(library(modulstis))
`%||%` <- function(a, b) if (is.null(a)) b else a
Sys.setenv(LANG = "C.UTF-8", LC_ALL = "C.UTF-8")

PEDOMAN <- normalizePath(".", winslash = "/")
KERJA   <- file.path(PEDOMAN, "_kerja")
PROYEK  <- file.path(KERJA, "pemrograman-statistika")
HASIL   <- file.path(PEDOMAN, "gambar", "hasil")
dir.create(KERJA, showWarnings = FALSE)
dir.create(HASIL, showWarnings = FALSE, recursive = TRUE)

BAB   <- tools::file_path_sans_ext(basename(knitr::current_input() %||% "lepas"))
SESI  <- file.path(KERJA, paste0("sesi-", BAB, ".rds"))
unlink(SESI)

# ---- menjalankan kode R di proses terpisah ----------------------------------
.skrip_anak <- '
local({
  kode  <- readLines(Sys.getenv("ANAK_KODE"), warn = FALSE, encoding = "UTF-8")
  keluar <- Sys.getenv("ANAK_KELUAR"); sesi <- Sys.getenv("ANAK_SESI")
  wd <- Sys.getenv("ANAK_WD")
  setwd(wd)
  options(width = 72, warn = 1)
  if (file.exists(sesi)) {
    s <- readRDS(sesi)
    for (p in rev(s$pkgs)) suppressPackageStartupMessages(
      library(p, character.only = TRUE))
    list2env(s$obj, globalenv())
  }
  res <- evaluate::evaluate(paste(kode, collapse = "\n"), envir = globalenv(),
                            stop_on_error = 0L, new_device = TRUE)
  pref <- function(x) {
    x <- sub("\\n$", "", x)
    if (!nzchar(x)) return(character(0))
    paste0("#> ", strsplit(x, "\\n")[[1]])
  }
  baris <- character(0)
  for (r in res) {
    if (inherits(r, "source")) {
      baris <- c(baris, sub("\\n$", "", r$src))
    } else if (is.character(r)) {
      baris <- c(baris, pref(r))
    } else if (inherits(r, "error")) {
      baris <- c(baris, pref(paste0("Error: ", conditionMessage(r))))
    } else if (inherits(r, "warning")) {
      baris <- c(baris, pref(paste0("Warning: ", conditionMessage(r))))
    } else if (inherits(r, "message")) {
      baris <- c(baris, pref(conditionMessage(r)))
    }
  }
  writeLines(baris, keluar, useBytes = TRUE)
  pk <- sub("^package:", "", grep("^package:", search(), value = TRUE))
  pk <- setdiff(pk, c("stats", "graphics", "grDevices", "utils", "datasets",
                      "methods", "base"))
  obj <- mget(ls(globalenv(), all.names = FALSE), envir = globalenv())
  saveRDS(list(pkgs = pk, obj = obj, wd = getwd()), sesi)
  
})
'
.berkas_anak <- file.path(KERJA, "anak.R")
writeLines(.skrip_anak, .berkas_anak)

jalankan <- function(kode, wd = PROYEK, sesi = SESI) {
  dir.create(wd, showWarnings = FALSE, recursive = TRUE)
  fk <- tempfile(fileext = ".R"); fo <- tempfile(fileext = ".txt")
  writeLines(kode, fk, useBytes = TRUE)
  # Jalur diteruskan lewat variabel lingkungan, bukan argumen, agar
  # commandArgs(TRUE) di proses anak kosong seperti di Console RStudio.
  status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(.berkas_anak),
                    env = c(sprintf("ANAK_KODE=%s", shQuote(fk)),
                            sprintf("ANAK_KELUAR=%s", shQuote(fo)),
                            sprintf("ANAK_SESI=%s", shQuote(sesi)),
                            sprintf("ANAK_WD=%s", shQuote(wd))),
                    stdout = TRUE, stderr = TRUE)
  if (!file.exists(fo)) stop("Proses anak gagal:\n", paste(status, collapse = "\n"))
  hasil <- readLines(fo, warn = FALSE, encoding = "UTF-8")
  # catatan untuk penelusuran saat membangun buku
  cat(c(sprintf("== %s (%s)", BAB, wd), hasil, status, ""),
      file = file.path(KERJA, "log-chunk.txt"), sep = "\n", append = TRUE)
  # Peringatan logger ditulis ke stderr (merah di Console RStudio); simpan
  # terpisah agar dapat ditampilkan bila diminta chunk (opsi stderr: true).
  attr(hasil, "stderr") <- grep("^(WARN|ERROR|FATAL) |^Quitting from", status, value = TRUE)
  hasil
}

knitr::knit_engines$set(rproyek = function(options) {
  kode <- options$code
  if (!isFALSE(options$eval)) {
    wd <- options$wd %||% PROYEK
    hasil <- jalankan(kode, wd = wd)
    if (isTRUE(options$stderr)) {
      hasil <- c(hasil, paste0("#> ", attr(hasil, "stderr")))
    }
  } else {
    hasil <- kode
  }
  if (isFALSE(options$echo)) {
    hasil <- grep("^#> ", hasil, value = TRUE)
  }
  if (!is.null(options$tampil)) hasil <- hasil[eval(parse(text = options$tampil))]
  if (isFALSE(options$include)) return("")
  paste0("\n```r\n", paste(hasil, collapse = "\n"), "\n```\n")
})

# ---- contoh berjalan ---------------------------------------------------------
# Membuat proyek contoh berjalan bila belum ada (Bab 3), sehingga setiap bab
# dapat dirender sendiri-sendiri.
pastikan_proyek <- function() {
  if (!dir.exists(PROYEK)) {
    jalankan(c(
      'library(modulstis)',
      'buat_proyek_modul("pemrograman-statistika",',
      '  matkul = "Pemrograman Statistika", kode = "K242310",',
      '  prodi = "D-IV Statistika", semester = "3 (Ganjil)",',
      '  penyusun = "Achmad Syahrul Choir", n_modul = 14)'),
      wd = KERJA, sesi = tempfile(fileext = ".rds"))
  }
  invisible(PROYEK)
}

# Memasang spesifikasi lengkap Modul 7 ke folder spec/ proyek.
SPEC7_CONTOH <- file.path(PEDOMAN, "contoh", "modul-07-deskriptif.yml")
pasang_modul7 <- function() {
  pastikan_proyek()
  file.copy(SPEC7_CONTOH, file.path(PROYEK, "spec", "modul-07-deskriptif.yml"),
            overwrite = TRUE)
  invisible(TRUE)
}

# Mencetak isi berkas sebagai blok kode (chunk dengan output: asis).
tampil_berkas <- function(path, bahasa = "yaml", baris = NULL, nomor = FALSE) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!is.null(baris)) x <- x[baris]
  # Empat backtick: isi berkas boleh memuat blok kode bertiga backtick
  # (mis. chunk R Markdown) tanpa menutup bingkai ini terlalu awal.
  # nomor = TRUE mencetak nomor baris (dipakai untuk kode sumber di lampiran).
  if (nomor) {
    # Geser kode ke kanan supaya nomor baris berada di dalam kotak kode
    cat("\n```{=latex}\n\\fvset{xleftmargin=2.4em, numbersep=0.7em}\n```\n")
    cat(sprintf("\n````{.%s .numberLines}\n", bahasa))
    on.exit(cat("\n```{=latex}\n\\fvset{xleftmargin=0pt, numbersep=12pt}\n```\n\n"), add = TRUE)
  } else {
    cat(sprintf("\n````%s\n", bahasa))
  }
  cat(x, sep = "\n")
  cat("\n````\n\n")
}

# Nomor baris dari pola `dari` sampai sebelum
# pola `sampai`. inklusif = TRUE ikut menyertakan baris `sampai`; sebelum = k
# menambahkan k baris di atas baris `dari`.
baris_dari <- function(path, dari, sampai = NULL, inklusif = FALSE, sebelum = 0) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  a <- grep(dari, x)[1]
  if (is.na(a)) stop("Pola '", dari, "' tidak ditemukan")
  if (is.null(sampai)) {
    b <- length(x)
  } else {
    j <- grep(sampai, x); j <- j[j > a][1]
    b <- if (inklusif) j else j - 1
  }
  seq(a - sebelum, b)
}

# Nomor halaman pertama PDF yang memuat pola teks tertentu.
cari_halaman <- function(pdf, pola) {
  teks <- pdftools::pdf_text(pdf)
  i <- grep(pola, teks)
  if (!length(i)) stop("Pola '", pola, "' tidak ditemukan di ", basename(pdf))
  i[1]
}

# Mengubah halaman PDF menjadi PNG untuk ditampilkan di buku.
halaman_png <- function(pdf, halaman, nama, dpi = 110) {
  keluar <- file.path(HASIL, sprintf("%s-%02d.png", nama, halaman))
  pdftools::pdf_convert(pdf, format = "png", pages = halaman, dpi = dpi,
                        filenames = keluar, verbose = FALSE)
  # bingkai tipis agar tepi halaman putih terlihat di atas kertas putih
  img <- png::readPNG(keluar)
  t <- 3; warna <- c(0x9D, 0xB4, 0xCF) / 255
  for (k in 1:3) {
    img[c(1:t, (dim(img)[1] - t + 1):dim(img)[1]), , k] <- warna[k]
    img[, c(1:t, (dim(img)[2] - t + 1):dim(img)[2]), k] <- warna[k]
  }
  png::writePNG(img, keluar)
  keluar
}

# Merender satu spesifikasi di proses terpisah tanpa menampilkan log.
render_diam <- function(spec_path, output_dir, backend = "bookdown") {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  jalankan(c(
    'suppressPackageStartupMessages(library(modulstis))',
    sprintf('invisible(capture.output(h <- render_module(module_spec_from_yaml("%s"), backend = "%s", output_dir = ".")))',
            spec_path, backend)),
    wd = output_dir, sesi = tempfile(fileext = ".rds"))
  num <- module_spec_from_yaml(spec_path)$number
  list(modul = list(path = list.files(file.path(output_dir, sprintf("modul-%02d", num)),
                                      "^Modul_.*\\.pdf$", full.names = TRUE)[1]),
       kunci = list(path = list.files(file.path(output_dir, sprintf("kunci-%02d", num)),
                                      "^Kunci_.*\\.pdf$", full.names = TRUE)[1]))
}
