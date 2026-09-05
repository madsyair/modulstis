# Uji revisi 0.2.0: recipe baru, dukungan Python, identitas kursus, judul contoh

test_that("recipe tabular menghasilkan kolom numeric/integer/category", {
  d <- generate_dataset(list(kind = "tabular", n = 25, seed = 1,
    columns = list(
      x = list(type = "numeric", min = 0, max = 10),
      k = list(type = "integer", min = 1, max = 5),
      g = list(type = "category", levels = c("A", "B"), probs = c(.5, .5)))))
  expect_equal(nrow(d), 25)
  expect_true(is.numeric(d$x))
  expect_true(is.integer(d$k))
  expect_true(is.factor(d$g))
})

test_that("recipe categorical menghasilkan faktor nominal", {
  d <- generate_dataset(list(kind = "categorical", n = 40, seed = 1,
    archetypes = list(P = .5, Q = .5),
    vars_probs = list(v = list(P = list(a = .8, b = .2), Q = list(a = .2, b = .8)))))
  expect_equal(nrow(d), 40)
  expect_true(is.factor(d$v))
  expect_equal(nlevels(d$v), 2)
})

test_that("recipe latent_class menghasilkan butir integer 1..K", {
  d <- generate_dataset(list(kind = "latent_class", n = 50, seed = 1,
    classes = list(C1 = .5, C2 = .5),
    items = list(i1 = list(C1 = c(.8, .2), C2 = c(.2, .8)))))
  expect_equal(nrow(d), 50)
  expect_true(is.integer(d$i1))
  expect_true(all(d$i1 %in% c(1L, 2L)))
})

test_that("kind tak dikenal tetap ditolak", {
  expect_error(generate_dataset(list(kind = "entah")), "tidak dikenal")
})

test_that("emit_kode Python memakai label \\kode[Python]", {
  ctx <- RenderContext$new(1)
  expect_match(ctx$emit_kode("uji", "Python"), "\\\\kode\\[Python\\]", perl = TRUE)
  expect_match(ctx$emit_kode("uji", "R"), "\\\\kode\\{", perl = TRUE)
})

test_that("preamble APG tetap default (kompatibilitas mundur)", {
  th <- theme_factory()
  p <- th$preamble(9, "Analisis Faktor", "modul")
  expect_true(grepl("K203318", p))
  expect_false(grepl("@@", p))
})

test_that("preamble menerima identitas kursus (Pemrograman Statistika)", {
  th <- theme_factory()
  p <- th$preamble(1, "Pengenalan", "modul", course = list(
    matkul = "Pemrograman Statistika", matkul_besar = "PEMROGRAMAN STATISTIKA",
    kode = "K242310", semester = "3 (Ganjil)"))
  expect_true(grepl("K242310", p))
  expect_true(grepl("bahasaPython", p))    # label kode Python tersedia
  expect_false(grepl("@@", p))
})

test_that("contoh_title override mengubah judul bagian Contoh", {
  secs <- default_sections(contoh_title = "Contoh Praktikum dengan R dan Python")
  contoh <- Filter(function(s) s$id == "contoh", secs)[[1]]
  expect_equal(contoh$title, "Contoh Praktikum dengan R dan Python")
})

test_that("ExampleSection memancarkan chunk python untuk bahasa Python", {
  ctx <- RenderContext$new(1)
  sec <- ExampleSection$new(list(id = "contoh", type = "example", title = "X"))
  sec$content <- list(list(kode = "print(1)", bahasa = "Python", kode_judul = "uji"))
  out <- sec$render_body(ctx)
  expect_match(out, "```\\{python", perl = TRUE)
  expect_match(out, "\\\\kode\\[Python\\]", perl = TRUE)
})

test_that("AnswerKeyBuilder merender solusi berkode R dan Python", {
  spec <- module_spec(
    number = 98, title = "Uji Kunci", short_code = "uji_kunci",
    topic = "Uji", pertemuan = 1, sub_cpmk = "x",
    exercises = list(list(id = "L1.1", points = 40,
      solution = "Ringkas.", solusi_r = "1+1", judul_r = "Jawab R",
      solusi_py = "print(2)", judul_py = "Jawab Python",
      interpretasi = "Setara.")))
  kb <- AnswerKeyBuilder$new(theme = theme_factory())
  doc <- kb$build(spec)
  expect_match(doc$body, "```\\{r", perl = TRUE)
  expect_match(doc$body, "```\\{python", perl = TRUE)
  expect_match(doc$body, "\\\\kode\\[Python\\]", perl = TRUE)
  expect_match(doc$body, "kotakinterpretasi")
})

