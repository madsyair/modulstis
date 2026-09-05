test_that("generate_dataset mvn menghasilkan ukuran benar", {
  df <- generate_dataset(list(kind = "mvn", vars = c("A", "B"), n = 30, seed = 1))
  expect_equal(nrow(df), 30)
  expect_equal(names(df), c("A", "B"))
})

test_that("grouped_mvn menghasilkan kolom kelompok", {
  df <- generate_dataset(list(kind = "grouped_mvn",
    vars = c("X", "Y"),
    groups = list(G1 = 10, G2 = 12),
    seed = 1))
  expect_true("kelompok" %in% names(df))
  expect_equal(nrow(df), 22)
  expect_equal(nlevels(df$kelompok), 2)
})

test_that("recipe.kind tak dikenal memicu galat", {
  expect_error(generate_dataset(list(kind = "aneh")), "tidak dikenal")
})

test_that("data deterministik dengan seed sama", {
  r <- list(kind = "mvn", vars = c("A"), n = 5, seed = 42)
  expect_equal(generate_dataset(r), generate_dataset(r))
})
