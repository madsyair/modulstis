test_that("RenderContext menomori contoh & kode berurutan", {
  ctx <- RenderContext$new(number = 14)
  ctx$emit_contoh("A"); ctx$emit_contoh("B")
  ctx$emit_kode("K1")
  expect_equal(ctx$counter("contoh"), 2L)
  expect_equal(ctx$counter("kode"), 1L)
})

test_that("LatexTheme menghasilkan preamble dengan nomor & topik", {
  theme <- theme_factory("bps")
  pre <- theme$preamble(7, "MANCOVA", variant = "modul")
  expect_true(grepl("\\\\newcommand\\{\\\\nomormodul\\}\\{7\\}", pre))
  expect_true(grepl("MANCOVA", pre))
})

test_that("varian kunci mewarnai sampul hijau", {
  theme <- theme_factory("bps")
  pre <- theme$preamble(7, "MANCOVA", variant = "kunci")
  expect_true(grepl("bpshijau!75", pre))
  expect_true(grepl("Kunci Modul", pre))
})

test_that("kotak menghasilkan environment yang benar", {
  theme <- theme_factory("bps")
  box <- theme$box("interpretasi", "isi", title = "Interpretasi")
  expect_true(grepl("\\\\begin\\{kotakinterpretasi\\}", box))
  expect_true(grepl("\\\\end\\{kotakinterpretasi\\}", box))
})

test_that("cover meng-escape ampersand", {
  theme <- theme_factory("bps")
  cov <- theme$cover(1, "A & B", "Pertemuan 1", "sub")
  expect_false(grepl("(?<!\\\\)&", cov, perl = TRUE))
})

test_that("ModuleBuilder & AnswerKeyBuilder menghasilkan Document", {
  spec <- module_spec(number = 3, title = "Inferensia",
    exercises = list(list(id = "L3.1", points = 20, solution = "jawab")))
  theme <- theme_factory("bps")
  dm <- ModuleBuilder$new(theme)$build(spec)
  dk <- AnswerKeyBuilder$new(theme)$build(spec)
  expect_s3_class(dm, "Document")
  expect_equal(dm$kind, "modul")
  expect_equal(dk$kind, "kunci")
  expect_true(grepl("kotakkunci", dk$body))
})

test_that("renderer_factory memilih strategi yang benar", {
  theme <- theme_factory("bps")
  expect_s3_class(renderer_factory("bookdown", theme), "BookdownRenderer")
  expect_s3_class(renderer_factory("quarto", theme), "QuartoRenderer")
})
