test_that("cek_kesiapan mengembalikan laporan berstruktur tetap", {
  lap <- cek_kesiapan(tampilkan = FALSE)
  expect_s3_class(lap, "data.frame")
  expect_named(lap, c("komponen", "status", "saran"))
  expect_true(all(lap$status %in% c("OK", "BELUM", "OPSIONAL")))
  expect_true(any(grepl("XeLaTeX", lap$komponen)))
  # saran hanya diisi untuk komponen yang belum siap
  expect_true(all(lap$saran[lap$status == "OK"] == ""))
})

test_that("uji_xelatex membedakan font yang ada dan yang tidak ada", {
  xe <- Sys.which("xelatex")
  skip_if_not(nzchar(xe))
  expect_false(modulstis:::uji_xelatex(xe, c("\\usepackage{fontspec}",
                                             "\\setmainfont{FontYangTidakAdaSama-Sekali}")))
  expect_true(modulstis:::uji_xelatex(xe, character(0)))
})

test_that("cetak_kesiapan menyebut komponen yang belum siap", {
  lap <- data.frame(komponen = c("A", "B"), status = c("OK", "BELUM"),
                    saran = c("", "pasang B"), stringsAsFactors = FALSE)
  out <- capture.output(cetak_kesiapan(lap))
  expect_true(any(grepl("pasang B", out)))
  expect_true(any(grepl("1 komponen wajib belum siap", out)))
})
