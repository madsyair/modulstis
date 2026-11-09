# Uji regresi 0.3.11: menghitung dan menggabung PDF tanpa perintah shell khusus Unix

buat_pdf <- function(n) {
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  for (i in seq_len(n)) graphics::plot.new()
  grDevices::dev.off()
  f
}

test_that("pdf_halaman menghitung halaman dan mengembalikan NA untuk berkas tak ada", {
  skip_if_not(requireNamespace("pdftools", quietly = TRUE) ||
              requireNamespace("qpdf", quietly = TRUE) ||
              nzchar(Sys.which("pdfinfo")))
  f <- buat_pdf(3)
  expect_identical(pdf_halaman(f), 3L)
  expect_identical(pdf_halaman(tempfile(fileext = ".pdf")), NA_integer_)
})

test_that("gabung_pdf menghasilkan PDF berisi jumlah halaman gabungan", {
  skip_if_not(nzchar(Sys.which("pdfunite")) || requireNamespace("qpdf", quietly = TRUE))
  skip_if_not(requireNamespace("pdftools", quietly = TRUE) ||
              requireNamespace("qpdf", quietly = TRUE))
  a <- buat_pdf(2); b <- buat_pdf(3)
  out <- tempfile(fileext = ".pdf")
  gabung_pdf(c(a, b), out)
  expect_true(file.exists(out))
  expect_identical(pdf_halaman(out), 5L)
})

test_that("gabung_pdf menolak daftar berkas yang semuanya tidak ada", {
  expect_error(gabung_pdf(tempfile(fileext = ".pdf"), tempfile(fileext = ".pdf")),
               "Tidak ada berkas PDF")
})
