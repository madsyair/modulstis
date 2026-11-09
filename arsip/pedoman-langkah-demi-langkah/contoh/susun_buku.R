# ===========================================================================
# susun_buku.R -- Menyusun buku modul dan buku kunci jawaban satu semester.
# Jalankan dari folder proyek:  Rscript susun_buku.R
# ===========================================================================
suppressMessages(library(modulstis))

# 1. Spesifikasi, terurut menurut nama berkas (nomor dua digit menjaga urutan)
specs <- sort(list.files("spec", "\\.yml$", full.names = TRUE))
dirs  <- file.path("buku", sub("\\.yml$", "", basename(specs)))

susun <- function(jenis) {
  # 2. Render dua tahap dengan nomor halaman berlanjut
  tabel <- render_berlanjut(specs, dirs, jenis = jenis)
  tabel$judul <- vapply(specs, function(f) {
    s <- module_spec_from_yaml(f)
    sprintf("Modul %d  %s", s$number, s$title)
  }, character(1))
  saveRDS(tabel, file.path("buku", sprintf("daftar_%s.rds", jenis)))

  # 3. Bagian awal: sampul buku, kata pengantar, daftar modul
  awal <- sprintf("bagian_awal_%s.pdf", jenis)
  rmarkdown::render("buku/bagian_awal.Rmd", params = list(jenis = jenis),
                    output_file = awal, quiet = TRUE)

  # 4. Gabungkan
  pola <- if (jenis == "kunci") "^Kunci_.*\\.pdf$" else "^Modul_.*\\.pdf$"
  isi  <- vapply(dirs, function(d) list.files(d, pola, full.names = TRUE)[1],
                 character(1))
  keluar <- sprintf("Buku_%s_Pemrograman_Statistika.pdf",
                    if (jenis == "kunci") "Kunci" else "Modul")
  gabung_pdf(c(file.path("buku", awal), isi), keluar)
  message(sprintf("%s: %d halaman", keluar, pdf_halaman(keluar)))
  tabel
}

modul <- susun("modul")
kunci <- susun("kunci")
print(modul[, c("spec", "hal", "mulai", "akhir")])
