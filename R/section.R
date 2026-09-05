#' Konteks render (penomoran terkelola)
#'
#' Menyimpan pencacah untuk contoh, kode, latihan, dan tugas agar
#' penomoran (mis. Contoh 14.1, Kode 14.2) konsisten otomatis.
#'
#' @export
RenderContext <- R6::R6Class("RenderContext",
  public = list(
    #' @field number nomor modul
    number = NULL,
    #' @description Buat konteks
    #' @param number nomor modul
    initialize = function(number) {
      self$number <- number
      private$counters <- list(contoh = 0L, kode = 0L, latihan = 0L, tugas = 0L)
    },
    #' @description Ambil nilai pencacah
    #' @param what nama pencacah
    counter = function(what) private$counters[[what]],
    #' @description Judul bagian (dibiarkan Markdown menomori otomatis)
    #' @param title judul
    heading = function(title) paste0("# ", title),
    #' @description Emit label Contoh bernomor
    #' @param judul judul contoh
    emit_contoh = function(judul) {
      private$bump("contoh")
      sprintf("\\contoh{%s}", .amp(judul))
    },
    #' @description Emit label Kode bernomor
    #' @param judul judul kode
    #' @param bahasa "R" (default) atau "Python"; menentukan warna label
    emit_kode = function(judul, bahasa = "R") {
      private$bump("kode")
      if (identical(bahasa, "Python")) {
        sprintf("\\kode[Python]{%s}", .amp(judul))
      } else {
        sprintf("\\kode{%s}", .amp(judul))
      }
    },
    #' @description Emit label Latihan bernomor
    #' @param judul judul latihan
    emit_latihan = function(judul) {
      private$bump("latihan")
      sprintf("\\latihan{%s}", .amp(judul))
    },
    #' @description Emit label Tugas bernomor
    #' @param judul judul tugas
    emit_tugas = function(judul) {
      private$bump("tugas")
      sprintf("\\tugas{%s}", .amp(judul))
    }
  ),
  private = list(
    counters = NULL,
    bump = function(what) {
      private$counters[[what]] <- private$counters[[what]] + 1L
      invisible(private$counters[[what]])
    }
  )
)

# amankan '&' dan '_' pada teks label bebas agar aman di LaTeX text mode
.amp <- function(x) {
  if (is.null(x) || length(x) == 0) return(x)
  # Judul label boleh memuat matematika ringkas ($T^2$, $\mathbf{S}_p$); bagian di
  # dalam pasangan $...$ dibiarkan apa adanya, sedangkan di luarnya karakter
  # khusus LaTeX di-escape. Tanpa ini, judul seperti "Sp^{-1} dan T^2" atau
  # "50% amatan" menghentikan kompilasi.
  satu <- function(s) {
    s <- as.character(s)
    if (is.na(s)) return(s)
    potongan <- regmatches(s, gregexpr("\\$[^$]*\\$|[^$]+", s, perl = TRUE))[[1]]
    if (length(potongan) == 0) return(s)
    hasil <- vapply(potongan, function(p) {
      if (startsWith(p, "$") && endsWith(p, "$") && nchar(p) >= 2) return(p)
      p <- gsub("(?<!\\\\)([&_%#])", "\\\\\\1", p, perl = TRUE)
      p <- gsub("(?<!\\\\)\\^", "\\\\textasciicircum{}", p, perl = TRUE)
      gsub("(?<!\\\\)~", "\\\\textasciitilde{}", p, perl = TRUE)
    }, character(1), USE.NAMES = FALSE)
    paste0(hasil, collapse = "")
  }
  vapply(x, satu, character(1), USE.NAMES = FALSE)
}

#' Bagian modul (kelas dasar, Template Method)
#'
#' `render()` menetapkan kerangka (judul + isi); `render_body()`
#' dioverride tiap jenis bagian.
#'
#' @export
Section <- R6::R6Class("Section",
  public = list(
    #' @field spec spesifikasi bagian
    spec = NULL,
    #' @field content isi bagian (dari ModuleSpec$body)
    content = NULL,
    #' @description Buat bagian
    #' @param spec SectionSpec (list id/type/title)
    #' @param content isi bagian
    initialize = function(spec, content = NULL) {
      self$spec <- spec
      self$content <- content
    },
    #' @description Template Method: kerangka render tetap
    #' @param ctx [RenderContext]
    render = function(ctx) {
      head <- ctx$heading(self$spec$title)
      body <- self$render_body(ctx)
      paste0(head, "\n\n", body)
    },
    #' @description Isi bagian (di-override subclass)
    #' @param ctx [RenderContext]
    render_body = function(ctx) {
      # default: tulis konten mentah bila ada
      if (is.null(self$content)) {
        return(sprintf("_(Konten bagian '%s' belum diisi.)_", self$spec$id))
      }
      paste(self$content, collapse = "\n\n")
    }
  )
)

