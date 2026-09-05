# Uji regresi bagi perbaikan pada versi 0.3.1

test_that("penanda datatable.aware tersedia di dalam paket", {
  # Tanpa penanda ini, sintaks data.table gagal saat render dipanggil
  # dari dalam paket (galat: could not find function "." )
  expect_true(exists(".datatable.aware", envir = asNamespace("modulstis"),
                     inherits = FALSE))
  expect_true(get(".datatable.aware", envir = asNamespace("modulstis")))
})

test_that("preamble memilih pola pemenggalan bahasa Indonesia", {
  teks <- paste(readLines(
    system.file("templates", "preamble.tex.tmpl", package = "modulstis"),
    warn = FALSE), collapse = "\n")
  # Dipilih langsung, tanpa polyglossia maupun babel, agar tidak menambah
  # ketergantungan dan tidak mengubah penamaan bagian.
  expect_match(teks, "l@indonesian", fixed = TRUE)
  expect_false(grepl("polyglossia", teks, fixed = TRUE))
})

test_that("pemenggalan ditetapkan sebelum pemilihan font", {
  tmpl <- readLines(
    system.file("templates", "preamble.tex.tmpl", package = "modulstis"),
    warn = FALSE)
  baris_bahasa <- grep("l@indonesian", tmpl, fixed = TRUE)[1]
  baris_font   <- grep("setmainfont", tmpl, fixed = TRUE)[1]
  expect_false(is.na(baris_bahasa))
  expect_false(is.na(baris_font))
  expect_lt(baris_bahasa, baris_font)
})

test_that("lebar nomor daftar isi cukup bagi modul dua digit", {
  teks <- paste(readLines(
    system.file("templates", "preamble.tex.tmpl", package = "modulstis"),
    warn = FALSE), collapse = "\n")
  for (p in c("cftsecnumwidth", "cftsubsecnumwidth", "cftsubsubsecnumwidth")) {
    expect_match(teks, p, fixed = TRUE)
  }
})

test_that("karakter khusus pada judul header diloloskan", {
  # "Reduksi & Anomali" sebelumnya membuat fancyhdr membaca & sebagai
  # pemisah kolom sehingga kompilasi gagal.
  th <- theme_factory()
  out <- th$preamble(number = 1, topic = "Reduksi & Anomali",
                     variant = "modul")
  expect_match(out, "Reduksi \\\\& Anomali")
  expect_false(grepl("Reduksi & Anomali", out, fixed = TRUE))
})

test_that("templat proyek RStudio tersedia dan sah", {
  dcf <- system.file("rstudio", "templates", "project",
                     "buat_proyek_modul.dcf", package = "modulstis")
  expect_true(nzchar(dcf))
  isi <- read.dcf(dcf)
  # RStudio menuntut Binding menunjuk fungsi yang diekspor paket
  expect_true("Binding" %in% colnames(isi))
  expect_identical(unname(isi[1, "Binding"]), "buat_proyek_modul")
  expect_true(exists("buat_proyek_modul", envir = asNamespace("modulstis")))
})

test_that("buat_proyek_modul menghasilkan kerangka yang dapat dirender", {
  p <- file.path(tempdir(), paste0("proyek_", as.integer(runif(1, 1, 1e6))))
  on.exit(unlink(p, recursive = TRUE), add = TRUE)

  buat_proyek_modul(p, matkul = "Mata Kuliah Uji", kode = "K999999",
                    prodi = "D-IV Statistika", penyusun = "Penguji")

  expect_true(dir.exists(file.path(p, "spec")))
  expect_true(dir.exists(file.path(p, "modul")))
  expect_true(file.exists(file.path(p, "render_modul.R")))
  expect_true(file.exists(file.path(p, "README.md")))

  # spesifikasi contoh harus lolos validasi apa adanya
  f  <- list.files(file.path(p, "spec"), "\\.yml$", full.names = TRUE)[1]
  sp <- module_spec_from_yaml(f)
  expect_true(sp$validate()$ok)
  expect_identical(sp$course$kode, "K999999")
})