test_that("item kode_r-saja tidak menghasilkan blok kode ganda (bug partial-match)", {
  ctx <- RenderContext$new(3)
  sec <- ExampleSection$new(list(id = "contoh", type = "example", title = "X"))
  sec$content <- list(list(contoh = "Uji", kode_r = "1+1", judul_r = "Judul R",
                           eval = TRUE, interpretasi = "ok"))
  out <- sec$render_body(ctx)
  # tepat satu blok R, tidak ada label generik "Kode", tidak ada python
  expect_equal(length(gregexpr("```\\{r", out, perl = TRUE)[[1]]), 1L)
  expect_false(grepl("\\kode{Kode}", out, fixed = TRUE))
  expect_false(grepl("```{python", out, fixed = TRUE))
})

test_that("tiga kotak komprehensif tersedia di preamble", {
  th <- theme_factory()
  p <- th$preamble(1, "Uji", "modul")
  expect_true(grepl("kotaksalah", p))
  expect_true(grepl("kotaktips", p))
  expect_true(grepl("kotakvariasi", p))
  expect_true(grepl("merahsalah", p))   # warna kotak kesalahan
})

test_that("box() menghasilkan environment kotak yang benar", {
  th <- theme_factory()
  expect_match(th$box("salah", "isi"), "\\\\begin\\{kotaksalah\\}", perl = TRUE)
  expect_match(th$box("tips", "isi"), "\\\\begin\\{kotaktips\\}", perl = TRUE)
  expect_match(th$box("variasi", "isi"), "\\\\begin\\{kotakvariasi\\}", perl = TRUE)
})

test_that("latex_prose_safe mengamankan underscore di prosa kotak", {
  out <- latex_prose_safe("pakai `value_counts()` pada data_mahasiswa")
  expect_true(grepl("\\\\texttt\\{value\\\\_counts", out, perl = TRUE))
  expect_true(grepl("data\\\\_mahasiswa", out, perl = TRUE))
  # tak ada underscore telanjang
  expect_equal(gregexpr("(?<!\\\\)_", out, perl = TRUE)[[1]][1], -1L)
})

test_that("semua spec PS bersih dari karakter non-ASCII berbahaya", {
  spec_dir <- system.file("specs_ps", package = "modulstis")
  if (spec_dir == "") spec_dir <- "inst/specs_ps"
  files <- list.files(spec_dir, pattern = "\\.yml$", full.names = TRUE)
  skip_if(length(files) == 0)
  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    # tak boleh ada karakter > 127 (Cyrillic, em-dash, dsb.) yang memicu galat baca R
    codes <- utf8ToInt(txt)
    expect_true(all(codes <= 127),
                info = paste("non-ASCII di", basename(f)))
  }
})

test_that("ukuran contoh n terbaca meski kunci YAML tak dikutip", {
  # YAML 1.1 menafsirkan kunci telanjang `n` sebagai FALSE; harus tetap terbaca.
  r <- yaml::yaml.load(
    "kind: tabular\nn: 7\nseed: 1\ncolumns:\n  a: {type: integer, min: 1, max: 5}\n")
  expect_equal(nrow(generate_dataset(r)), 7L)
  r2 <- yaml::yaml.load(
    "kind: tabular\n\"n\": 7\nseed: 1\ncolumns:\n  a: {type: integer, min: 1, max: 5}\n")
  expect_equal(nrow(generate_dataset(r2)), 7L)
})

test_that("spec PS membangkitkan data sebesar yang dinyatakan", {
  dir <- system.file("specs_ps", package = "modulstis")
  if (dir == "") dir <- "inst/specs_ps"
  harap <- c("modul-01-pengenalan.yml" = 10, "modul-02-dasar.yml" = 8,
             "modul-03-pemrograman-r.yml" = 12, "modul-05-dplyr.yml" = 40)
  for (f in names(harap)) {
    path <- file.path(dir, f)
    if (!file.exists(path)) next
    sp <- module_spec_from_yaml(path)
    d  <- generate_dataset(sp$datasets[[1]]$recipe)
    expect_equal(nrow(d), harap[[f]], info = f)
  }
})

