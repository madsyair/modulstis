#' Dokumen abstrak backend-agnostik
#'
#' Hasil `ContentBuilder$build()`: memuat metadata + badan Markdown/Rmd
#' yang dapat diserialisasi oleh renderer bookdown atau Quarto.
#'
#' @export
Document <- R6::R6Class("Document",
  public = list(
    #' @field number nomor modul
    number = NULL,
    #' @field kind "modul" atau "kunci"
    kind = NULL,
    #' @field short_code kode singkat
    short_code = NULL,
    #' @field topic topik header
    topic = NULL,
    #' @field cover string LaTeX cover
    cover = NULL,
    #' @field body badan Markdown/Rmd
    body = NULL,
    #' @field preamble preamble LaTeX
    preamble = NULL,
    #' @description Buat dokumen
    #' @param number nomor modul
    #' @param kind `"modul"` atau `"kunci"`
    #' @param short_code kode singkat untuk nama berkas
    #' @param topic topik untuk header halaman
    #' @param cover string LaTeX sampul pembatas
    #' @param body badan dokumen (Markdown/Rmd)
    #' @param preamble preamble LaTeX
    initialize = function(number, kind, short_code, topic, cover, body, preamble) {
      self$number <- number; self$kind <- kind
      self$short_code <- short_code; self$topic <- topic
      self$cover <- cover; self$body <- body; self$preamble <- preamble
    }
  )
)

#' Pembangun konten (abstrak)
#' @export
ContentBuilder <- R6::R6Class("ContentBuilder",
  public = list(
    #' @description Buat pembangun
    #' @param theme [LatexTheme]
    #' @param logger [Logger]
    initialize = function(theme, logger = NULL) {
      private$theme <- theme
      private$logger <- logger %||% build_logger(console_level = "warn")
    },
    #' @description Bangun Document dari spec (di-override)
    #' @param spec [ModuleSpec]
    build = function(spec) stop("abstrak: implementasikan di subclass")
  ),
  private = list(theme = NULL, logger = NULL)
)

#' Pembangun modul (menampilkan soal)
#' @export
ModuleBuilder <- R6::R6Class("ModuleBuilder", inherit = ContentBuilder,
  public = list(
    #' @description Bangun Document modul
    #' @param spec [ModuleSpec]
    #' @return objek [Document]
    build = function(spec) {
      private$logger$debug("Bangun modul", modul = spec$number)
      ctx <- RenderContext$new(spec$number)
      # bagian opsional yang tidak diisi pada spec dilewati sepenuhnya
      opsional <- c("tambahan")
      bagian <- Filter(function(s) {
        !(s$id %in% opsional) || length(spec$body[[s$id]]) > 0
      }, spec$sections)
      secs <- purrr::imap_chr(bagian, function(s, i) {
        content <- spec$body[[s$id]]
        rendered <- make_section(s, content)$render(ctx)
        # Bagian berat (Contoh, Latihan, Penugasan) diawali pemisah halaman agar
        # mulai bersih; bagian ringan mengalir menyambung bila masih ada ruang.
        if (i > 1 && s$id %in% c("contoh", "latihan", "penugasan")) {
          paste0("\\newpage\n\n", rendered)
        } else if (i > 1) {
          paste0("\\vspace{1.2em}\n\n", rendered)
        } else {
          rendered
        }
      })
      body <- paste(secs, collapse = "\n\n")
      cover <- private$theme$cover(
        number = spec$number,
        title = toupper(spec$title),
        pertemuan = sprintf("Pertemuan Minggu ke-%s", spec$pertemuan %||% "-"),
        sub_cpmk = spec$sub_cpmk %||% ""
      )
      preamble <- private$theme$preamble(spec$number, spec$topic, variant = "modul", course = spec$course)
      Document$new(spec$number, "modul", spec$short_code, spec$topic,
                   cover, body, preamble)
    }
  )
)

