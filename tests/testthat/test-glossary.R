test_that("bank istilah termuat dan berisi banyak istilah", {
  g <- load_glossary()
  expect_gt(length(g), 30)
  expect_true(all(vapply(g, function(t) !is.null(t$istilah), logical(1))))
})

test_that("sebagian istilah memiliki catatan KBBI", {
  g <- load_glossary()
  n_kbbi <- sum(vapply(g, function(t) !is.null(t$kbbi), logical(1)))
  expect_gt(n_kbbi, 10)
})

test_that("filter_glossary menyertakan 'umum' dan topik terpilih", {
  g <- load_glossary()
  f <- filter_glossary(g, topics = "Modul 13")
  topics <- vapply(f, function(t) t$topik %||% "umum", character(1))
  expect_true(all(topics %in% c("umum", "Modul 13")))
  expect_true("umum" %in% topics)
})

test_that("glossary_latex menghasilkan perintah LaTeX yang benar", {
  g <- load_glossary()
  lat <- glossary_latex(g)
  expect_true(grepl("\\\\istilahitem", lat))
  expect_true(grepl("\\\\istilahkbbi", lat))
  expect_true(grepl("kotakistilah", lat))
})

test_that("GlossarySection ter-render tanpa konten (pakai bank bawaan)", {
  sec <- make_section(list(id = "istilah", type = "glossary",
                           title = "Daftar Istilah"))
  expect_s3_class(sec, "GlossarySection")
  ctx <- RenderContext$new(0)
  body <- sec$render(ctx)
  expect_true(grepl("istilahitem", body))
})

test_that("'glossary' termasuk jenis bagian yang dikenal", {
  expect_true("glossary" %in% section_types())
})
