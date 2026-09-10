## ----include=FALSE------------------------------------------------------------
knitr::opts_chunk$set(eval = FALSE, comment = "#>")

## -----------------------------------------------------------------------------
#  library(modulstis)
#  
#  ps4 <- ModuleProject$new(
#    specs_dir  = system.file("specs_ps", package = "modulstis"),
#    theme      = "bps",
#    backend    = "bookdown",
#    output_dir = "build_ps_d4"
#  )
#  
#  ps4$validate_all()   # 14 spesifikasi divalidasi lebih dahulu (fail-fast agregat)
#  ps4$generate_data()  # berkas CSV data simulasi untuk tiap modul
#  ps4$render_all()     # 14 modul + 14 kunci

## -----------------------------------------------------------------------------
#  spec4 <- module_spec_from_yaml(
#    system.file("specs_ps/modul-03-pemrograman-r.yml", package = "modulstis")
#  )
#  c(spec4$number, spec4$course$prodi)
#  #> [1] "3" "D-IV Statistika"
#  
#  hasil4 <- render_module(spec4, backend = "bookdown", theme = "bps",
#                          output_dir = "build_ps_d4")
#  hasil4$modul$path
#  #> [1] "build_ps_d4/modul-03/Modul_03_pemrograman_r.pdf"   (29 halaman)
#  hasil4$kunci$path
#  #> [1] "build_ps_d4/kunci-03/Kunci_03_pemrograman_r.pdf"   (6 halaman)

## -----------------------------------------------------------------------------
#  ps3 <- ModuleProject$new(
#    specs_dir  = system.file("specs_d3", package = "modulstis"),
#    theme      = "bps",
#    backend    = "quarto",          # <- satu-satunya perbedaan
#    output_dir = "build_ps_d3"
#  )
#  
#  ps3$validate_all()
#  ps3$generate_data()
#  ps3$render_all()

## -----------------------------------------------------------------------------
#  spec3 <- module_spec_from_yaml(
#    system.file("specs_d3/modul-02-dasar.yml", package = "modulstis")
#  )
#  spec3$course$prodi
#  #> [1] "D-III Statistika"
#  
#  hasil3 <- render_module(spec3, backend = "quarto", theme = "bps",
#                          output_dir = "build_ps_d3")
#  list.files("build_ps_d3/modul-02")
#  #> [1] "data" "Modul_02_dasar_r_python.pdf" "Modul_02_dasar_r_python.qmd" "preamble.tex"

## -----------------------------------------------------------------------------
#  spec <- module_spec_from_yaml(
#    system.file("specs_d3/modul-02-dasar.yml", package = "modulstis")
#  )
#  q <- render_module(spec, backend = "quarto",   output_dir = "cek_q")
#  b <- render_module(spec, backend = "bookdown", output_dir = "cek_b")
#  
#  sapply(c(quarto = q$modul$path, bookdown = b$modul$path),
#         function(f) pdftools::pdf_info(f)$pages)
#  #>   quarto bookdown
#  #>       34       31

## -----------------------------------------------------------------------------
#  ps4$build_books(bookmarks = TRUE,
#                  front_matter = list(cover = TRUE, copyright = TRUE,
#                                      preface = TRUE, toc = TRUE))
#  #> build_ps_d4/Buku_Modul_Praktikum_PS_D4.pdf
#  #> build_ps_d4/Buku_Kunci_Jawaban_PS_D4.pdf

## -----------------------------------------------------------------------------
#  ctx <- RenderContext$new(number = 4)
#  
#  # dianjurkan: rumus ditulis sebagai matematika
#  ctx$emit_kode("Arah pembeda $\\mathbf{S}_p^{-1}(\\bar{x}_1 - \\bar{x}_2)$")
#  
#  # tetap aman: karakter khusus di luar $...$ diloloskan sendiri oleh paket
#  ctx$emit_contoh("50% amatan pada data_baku & pola ~x")

