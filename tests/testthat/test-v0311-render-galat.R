# Uji regresi 0.3.11: kode contoh yang galat tidak boleh menghasilkan PDF berisi
# isi render sebelumnya.

spec_dengan_kode <- function(kode) {
  module_spec(7, "Uji Render Galat", short_code = "uji",
    course = list(matkul = "Uji", kode = "K0", prodi = "Uji", penyusun = "Penguji"),
    body = list(contoh = list(list(contoh = "Satu contoh", judul_r = "kode",
                                   kode_r = kode, eval = TRUE))))
}

test_that("kode contoh yang galat menghentikan render dan tidak memakai .tex lama", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("xelatex")))
  skip_if_not(requireNamespace("rmarkdown", quietly = TRUE))
  out <- file.path(tempdir(), "uji-render-galat")
  unlink(out, recursive = TRUE)
  th <- theme_factory()
  rnd <- renderer_factory("bookdown", theme = th,
                          logger = build_logger(console_level = "fatal"))

  ok <- ModuleBuilder$new(th)$build(spec_dengan_kode("cat('PENANDA_LAMA')"))
  a <- suppressWarnings(rnd$render(ok, out))
  expect_true(file.exists(a$path))

  rusak <- ModuleBuilder$new(th)$build(spec_dengan_kode("stop('galat sengaja')"))
  expect_error(suppressWarnings(rnd$render(rusak, out)), "galat sengaja")
  expect_false(file.exists(file.path(out, "Modul_07_uji.pdf")))
})

test_that("galat LaTeX pada berkas log dilaporkan sebagai peringatan", {
  log <- tempfile(fileext = ".log")
  writeLines(c("This is XeTeX", "! Missing $ inserted.", "<inserted text> ",
               "                $", "l.448 Data disimpan di data_", "",
               "! Missing $ inserted."), log)
  logf <- tempfile(fileext = ".log")
  lg <- build_logger(console_level = "fatal", logfile = logf)
  rnd <- renderer_factory("bookdown", theme = theme_factory(), logger = lg)
  priv <- rnd$.__enclos_env__$private
  expect_equal(priv$laporkan_galat_latex(log, 7), "Missing $ inserted.")
  catatan <- readLines(logf)
  expect_true(any(grepl("LaTeX melaporkan galat", catatan)))
  expect_true(any(grepl("l.448 Data disimpan di data_", catatan, fixed = TRUE)))
  expect_true(any(grepl("jumlah=2", catatan, fixed = TRUE)))

  bersih <- tempfile(fileext = ".log")
  writeLines(c("This is XeTeX", "Output written on x.pdf"), bersih)
  expect_length(priv$laporkan_galat_latex(bersih, 7), 0)
})

test_that("render_berlanjut membangkitkan data sebelum merender", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("xelatex")))
  skip_if_not(requireNamespace("rmarkdown", quietly = TRUE))
  skip_if_not(requireNamespace("pdftools", quietly = TRUE) ||
              requireNamespace("qpdf", quietly = TRUE))
  dir <- file.path(tempdir(), "uji-berlanjut")
  unlink(dir, recursive = TRUE); dir.create(dir)
  yml <- file.path(dir, "m.yml")
  writeLines(c('number: 7', 'title: "Uji"', 'short_code: "uji"',
    'course: {matkul: "Uji", kode: "K0", prodi: "Uji", penyusun: ["P"]}',
    'datasets:', '  - name: d', '    recipe: {kind: tabular, "n": 5, seed: 1,',
    '             columns: {x: {type: numeric, min: 0, max: 1}}}',
    'body:', '  contoh:', '    - contoh: "baca"', '      judul_r: "baca"',
    '      kode_r: "nrow(read.csv(\'data/d.csv\'))"', '      eval: true'), yml)
  hasil <- suppressWarnings(render_berlanjut(yml, file.path(dir, "out"), jenis = "modul"))
  expect_true(file.exists(file.path(dir, "out", "data", "d.csv")))
  expect_true(hasil$hal[1] > 0)
})
