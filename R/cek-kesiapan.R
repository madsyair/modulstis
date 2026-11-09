#' Periksa kesiapan komputer untuk merender modul
#'
#' Memeriksa satu per satu perangkat yang diperlukan `modulstis`: versi R,
#' paket R pendukung, XeLaTeX, font Carlito, pola pemenggalan kata bahasa
#' Indonesia, penggabung PDF, dan (opsional) Quarto. Font dan pola pemenggalan
#' diuji dengan benar-benar mengompilasi dokumen LaTeX kecil, sehingga hasilnya
#' berlaku sama di Windows, macOS, dan Linux.
#'
#' @param tampilkan bila `TRUE` (bawaan), cetak laporan ke konsol
#' @return data.frame berkolom `komponen`, `status` (`"OK"`, `"BELUM"`, atau
#'   `"OPSIONAL"`), dan `saran`, secara tak terlihat
#' @examples
#' \dontrun{
#' cek_kesiapan()
#' }
#' @export
cek_kesiapan <- function(tampilkan = TRUE) {
  baris <- list()
  catat <- function(komponen, ok, saran, wajib = TRUE) {
    status <- if (isTRUE(ok)) "OK" else if (wajib) "BELUM" else "OPSIONAL"
    baris[[length(baris) + 1L]] <<- data.frame(
      komponen = komponen, status = status,
      saran = if (isTRUE(ok)) "" else saran, stringsAsFactors = FALSE)
  }

  catat("R versi 4.1 atau lebih baru",
        getRversion() >= "4.1.0",
        "Pasang R terbaru dari https://cran.r-project.org")

  for (p in c("rmarkdown", "knitr", "bookdown")) {
    catat(sprintf("paket R '%s'", p), requireNamespace(p, quietly = TRUE),
          sprintf("install.packages(\"%s\")", p))
  }
  catat("paket R 'pdftools' atau 'qpdf' (buku gabungan)",
        requireNamespace("pdftools", quietly = TRUE) ||
          requireNamespace("qpdf", quietly = TRUE),
        "install.packages(c(\"pdftools\", \"qpdf\"))")

  xe <- Sys.which("xelatex")
  ada_xe <- nzchar(xe)
  catat("XeLaTeX", ada_xe,
        "install.packages(\"tinytex\"); tinytex::install_tinytex(); lalu mulai ulang RStudio")

  if (ada_xe) {
    catat("font Carlito",
          uji_xelatex(xe, c("\\usepackage{fontspec}", "\\setmainfont{Carlito}")),
          "Pasang font Carlito (Windows: klik kanan berkas .ttf, pilih 'Install for all users')")
    catat("pola pemenggalan bahasa Indonesia",
          uji_xelatex(xe, c(
            "\\ifcsname l@indonesian\\endcsname\\else",
            "\\errmessage{pola indonesian tidak ada}\\fi")),
          "tinytex::tlmgr_install(\"hyphen-indonesian\"); Debian/Ubuntu: paket texlive-lang-other")
  } else {
    catat("font Carlito", FALSE, "Pasang XeLaTeX lebih dahulu")
    catat("pola pemenggalan bahasa Indonesia", FALSE, "Pasang XeLaTeX lebih dahulu")
  }

  ada_quarto <- requireNamespace("quarto", quietly = TRUE) &&
    !is.null(tryCatch(quarto::quarto_path(), error = function(e) NULL))
  catat("Quarto (hanya untuk backend \"quarto\")", ada_quarto,
        "Pasang Quarto dari https://quarto.org lalu install.packages(\"quarto\")",
        wajib = FALSE)

  laporan <- do.call(rbind, baris)
  if (isTRUE(tampilkan)) cetak_kesiapan(laporan)
  invisible(laporan)
}

# Mengompilasi dokumen kecil dengan XeLaTeX; TRUE bila PDF terbentuk.
uji_xelatex <- function(xe, preamble) {
  dir <- tempfile("cek_kesiapan_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  tex <- file.path(dir, "uji.tex")
  writeLines(c("\\documentclass{article}", preamble,
               "\\begin{document}uji\\end{document}"), tex)
  # dijalankan dari folder sementara agar berkas sampingan XeLaTeX
  # (mis. missfont.log) tidak tertinggal di direktori kerja pengguna
  lama <- setwd(dir)
  on.exit(setwd(lama), add = TRUE, after = FALSE)
  suppressWarnings(tryCatch(
    system2(xe, c("-interaction=nonstopmode", "-halt-on-error", "uji.tex"),
            stdout = FALSE, stderr = FALSE),
    error = function(e) 1L))
  file.exists(file.path(dir, "uji.pdf"))
}

cetak_kesiapan <- function(laporan) {
  tanda <- c(OK = "[OK]   ", BELUM = "[BELUM]", OPSIONAL = "[ - ]  ")
  cat("Kesiapan komputer untuk modulstis\n")
  for (i in seq_len(nrow(laporan))) {
    cat(tanda[[laporan$status[i]]], laporan$komponen[i], "\n")
    if (nzchar(laporan$saran[i])) cat("          saran:", laporan$saran[i], "\n")
  }
  n_belum <- sum(laporan$status == "BELUM")
  if (n_belum == 0) {
    cat("Semua komponen wajib siap. Anda dapat merender modul.\n")
  } else {
    cat(sprintf("%d komponen wajib belum siap. Ikuti saran di atas, lalu jalankan ulang.\n",
                n_belum))
  }
  invisible(laporan)
}