test_that("kotak centang RStudio yang berupa teks ditafsirkan benar", {
  # RStudio mengirim "TRUE"/"FALSE" sebagai karakter, bukan logika
  p <- file.path(tempdir(), paste0("proyek_cb_", as.integer(runif(1, 1, 1e6))))
  on.exit(unlink(p, recursive = TRUE), add = TRUE)
  buat_proyek_modul(p, contoh_spec = "FALSE")
  expect_equal(length(list.files(file.path(p, "spec"), "\\.yml$")), 0L)
})

test_that("renderer quarto tersedia lewat factory", {
  th <- theme_factory()
  r  <- renderer_factory("quarto", theme = th)
  expect_s3_class(r, "QuartoRenderer")
})

test_that("preamble memuat format judul tingkat empat", {
  # Quarto memetakan '####' ke \paragraph; tanpa format, titlesec berhenti
  # dengan galat "No format for this command".
  teks <- paste(readLines(
    system.file("templates", "preamble.tex.tmpl", package = "modulstis"),
    warn = FALSE), collapse = "\n")
  expect_match(teks, "titleformat{\\paragraph}", fixed = TRUE)
  expect_match(teks, "titleformat{\\subparagraph}", fixed = TRUE)
})

test_that("latex_prose_safe meloloskan sisipan dan tilde", {
  hasil <- latex_prose_safe("pangkat ^ dan kira-kira ~ lima")
  expect_match(hasil, "textasciicircum", fixed = TRUE)
  expect_match(hasil, "textasciitilde", fixed = TRUE)
  expect_false(grepl("(?<!i)\\^", hasil, perl = TRUE))
})

test_that("judul sampul memakai font lewat opsi node TikZ", {
  # Bila font ditetapkan di dalam badan node, TikZ mengunci jarak baris dari
  # font luar sehingga judul tiga baris saling bertindih.
  teks <- paste(readLines(
    system.file("templates", "preamble.tex.tmpl", package = "modulstis"),
    warn = FALSE), collapse = "\n")
  expect_match(teks, "font=\\sffamily\\bfseries\\fontsize{28}{33}", fixed = TRUE)
  expect_match(teks, "hyphenchar\\font=-1", fixed = TRUE)
})

test_that("judul label mengamankan karakter khusus di luar matematika", {
  ctx <- RenderContext$new(number = 5)
  # ^ dan ~ menghentikan kompilasi bila diteruskan apa adanya
  out <- ctx$emit_kode("Arah pembeda Sp^{-1} dan pola ~x")
  expect_true(grepl("textasciicircum", out, fixed = TRUE))
  expect_true(grepl("textasciitilde", out, fixed = TRUE))
  expect_false(grepl("Sp^", out, fixed = TRUE))

  # % dan # juga di-escape, sedangkan & dan _ tetap seperti sebelumnya
  out2 <- ctx$emit_contoh("50% amatan #1 pada data_baku & lainnya")
  expect_true(grepl("50\\\\%", out2))
  expect_true(grepl("\\\\#1", out2))
  expect_true(grepl("data\\\\_baku", out2))
  expect_true(grepl("\\\\& lainnya", out2))

  # isi $...$ dibiarkan agar matematika ringkas tetap dapat dipakai
  out3 <- ctx$emit_latihan("Uji $T^2$ Hotelling")
  expect_true(grepl("$T^2$", out3, fixed = TRUE))

  # karakter yang sudah ter-escape tidak di-escape ganda
  out4 <- ctx$emit_tugas("Berkas nama\\_lama")
  expect_false(grepl("\\\\\\\\_", out4))
})

