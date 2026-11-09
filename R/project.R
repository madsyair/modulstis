#' Proyek modul (Facade) — API utama end-to-end
#'
#' Menyimpan koleksi [ModuleSpec], memvalidasi seluruhnya (fail-fast agregat),
#' membangkitkan data, lalu merender modul + kunci untuk setiap spec lewat
#' pipeline fungsional (looping). Renderer disuntikkan (dependency injection),
#' sehingga backend dapat diganti tanpa mengubah orkestrasi.
#'
#' @export
ModuleProject <- R6::R6Class("ModuleProject",
  public = list(
    #' @field specs daftar [ModuleSpec]
    specs = NULL,
    #' @field logger [Logger]
    logger = NULL,

    #' @description Buat proyek
    #' @param specs_dir direktori berisi berkas .yml (opsional)
    #' @param theme "bps" atau [LatexTheme]
    #' @param backend "bookdown" atau "quarto"
    #' @param log_level ambang log konsol
    #' @param output_dir direktori keluaran build
    initialize = function(specs_dir = NULL, theme = "bps",
                          backend = c("bookdown", "quarto"),
                          log_level = "info", output_dir = "build") {
      backend <- match.arg(backend)
      self$logger <- build_logger(console_level = log_level)
      private$theme <- if (inherits(theme, "LatexTheme")) theme else theme_factory(theme)
      private$backend <- backend
      private$output_dir <- output_dir
      self$specs <- list()
      if (!is.null(specs_dir)) {
        files <- fs::dir_ls(specs_dir, glob = "*.yml")
        self$specs <- purrr::map(files, module_spec_from_yaml)
        self$logger$info("Muat spesifikasi", jumlah = length(self$specs))
      }
    },

    #' @description Tambah satu spec
    #' @param spec [ModuleSpec]
    add_module = function(spec) {
      self$specs[[length(self$specs) + 1L]] <- spec
      invisible(self)
    },

    #' @description Validasi semua spec (fail-fast agregat)
    #' @return logis, TRUE bila semua valid
    validate_all = function() {
      reports <- purrr::map(self$specs, ~ .x$validate())
      oks <- purrr::map_lgl(reports, ~ .x$ok)
      purrr::iwalk(reports, function(r, i) {
        if (!r$ok) {
          self$logger$error("Spec tidak valid", modul = self$specs[[i]]$number)
          for (m in r$messages) self$logger$error(paste("  -", m))
        }
      })
      all(oks)
    },

    #' @description Bangkitkan data seluruh modul
    generate_data = function() {
      purrr::walk(self$specs, function(spec) {
        dir <- file.path(private$output_dir, sprintf("modul-%02d", spec$number))
        if (length(spec$datasets)) {
          generate_module_data(spec, output_dir = dir)
          self$logger$info("Data dibangkitkan", modul = spec$number,
                           dataset = length(spec$datasets))
        }
      })
      invisible(self)
    },

    #' @description Render modul + kunci untuk satu spec
    #' @param spec [ModuleSpec]
    #' @return list(modul=Artifact, kunci=Artifact)
    render_module = function(spec) {
      rnd <- renderer_factory(private$backend, theme = private$theme,
                              logger = self$logger)
      doc_m <- ModuleBuilder$new(private$theme, self$logger)$build(spec)
      doc_k <- AnswerKeyBuilder$new(private$theme, self$logger)$build(spec)
      dirm <- file.path(private$output_dir, sprintf("modul-%02d", spec$number))
      dirk <- file.path(private$output_dir, sprintf("kunci-%02d", spec$number))
      # Modul dan kunci membaca berkas data dengan path relatif "data/...", sehingga
      # kedua direktori harus memuat data tersebut sebelum render. Data dibangkitkan
      # di sini, bukan hanya oleh generate_data(), agar render_all() tetap berhasil
      # walaupun generate_data() tidak dipanggil lebih dahulu.
      if (length(spec$datasets)) {
        for (d in c(dirm, dirk)) {
          dir.create(d, recursive = TRUE, showWarnings = FALSE)
          generate_module_data(spec, output_dir = d)
        }
        self$logger$debug("Data disiapkan untuk modul dan kunci", modul = spec$number)
      }
      am <- self$logger$with_timing("render modul",
              rnd$render(doc_m, dirm), modul = spec$number)
      ak <- self$logger$with_timing("render kunci",
              rnd$render(doc_k, dirk), modul = spec$number)
      list(modul = am, kunci = ak)
    },

    #' @description Render seluruh modul (looping fungsional, tahan galat)
    #' @return list hasil per modul
    render_all = function() {
      safe <- purrr::safely(function(spec) self$render_module(spec))
      hasil <- self$specs |>
        purrr::set_names(purrr::map_chr(self$specs, ~ as.character(.x$number))) |>
        purrr::map(safe)
      purrr::iwalk(hasil, function(h, nomor) {
        if (is.null(h$error)) {
          self$logger$info("OK", modul = nomor)
        } else {
          self$logger$error("GAGAL", modul = nomor,
                            pesan = conditionMessage(h$error))
        }
      })
      invisible(hasil)
    }
  ),
  private = list(theme = NULL, backend = NULL, output_dir = NULL)
)

#' Render satu modul langsung (jalan pintas)
#' @param spec [ModuleSpec]
#' @param backend "bookdown" atau "quarto"
#' @param theme "bps" atau [LatexTheme]
#' @param output_dir direktori keluaran
#' @return list artefak
#' @export
render_module <- function(spec, backend = "bookdown", theme = "bps",
                          output_dir = "build") {
  ensure_dir(output_dir)
  proj <- ModuleProject$new(theme = theme, backend = backend,
                            output_dir = output_dir)
  proj$add_module(spec)
  proj$generate_data()
  proj$render_module(spec)
}
