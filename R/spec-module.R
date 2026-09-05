#' Kosakata baku jenis bagian (section)
#' @export
section_types <- function() {
  c("prose", "objectives", "tools", "procedure", "theory",
    "example", "exercise", "assignment", "summary", "references", "glossary")
}

#' Laporan hasil validasi
#'
#' Objek nilai sederhana berisi status dan pesan.
#' @export
ValidationReport <- R6::R6Class("ValidationReport",
  public = list(
    #' @field ok logis, TRUE bila valid
    ok = TRUE,
    #' @field messages vektor pesan galat
    messages = character(0),
    #' @description Tambah galat
    #' @param msg pesan
    add = function(msg) {
      self$ok <- FALSE
      self$messages <- c(self$messages, msg)
      invisible(self)
    },
    #' @description Cetak laporan
    #' @param ... diabaikan
    print = function(...) {
      if (self$ok) {
        cat("\u2714 Spesifikasi valid.\n")
      } else {
        cat("\u2716 Spesifikasi tidak valid:\n")
        for (m in self$messages) cat("  -", m, "\n")
      }
      invisible(self)
    }
  )
)

#' Spesifikasi modul (objek nilai deklaratif)
#'
#' Satu-satunya sumber kebenaran untuk sebuah modul: metadata, daftar
#' bagian, dataset, dan latihan/penugasan. Tahu cara memvalidasi dirinya.
#'
#' @export
ModuleSpec <- R6::R6Class("ModuleSpec",
  public = list(
    #' @field number nomor modul
    number = NULL,
    #' @field title judul modul
    title = NULL,
    #' @field short_code kode singkat untuk nama berkas
    short_code = NULL,
    #' @field topic topik untuk header
    topic = NULL,
    #' @field pertemuan pertemuan ke-berapa (RPS)
    pertemuan = NULL,
    #' @field sub_cpmk teks sub-CPMK
    sub_cpmk = NULL,
    #' @field packages paket R yang dibutuhkan
    packages = NULL,
    #' @field sections daftar bagian
    sections = NULL,
    #' @field datasets daftar dataset
    datasets = NULL,
    #' @field exercises daftar latihan/penugasan
    exercises = NULL,
    #' @field body isi konten per bagian (list bernama by section id)
    body = NULL,
    #' @field references daftar referensi
    references = NULL,
    #' @field course identitas mata kuliah (list: matkul, matkul_besar, kode, ta, semester); NULL = APG
    course = NULL,
    #' @field contoh_title judul bagian Contoh (override; mis. "Contoh Praktikum dengan R dan Python")
    contoh_title = NULL,
    #' @field tambahan_title judul bagian Tambahan (setelah Penugasan)
    tambahan_title = NULL,

    #' @description Buat spec dari list
    #' @param number nomor modul
    #' @param title judul modul
    #' @param topic topik untuk header; `NULL` memakai `title`
    #' @param short_code kode singkat untuk nama berkas; `NULL` diturunkan dari judul
    #' @param pertemuan pertemuan ke-berapa menurut RPS
    #' @param sub_cpmk teks sub-CPMK
    #' @param packages paket R yang dibutuhkan modul
    #' @param sections daftar bagian; `NULL` memakai [default_sections()]
    #' @param datasets daftar dataset beserta resepnya
    #' @param exercises daftar latihan/penugasan beserta solusinya
    #' @param body isi tiap bagian
    #' @param references daftar pustaka
    #' @param course metadata mata kuliah (matkul, kode, prodi, penyusun, ...)
    #' @param contoh_title judul khusus bagian Contoh
    #' @param tambahan_title judul khusus bagian Tambahan
    initialize = function(number = NULL, title = NULL, topic = NULL,
                          short_code = NULL, pertemuan = NULL, sub_cpmk = NULL,
                          packages = character(0), sections = NULL,
                          datasets = list(), exercises = list(),
                          body = list(), references = character(0),
                          course = NULL, contoh_title = NULL,
                          tambahan_title = NULL) {
      self$number <- number
      self$title <- title
      self$topic <- topic %||% title
      self$short_code <- short_code %||% slugify(title %||% as.character(number))
      self$pertemuan <- pertemuan
      self$sub_cpmk <- sub_cpmk
      self$packages <- packages
      self$course <- course
      self$contoh_title <- contoh_title
      self$tambahan_title <- tambahan_title
      self$sections <- sections %||% default_sections(contoh_title = contoh_title, tambahan_title = tambahan_title)
      self$datasets <- datasets
      self$exercises <- exercises
      self$body <- body
      self$references <- references
    },

    #' @description Validasi spec terhadap skema (fail-fast agregat)
    #' @return objek [ValidationReport]
    validate = function() {
      rep <- ValidationReport$new()
      if (is.null(self$number) || !is.numeric(self$number) ||
          self$number < 1 || self$number > 99) {
        rep$add("`number` harus bilangan bulat 1..99")
      }
      if (is.null(self$title) || !nzchar(self$title)) {
        rep$add("`title` tidak boleh kosong")
      }
      ids <- vapply(self$sections, function(s) s$id %||% "", character(1))
      if (anyDuplicated(ids)) rep$add("`sections[*].id` harus unik")
      types <- vapply(self$sections, function(s) s$type %||% "", character(1))
      bad <- setdiff(types, section_types())
      if (length(bad)) {
        rep$add(paste0("jenis bagian tidak dikenal: ", paste(bad, collapse = ", ")))
      }
      for (ds in self$datasets) {
        if (is.null(ds$recipe) || is.null(ds$recipe$kind)) {
          rep$add(sprintf("dataset '%s' tidak punya recipe.kind", ds$name %||% "?"))
        } else if (identical(ds$recipe$kind, "file")) {
          p <- ds$recipe$path %||% ds$recipe$file
          if (is.null(p)) {
            rep$add(sprintf("dataset '%s' berjenis file tetapi tanpa `path`",
                            ds$name %||% "?"))
          } else if (!file.exists(resolve_data_path(p, ds$recipe$base_dir))) {
            rep$add(sprintf("dataset '%s': berkas tidak ditemukan (%s)",
                            ds$name %||% "?", p))
          }
        }
      }
      for (i in seq_along(self$exercises)) {
        ex <- self$exercises[[i]]
        if (is.null(ex$points)) {
          rep$add(sprintf("exercises[%d].points hilang", i))
        }
      }
      rep
    }
  )
)

