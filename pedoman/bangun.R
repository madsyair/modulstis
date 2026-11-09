# ===========================================================================
# bangun.R -- Membangun Buku Pedoman modulstis dan memasangnya ke paket.
#
# Jalankan dari folder pedoman/:   Rscript bangun.R
#
# Prasyarat: modulstis versi terbaru sudah terpasang (R CMD INSTALL ..),
# Quarto, XeLaTeX, font Carlito dan DejaVu Sans Mono, pdftools, qpdf, dan
# serta dplyr dan tidyr (dipakai spesifikasi bawaan Modul 5).
# ===========================================================================
Sys.setenv(LANG = "C.UTF-8", LC_ALL = "C.UTF-8")

status <- system2("quarto", c("render", "--to", "pdf"))
if (!identical(as.integer(status), 0L)) stop("quarto render gagal")

asal <- file.path("_book", "Pedoman_modulstis.pdf")
tujuan <- file.path("..", "inst", "pedoman", "Pedoman_modulstis.pdf")
file.copy(asal, tujuan, overwrite = TRUE)

# Padatkan supaya ukuran paket tetap kecil. Memerlukan Ghostscript atau qpdf.
ukuran_awal <- file.size(tujuan)
tools::compactPDF(tujuan, gs_quality = if (nzchar(tools::find_gs_cmd())) "ebook" else "none")
message(sprintf("Pedoman_modulstis.pdf: %d halaman, %.1f MB (sebelum dipadatkan %.1f MB)",
                modulstis::pdf_halaman(tujuan), file.size(tujuan) / 1e6, ukuran_awal / 1e6))