#' Bagian contoh praktikum (menomori contoh & kode)
#' @export
ExampleSection <- R6::R6Class("ExampleSection", inherit = Section,
  public = list(
    #' @description Render isi contoh
    #' @param ctx [RenderContext]
    render_body = function(ctx) {
      items <- self$content
      if (is.null(items) || length(items) == 0) {
        return(super$render_body(ctx))
      }
      blocks <- purrr::map_chr(items, function(it) {
        # item berupa string mentah (mis. kotak sisipan) ditulis apa adanya
        if (is.character(it)) return(it)
        parts <- character(0)
        if (!is.null(it[["contoh"]])) parts <- c(parts, ctx$emit_contoh(it[["contoh"]]))
        if (!is.null(it[["narasi"]])) parts <- c(parts, it[["narasi"]])
        if (!is.null(it[["kode"]])) {
          bahasa <- it[["bahasa"]] %||% "R"
          engine <- if (identical(bahasa, "Python")) "python" else "r"
          parts <- c(parts, ctx$emit_kode(it[["kode_judul"]] %||% "Kode", bahasa))
          ev <- if (isTRUE(it[["eval"]])) "" else ", eval=FALSE"
          parts <- c(parts, paste0("```{", engine, ev, "}\n", it[["kode"]], "\n```"))
        }
        # dukungan pasangan: kode_r + kode_py dalam satu item (R lalu Python)
        if (!is.null(it[["kode_r"]])) {
          parts <- c(parts, ctx$emit_kode(it[["judul_r"]] %||% "Kode R", "R"))
          ev <- if (isTRUE(it[["eval"]])) "" else ", eval=FALSE"
          parts <- c(parts, paste0("```{r", ev, "}\n", it[["kode_r"]], "\n```"))
        }
        if (!is.null(it[["kode_py"]])) {
          parts <- c(parts, ctx$emit_kode(it[["judul_py"]] %||% "Kode Python", "Python"))
          ev <- if (isTRUE(it[["eval"]])) "" else ", eval=FALSE"
          parts <- c(parts, paste0("```{python", ev, "}\n", it[["kode_py"]], "\n```"))
        }
        if (!is.null(it[["penjelasan"]])) {
          parts <- c(parts,
            sprintf("\\begin{kotakpenjelasan}\n%s\n\\end{kotakpenjelasan}",
                    latex_prose_safe(it[["penjelasan"]])))
        }
        if (!is.null(it[["interpretasi"]])) {
          parts <- c(parts,
            sprintf("\\begin{kotakinterpretasi}\n%s\n\\end{kotakinterpretasi}",
                    latex_prose_safe(it[["interpretasi"]])))
        }
        paste(parts, collapse = "\n\n")
      })
      paste(blocks, collapse = "\n\n")
    }
  )
)

#' Bagian latihan (menomori latihan)
#' @export
ExerciseSection <- R6::R6Class("ExerciseSection", inherit = Section,
  public = list(
    #' @description Render isi latihan
    #' @param ctx [RenderContext]
    render_body = function(ctx) {
      items <- self$content
      if (is.null(items) || length(items) == 0) return(super$render_body(ctx))
      # Bila konten berupa string mentah (markdown/LaTeX siap pakai), tulis apa adanya
      if (is.character(items)) return(paste(items, collapse = "\n\n"))
      blocks <- purrr::map_chr(items, function(it) {
        if (is.character(it)) return(it)
        parts <- c(ctx$emit_latihan(it[["judul"]] %||% "Latihan"))
        if (!is.null(it[["isi"]])) parts <- c(parts, it[["isi"]])
        paste(parts, collapse = "\n\n")
      })
      paste(blocks, collapse = "\n\n")
    }
  )
)

#' Bagian penugasan (menomori tugas)
#' @export
AssignmentSection <- R6::R6Class("AssignmentSection", inherit = Section,
  public = list(
    #' @description Render isi penugasan
    #' @param ctx [RenderContext]
    render_body = function(ctx) {
      items <- self$content
      if (is.null(items) || length(items) == 0) return(super$render_body(ctx))
      if (is.character(items)) return(paste(items, collapse = "\n\n"))
      blocks <- purrr::map_chr(items, function(it) {
        if (is.character(it)) return(it)
        parts <- c(ctx$emit_tugas(it[["judul"]] %||% "Tugas"))
        if (!is.null(it[["isi"]])) parts <- c(parts, it[["isi"]])
        paste(parts, collapse = "\n\n")
      })
      paste(blocks, collapse = "\n\n")
    }
  )
)

#' Buat objek Section sesuai jenis (Factory + Registry)
#' @param spec SectionSpec
#' @param content isi bagian
#' @return objek turunan [Section]
#' @export
make_section <- function(spec, content = NULL) {
  cls <- switch(spec$type,
    example    = ExampleSection,
    exercise   = ExerciseSection,
    assignment = AssignmentSection,
    glossary   = GlossarySection,
    Section
  )
  cls$new(spec, content)
}