#' Sepuluh bagian baku modul praktikum
#' @param contoh_title judul khusus bagian Contoh; `NULL` memakai judul bawaan
#' @param tambahan_title judul khusus bagian Tambahan; `NULL` memakai judul bawaan
#' @return list SectionSpec (list bernama)
#' @export
default_sections <- function(contoh_title = NULL, tambahan_title = NULL) {
  defs <- list(
    c("deskripsi",  "prose",      "Deskripsi Modul"),
    c("tujuan",     "objectives", "Tujuan Praktikum"),
    c("alat",       "tools",      "Alat dan Bahan"),
    c("instruksi",  "procedure",  "Instruksi Pengerjaan"),
    c("teori",      "theory",     "Teori Singkat"),
    c("contoh",     "example",    contoh_title %||% "Contoh Praktikum dengan R"),
    c("latihan",    "exercise",   "Latihan Mandiri"),
    c("penugasan",  "assignment", "Penugasan"),
    c("tambahan",   "example",    tambahan_title %||% "Tambahan: Penyelesaian dengan Fungsi R"),
    c("ringkasan",  "summary",    "Ringkasan Modul"),
    c("referensi",  "references", "Referensi")
  )
  lapply(defs, function(d) list(id = d[1], type = d[2], title = d[3]))
}

#' Muat ModuleSpec dari berkas YAML
#' @param path path berkas .yml
#' @return objek [ModuleSpec]
#' @export
module_spec_from_yaml <- function(path) {
  raw <- yaml::read_yaml(path)
  # Resep `kind: file` menunjuk berkas data nyata; path relatif pada YAML dihitung
  # terhadap letak berkas YAML itu sendiri, bukan direktori kerja pemanggil.
  base_dir <- dirname(normalizePath(path, winslash = "/", mustWork = FALSE))
  raw$datasets <- lapply(raw$datasets %||% list(), function(ds) {
    if (!is.null(ds$recipe) && identical(ds$recipe$kind, "file") &&
        is.null(ds$recipe$base_dir)) {
      ds$recipe$base_dir <- base_dir
    }
    ds
  })
  ModuleSpec$new(
    number = raw$number, title = raw$title, topic = raw$topic,
    short_code = raw$short_code, pertemuan = raw$pertemuan,
    sub_cpmk = raw$sub_cpmk, packages = raw$packages %||% character(0),
    contoh_title = raw$contoh_title,
    tambahan_title = raw$tambahan_title,
    sections = raw$sections %||% default_sections(contoh_title = raw$contoh_title, tambahan_title = raw$tambahan_title),
    datasets = raw$datasets %||% list(),
    exercises = raw$exercises %||% list(),
    body = raw$body %||% list(),
    references = raw$references %||% character(0),
    course = raw$course
  )
}

#' Konstruktor ringkas ModuleSpec
#' @param number nomor modul
#' @param title judul
#' @param ... field lain
#' @return objek [ModuleSpec]
#' @export
module_spec <- function(number, title, ...) {
  ModuleSpec$new(number = number, title = title, ...)
}
