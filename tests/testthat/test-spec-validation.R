test_that("spec valid lolos validasi", {
  spec <- module_spec(number = 5, title = "One-way MANOVA",
                      exercises = list(list(id = "L5.1", points = 20)))
  rep <- spec$validate()
  expect_true(rep$ok)
})

test_that("spec menolak nomor di luar rentang", {
  spec <- module_spec(number = 200, title = "X")
  expect_false(spec$validate()$ok)
})

test_that("spec menolak jenis bagian tak dikenal", {
  spec <- module_spec(number = 1, title = "X",
    sections = list(list(id = "a", type = "tidak_ada", title = "A")))
  rep <- spec$validate()
  expect_false(rep$ok)
  expect_true(any(grepl("tidak dikenal", rep$messages)))
})

test_that("exercises tanpa points ditolak", {
  spec <- module_spec(number = 1, title = "X",
    exercises = list(list(id = "L1.1")))
  rep <- spec$validate()
  expect_false(rep$ok)
  expect_true(any(grepl("points hilang", rep$messages)))
})

test_that("default_sections berjumlah 11 (termasuk tambahan opsional) dan id unik", {
  s <- default_sections()
  expect_length(s, 11)
  ids0 <- vapply(s, function(x) x$id, character(1))
  expect_true("tambahan" %in% ids0)
  ids <- vapply(s, function(x) x$id, character(1))
  expect_equal(anyDuplicated(ids), 0L)
})