test_that("latex_prose_safe mengamankan karakter khusus LaTeX lain", {
  out <- latex_prose_safe("pakai `input$n` pada 50% data_x")
  expect_true(grepl("input\\\\\\$n", out, perl = TRUE))
  expect_true(grepl("50\\\\%", out, perl = TRUE))
  expect_true(grepl("data\\\\_x", out, perl = TRUE))
  # yang sudah ter-escape tidak boleh di-escape ulang
  sudah <- "demo\\$nama dan umur\\_teks"
  expect_equal(latex_prose_safe(sudah), sudah)
})

test_that("field penjelasan dirender sebagai kotak sebelum interpretasi", {
  spec <- module_spec_from_yaml(
    file.path(system.file("specs_ps", package = "modulstis"), "modul-01-pengenalan.yml"))
  if (is.null(spec)) skip("spec tidak tersedia")
  th  <- theme_factory()
  doc <- ModuleBuilder$new(theme = th)$build(spec)
  b   <- doc$body
  expect_true(grepl("kotakpenjelasan", b, fixed = TRUE))
  # penjelasan harus muncul SEBELUM interpretasi pada contoh pertama
  i <- regexpr("kotakpenjelasan", b, fixed = TRUE)
  j <- regexpr("kotakinterpretasi", b, fixed = TRUE)
  expect_lt(i, j)
})

test_that("tipe kolom balanced menghasilkan rancangan faktorial berimbang", {
  r <- yaml::yaml.load(paste0(
    "kind: tabular\n\"n\": 12\nseed: 1\ncolumns:\n",
    "  A: {type: balanced, levels: [a1, a2, a3], each: 4}\n",
    "  B: {type: balanced, levels: [b1, b2], each: 2}\n"))
  d <- generate_dataset(r)
  tb <- table(d$A, d$B)
  expect_equal(nrow(d), 12L)
  expect_true(all(tb == tb[1, 1]))   # seluruh sel berisi amatan sama banyak
})

test_that("bagian tambahan muncul setelah penugasan dan dilewati bila kosong", {
  sp <- module_spec_from_yaml(
    file.path(system.file("specs_ps", package = "modulstis"), "modul-13-anova.yml"))
  ids <- vapply(sp$sections, function(s) s$id, character(1))
  expect_true("tambahan" %in% ids)
  expect_gt(which(ids == "tambahan"), which(ids == "penugasan"))
  expect_lt(which(ids == "tambahan"), which(ids == "ringkasan"))
  # bila body$tambahan kosong, bagian tidak dirender
  doc <- ModuleBuilder$new(theme = theme_factory())$build(sp)
  expect_false(grepl("belum diisi", doc$body, fixed = TRUE))
})

test_that("penyusun boleh lebih dari satu dan tampil di sampul", {
  th <- theme_factory()
  pre <- th$preamble(number = 1, topic = "Uji",
                     course = list(penyusun = c("Penyusun A", "Penyusun B")))
  expect_false(grepl("@@PENYUSUN@@", pre, fixed = TRUE))
  expect_true(grepl("Penyusun A, Penyusun B", pre, fixed = TRUE))
})

test_that("sampul_buku menghasilkan LaTeX tanpa penanda tersisa", {
  s <- sampul_buku("JUDUL", "KEDUA", kode = "K000", semester = "3",
                   penyusun = c("A", "B"), varian = "kunci")
  expect_false(grepl("@@", s, fixed = TRUE))
  expect_true(grepl("logo_stis.png", s, fixed = TRUE))
  expect_true(grepl("bpshijau", s, fixed = TRUE))   # varian kunci = pita hijau
})

test_that("aset tema tersedia di dalam paket", {
  d <- system.file("themes", "bps", "img", package = "modulstis")
  expect_true(file.exists(file.path(d, "logo_stis.png")))
  expect_true(file.exists(file.path(d, "gedung_bg.png")))
})

test_that("tahun ajaran tidak lagi tercetak pada sampul modul", {
  pre <- theme_factory()$preamble(number = 1, topic = "Uji")
  expect_false(grepl("Tahun Ajaran", pre, fixed = TRUE))
})

test_that("prodi dapat disesuaikan per mata kuliah", {
  bawaan <- theme_factory()$preamble(number = 1, topic = "U")
  khusus <- theme_factory()$preamble(number = 1, topic = "U",
                                     course = list(prodi = "D-IV Statistika"))
  expect_true(grepl("D-IV Komputasi Statistik", bawaan, fixed = TRUE))
  expect_true(grepl("D-IV Statistika", khusus, fixed = TRUE))
  expect_false(grepl("@@PRODI@@", khusus, fixed = TRUE))
})