test_that("direktori kunci ikut menerima berkas data", {
  skip_on_cran()
  spec <- module_spec_from_yaml(
    system.file("specs_d3/modul-02-dasar.yml", package = "modulstis"))
  skip_if(length(spec$datasets) == 0)
  tmp <- file.path(tempdir(), paste0("kunci-data-", as.integer(runif(1, 1, 1e6))))
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  proj <- ModuleProject$new(theme = "bps", backend = "bookdown", output_dir = tmp)
  proj$specs <- list(spec)
  proj$generate_data()
  # tiru langkah penyalinan data yang kini dilakukan render_module()
  dirk <- file.path(tmp, sprintf("kunci-%02d", spec$number))
  dir.create(dirk, recursive = TRUE, showWarnings = FALSE)
  generate_module_data(spec, output_dir = dirk)

  berkas <- basename(list.files(file.path(dirk, "data"), pattern = "[.]csv$"))
  expect_true(length(berkas) >= 1)
  expect_setequal(
    berkas,
    basename(list.files(file.path(tmp, sprintf("modul-%02d", spec$number), "data"),
                        pattern = "[.]csv$")))
})

test_that("recipe kind 'file' memakai berkas data nyata tanpa simulasi", {
  tmp <- file.path(tempdir(), paste0("file-recipe-", as.integer(runif(1, 1, 1e6))))
  dir.create(file.path(tmp, "asli"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  asli <- data.frame(kab = sprintf("K%02d", 1:5), RLS = c(8.1, 9.2, 7.3, 8.8, 9.9),
                     AHH = c(70, 71, 69, 72, 73), Lain = 1:5)
  write.csv(asli, file.path(tmp, "asli", "nyata.csv"), row.names = FALSE)

  rec <- list(kind = "file", path = "asli/nyata.csv",
              columns = c("kab", "RLS", "AHH"), base_dir = tmp)
  df <- generate_dataset(rec)
  expect_equal(names(df), c("kab", "RLS", "AHH"))       # kolom terpilih & urut
  expect_equal(df$RLS, asli$RLS)                        # nilai apa adanya
  expect_equal(nrow(df), 5L)

  # dua pemanggilan memberi hasil identik (tidak ada keacakan sama sekali)
  expect_identical(df, generate_dataset(rec))

  # n memotong baris; rename mengganti nama kolom
  rec2 <- c(rec, list(n = 3))
  expect_equal(nrow(generate_dataset(rec2)), 3L)
  rec3 <- rec; rec3$rename <- list(RLS = "rata_lama_sekolah")
  expect_true("rata_lama_sekolah" %in% names(generate_dataset(rec3)))

  # kolom tak ada dan berkas tak ada -> galat yang jelas
  rec4 <- rec; rec4$columns <- c("kab", "TidakAda")
  expect_error(generate_dataset(rec4), "kolom tidak ada")
  rec5 <- rec; rec5$path <- "asli/tidak_ada.csv"
  expect_error(generate_dataset(rec5), "tidak ditemukan")
})

test_that("path relatif diselesaikan terhadap letak berkas YAML", {
  tmp <- file.path(tempdir(), paste0("file-yaml-", as.integer(runif(1, 1, 1e6))))
  dir.create(file.path(tmp, "data_asli"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  write.csv(data.frame(a = 1:3, b = 4:6), file.path(tmp, "data_asli", "nyata.csv"),
            row.names = FALSE)
  yml <- file.path(tmp, "modul-99.yml")
  writeLines(c("number: 99", 'title: "Uji"', "short_code: uji", "topic: Uji",
               "pertemuan: 99", 'sub_cpmk: "Uji"', "datasets:", "  - name: nyata",
               "    role: contoh", "    recipe:", "      kind: file",
               "      path: data_asli/nyata.csv", "exercises:", "  - id: L1",
               '    prompt: "x"', '    solution: "y"', "    points: 10"), yml)

  spec <- module_spec_from_yaml(yml)
  expect_true(spec$validate()$ok)                       # berkas ditemukan lewat base_dir
  expect_equal(nrow(generate_dataset(spec$datasets[[1]]$recipe)), 3L)

  spec$datasets[[1]]$recipe$path <- "data_asli/tidak_ada.csv"
  rep <- spec$validate()
  expect_false(rep$ok)
  expect_match(paste(rep$messages, collapse = " "), "tidak ditemukan")
})
