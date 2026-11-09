# Dijalankan Quarto sebelum merender buku (pre-render).
# 1. Menulis nomor versi modulstis yang terpasang ke tex/versi.tex.
# 2. Mengosongkan folder kerja _kerja/ agar setiap pembangunan buku dimulai bersih.
versi <- as.character(utils::packageVersion("modulstis"))
writeLines(sprintf("\\newcommand{\\versimodulstis}{%s}", versi), "tex/versi.tex")
if (identical(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"), "1")) {
  unlink("_kerja", recursive = TRUE)
  unlink("gambar/hasil", recursive = TRUE)
}
dir.create("_kerja", showWarnings = FALSE)
dir.create("gambar/hasil", showWarnings = FALSE, recursive = TRUE)