#' Pembangun kunci jawaban (menampilkan solusi) — DRY dari spec yang sama
#' @export
AnswerKeyBuilder <- R6::R6Class("AnswerKeyBuilder", inherit = ContentBuilder,
  public = list(
    #' @description Bangun Document kunci
    #' @param spec [ModuleSpec]
    #' @return objek [Document]
    build = function(spec) {
      private$logger$debug("Bangun kunci", modul = spec$number)
      ctx <- RenderContext$new(spec$number)
      # Proyeksikan hanya solusi latihan/penugasan
      blocks <- character(0)
      blocks <- c(blocks, "# Kunci Jawaban Latihan dan Penugasan")
      for (ex in spec$exercises) {
        safe_txt <- function(x) {
          # Ringkasan solusi berisi prosa dan potongan kode R, bukan LaTeX.
          # Seluruh karakter khusus karena itu diloloskan: tanpa ini, "obj$kolom"
          # membuka mode matematika dan "rho^2" dibaca sebagai pangkat, sehingga
          # kompilasi gagal dengan pesan "Missing $ inserted".
          esc_latex(x)
        }
        # judul + ringkasan solusi dalam kotak kunci
        blocks <- c(blocks,
          sprintf("\\begin{kotakkunci}\n\\textbf{%s} (%s poin)\n\n%s\n\\end{kotakkunci}",
                  safe_txt(ex[["id"]] %||% "Soal"), ex[["points"]] %||% "-",
                  safe_txt(ex[["solution"]] %||% ex[["solution_text"]] %||% "Lihat kode solusi berikut.")))
        # solusi berkode yang dieksekusi (R lalu Python), gaya seperti Contoh
        if (!is.null(ex[["solusi_r"]])) {
          ev <- if (isFALSE(ex[["eval"]])) ", eval=FALSE" else ""
          blocks <- c(blocks,
            ctx$emit_kode(ex[["judul_r"]] %||% "Solusi R", "R"),
            paste0("```{r", ev, "}\n", ex[["solusi_r"]], "\n```"))
        }
        if (!is.null(ex[["solusi_py"]])) {
          ev <- if (isFALSE(ex[["eval"]])) ", eval=FALSE" else ""
          blocks <- c(blocks,
            ctx$emit_kode(ex[["judul_py"]] %||% "Solusi Python", "Python"),
            paste0("```{python", ev, "}\n", ex[["solusi_py"]], "\n```"))
        }
        if (!is.null(ex[["interpretasi"]])) {
          blocks <- c(blocks,
            sprintf("\\begin{kotakinterpretasi}\n%s\n\\end{kotakinterpretasi}",
                    latex_prose_safe(ex[["interpretasi"]])))
        }
      }
      ada_mentah <- !is.null(spec$body[["kunci"]]) && length(spec$body[["kunci"]]) > 0
      if (length(spec$exercises) == 0 && !ada_mentah) {
        blocks <- c(blocks, "_(Belum ada latihan/penugasan pada spesifikasi ini.)_")
      }
      # Blok mentah `body$kunci`: dituliskan APA ADANYA setelah daftar
      # exercises. Diperlukan bagi kunci yang sebagian besar isinya prosa
      # panjang beserta kotak LaTeX -- memaksanya masuk ke medan `solution`
      # akan meloloskan seluruh karakter khusus sehingga perintah LaTeX
      # tercetak sebagai teks biasa.
      if (!is.null(spec$body[["kunci"]]) && length(spec$body[["kunci"]]) > 0) {
        blocks <- c(blocks, unlist(spec$body[["kunci"]], use.names = FALSE))
      }
      blocks <- c(blocks, "# Catatan Penskoran untuk Pengajar",
        "\\begin{kotakinfo}\nToleransi: perbedaan pembulatan dan arah tanda komponen dapat diterima selama interpretasi konsisten.\n\\end{kotakinfo}")
      body <- paste(blocks, collapse = "\n\n")
      cover <- private$theme$cover(
        number = spec$number,
        title = toupper(spec$title),
        pertemuan = "Kunci Jawaban Latihan \\& Penugasan",
        sub_cpmk = "Pegangan dosen dan asisten praktikum.",
        badge = "KUNCI JAWABAN"
      )
      preamble <- private$theme$preamble(spec$number, spec$topic, variant = "kunci", course = spec$course)
      Document$new(spec$number, "kunci", spec$short_code, spec$topic,
                   cover, body, preamble)
    }
  )
)
