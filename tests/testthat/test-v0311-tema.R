test_that("palet tema diterapkan ke preamble", {
  th <- LatexTheme$new(palette = list(navy = "#5B2C6F", oranye = "d35400"))
  p <- th$preamble(7, "Uji")
  expect_true(grepl("\\definecolor{bpsnavy}{HTML}{5B2C6F}", p, fixed = TRUE))
  expect_true(grepl("\\definecolor{bpsoranye}{HTML}{D35400}", p, fixed = TRUE))
  # warna yang tidak disebut tetap bawaan
  expect_true(grepl("\\definecolor{bpsbiru}{HTML}{0B6FB4}", p, fixed = TRUE))
})

test_that("tema bawaan tidak mengubah warna templat", {
  p <- theme_factory()$preamble(1, "Uji")
  for (w in c("123A6B", "0B6FB4", "6FB3E0", "F58220", "00A651", "45505C")) {
    expect_true(grepl(w, p, fixed = TRUE))
  }
  expect_true(grepl("\\setmainfont{Carlito}", p, fixed = TRUE))
})

test_that("font tema menggantikan Carlito", {
  p <- theme_factory(font = "DejaVu Sans")$preamble(1, "Uji")
  expect_true(grepl("\\setmainfont{DejaVu Sans}", p, fixed = TRUE))
  expect_true(grepl("\\setsansfont{DejaVu Sans}", p, fixed = TRUE))
  expect_false(grepl("Carlito", p, fixed = TRUE))
})

test_that("warna dan font yang tidak sah ditolak", {
  expect_error(LatexTheme$new(palette = list(biru = "biru"))$preamble(1, "x"),
               "heksadesimal")
  expect_error(LatexTheme$new(font = ""), "font")
})
