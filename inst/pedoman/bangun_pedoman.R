# ============================================================================
# bangun_pedoman.R -- Membangun ulang Buku Pedoman modulstis dari sumbernya.
#
# Cara pakai (dari folder ini):
#   Rscript bangun_pedoman.R
#
# Prasyarat: R dengan rmarkdown, XeLaTeX, font Carlito, dan poppler-utils.
#
# CATATAN PENOMORAN
# Setiap preamble_pedoman*.tex memuat \setcounter{page}{N} dan
# \setcounter{section}{N} agar nomor halaman dan nomor bab berlanjut
# antar-bagian. Bila panjang salah satu bagian berubah, jalankan skrip ini
# dengan argumen 'hitung' untuk menghitung ulang offsetnya.
# ============================================================================

bagian <- sprintf("bagian_%d.Rmd", 0:6)

render_semua <- function() {
  for (f in bagian) {
    message("Merender ", f, " ...")
    rmarkdown::render(f, quiet = TRUE)
  }
}

hitung_offset <- function() {
  pdf <- sprintf("bagian_%d.pdf", 1:5)          # bagian isi (tanpa awal/akhir)
  hal <- vapply(pdf, function(f) {
    as.integer(sub(".*?(\\d+).*", "\\1",
      system(sprintf("pdfinfo %s | grep Pages", shQuote(f)), intern = TRUE)))
  }, integer(1))
  off <- cumsum(c(1, utils::head(hal, -1)))
  akhir <- off[length(off)] + hal[length(hal)]
  message("Halaman tiap bagian : ", paste(hal, collapse = ", "))
  message("Offset yang benar   : ", paste(off, collapse = ", "))
  message("Bagian akhir mulai  : ", akhir)
  message("\nSetel nilai tersebut pada \\setcounter{page}{} di tiap preamble, ",
          "lalu jalankan ulang.")
  invisible(list(hal = hal, off = off, akhir = akhir))
}

gabung <- function(keluaran = "Pedoman_modulstis.pdf") {
  pdf <- sprintf("bagian_%d.pdf", 0:6)
  ada <- pdf[file.exists(pdf)]
  system2("pdfunite", c(shQuote(ada), shQuote(keluaran)))
  message("Buku tersusun: ", keluaran, " (",
          as.integer(sub(".*?(\\d+).*", "\\1",
            system(sprintf("pdfinfo %s | grep Pages", shQuote(keluaran)),
                   intern = TRUE))), " halaman)")
}

# Buku tinggal di inst/pedoman/ (bukan vignettes/), sehingga ukurannya tidak lagi
# diperiksa `R CMD check`. Pemadatan tetap dilakukan agar paket terpasang ringan.
padatkan <- function(berkas = "Pedoman_modulstis.pdf") {
  if (!file.exists(berkas)) return(invisible(NULL))
  sebelum <- file.size(berkas)
  tools::compactPDF(berkas, gs_quality = "ebook")
  sesudah <- file.size(berkas)
  message(sprintf("PDF dipadatkan: %.0f Kb -> %.0f Kb", sebelum / 1024, sesudah / 1024))
  invisible(c(sebelum = sebelum, sesudah = sesudah))
}

bersihkan <- function() {
  unlink(c(sprintf("bagian_%d.pdf", 0:6), sprintf("bagian_%d.log", 0:6),
           sprintf("bagian_%d.tex", 0:6)))
}

arg <- commandArgs(trailingOnly = TRUE)
if (length(arg) && arg[1] == "hitung") {
  hitung_offset()
} else {
  render_semua()
  gabung()
  padatkan()
  bersihkan()
}
