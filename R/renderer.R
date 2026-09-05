#' Artefak hasil render
#' @export
Artifact <- R6::R6Class("Artifact",
  public = list(
    #' @field path path berkas hasil
    path = NULL,
    #' @field kind jenis artefak
    kind = NULL,
    #' @description Buat artefak
    #' @param path path
    #' @param kind jenis
    initialize = function(path, kind = "pdf") {
      self$path <- path; self$kind <- kind
    }
  )
)

#' Renderer (antarmuka Strategy)
#'
#' Semua renderer menyediakan `$render(doc, output_dir)` yang mengubah
#' [Document] abstrak menjadi PDF. Implementasi dapat saling menggantikan.
#'
#' @export
Renderer <- R6::R6Class("Renderer",
  public = list(
    #' @description Buat renderer
    #' @param theme [LatexTheme]
    #' @param logger [Logger]
    initialize = function(theme, logger = NULL) {
      private$theme <- theme
      private$logger <- logger %||% build_logger()
    },
    #' @description Render dokumen (di-override)
    #' @param doc [Document]
    #' @param output_dir direktori keluaran
    render = function(doc, output_dir) stop("abstrak: implementasikan di subclass")
  ),
  private = list(
    theme = NULL,
    logger = NULL,
    rmd_yaml = function(header_file) {
      paste0(
        "---\n",
        "output:\n",
        "  pdf_document:\n",
        "    latex_engine: xelatex\n",
        "    number_sections: true\n",
        "    fig_caption: true\n",
        "    includes:\n",
        "      in_header: ", header_file, "\n",
        "geometry: \"left=2.6cm,right=2.4cm,top=3.0cm,bottom=2.4cm\"\n",
        "fontsize: 11pt\n",
        "urlcolor: blue\n",
        "---\n"
      )
    },
    setup_chunk = function() {
      paste0(
        "```{r setup, include=FALSE}\n",
        "knitr::opts_chunk$set(echo=TRUE, warning=FALSE, message=FALSE, comment=\"\",\n",
        "  fig.align=\"center\", fig.pos=\"H\", out.width=\"88%\")\n",
        "options(width=95, digits=4, scipen=999)\n",
        "knitr::knit_hooks$set(output = function(x, options) {\n",
        "  paste0(\"\\\\begin{routbox}\\n\\\\begin{verbatim}\\n\", x, ",
        "\"\\\\end{verbatim}\\n\\\\end{routbox}\\n\")\n",
        "})\n",
        "```\n"
      )
    },
    assemble_rmd_body = function(doc, header_file) {
      paste0(
        private$rmd_yaml(header_file), "\n",
        private$setup_chunk(), "\n",
        doc$cover, "\n\n",
        "\\tableofcontents\n\\thispagestyle{fancy}\n\\newpage\n\n",
        doc$body, "\n"
      )
    }
  )
)

#' Renderer bookdown
#' @export
BookdownRenderer <- R6::R6Class("BookdownRenderer", inherit = Renderer,
  public = list(
    #' @description Render via rmarkdown/bookdown
    #' @param doc [Document]
    #' @param output_dir direktori keluaran
    #' @return objek [Artifact]
    render = function(doc, output_dir) {
      ensure_dir(output_dir)
      stem <- sprintf("%s_%02d_%s",
                      if (doc$kind == "kunci") "Kunci" else "Modul",
                      doc$number, doc$short_code)
      header_file <- "preamble.tex"
      writeLines(doc$preamble, file.path(output_dir, header_file))
      rmd_path <- file.path(output_dir, paste0(stem, ".Rmd"))
      writeLines(private$assemble_rmd_body(doc, header_file), rmd_path)
      private$logger$info("Render (bookdown/rmarkdown)", modul = doc$number,
                          jenis = doc$kind)
      if (!requireNamespace("rmarkdown", quietly = TRUE)) {
        private$logger$warn("rmarkdown tidak tersedia; hanya menulis .Rmd")
        return(Artifact$new(rmd_path, "rmd"))
      }
      # Render dengan keep_tex agar cover TikZ (remember-picture) dapat
      # diankan lewat dua lintasan xelatex. Bila lintasan tunggal rmarkdown
      # gagal (mis. pesan fclose semu), .tex tetap tertulis dan dipulihkan
      # oleh dua lintasan xelatex di bawah.
      fmt <- rmarkdown::pdf_document(
        latex_engine = "xelatex", number_sections = TRUE, keep_tex = TRUE,
        includes = rmarkdown::includes(in_header = header_file))
      out <- tryCatch(
        rmarkdown::render(rmd_path, output_format = fmt,
                          quiet = TRUE, output_dir = output_dir),
        error = function(e) {
          private$logger$warn("render tunggal gagal; memulihkan via 2x xelatex",
                              modul = doc$number, pesan = conditionMessage(e))
          NA_character_
        })
      tex <- file.path(output_dir, paste0(stem, ".tex"))
      if (file.exists(tex)) private$xelatex_twice(tex, output_dir)
      pdf <- file.path(output_dir, paste0(stem, ".pdf"))
      if (!file.exists(pdf)) {
        stop(sprintf("Render gagal: PDF tidak dihasilkan untuk modul %s", doc$number),
             call. = FALSE)
      }
      Artifact$new(pdf, "pdf")
    }
  ),
  private = list(
    # dua lintasan xelatex agar sampul penuh (remember-picture anchoring)
    xelatex_twice = function(tex, output_dir) {
      xe <- Sys.which("xelatex")
      if (!nzchar(xe)) return(invisible(FALSE))
      oldwd <- getwd()
      on.exit(setwd(oldwd), add = TRUE)
      setwd(output_dir)
      texfile <- basename(tex)
      for (i in 1:2) {
        try(system2(xe, c("-interaction=nonstopmode", "-halt-on-error=false",
                          shQuote(texfile)), stdout = FALSE, stderr = FALSE),
            silent = TRUE)
      }
      invisible(TRUE)
    }
  )
)

#' Renderer Quarto
#' @export
QuartoRenderer <- R6::R6Class("QuartoRenderer", inherit = Renderer,
  public = list(
    #' @description Render via Quarto
    #' @param doc [Document]
    #' @param output_dir direktori keluaran
    #' @return objek [Artifact]
    render = function(doc, output_dir) {
      ensure_dir(output_dir)
      stem <- sprintf("%s_%02d_%s",
                      if (doc$kind == "kunci") "Kunci" else "Modul",
                      doc$number, doc$short_code)
      header_file <- "preamble.tex"
      writeLines(doc$preamble, file.path(output_dir, header_file))
      qmd_yaml <- paste0(
        "---\n",
        "format:\n  pdf:\n    pdf-engine: xelatex\n",
        "    number-sections: true\n",
        "    include-in-header: ", header_file, "\n",
        "    geometry: [left=2.6cm,right=2.4cm,top=3.0cm,bottom=2.4cm]\n",
        "fontsize: 11pt\n---\n"
      )
      qmd_body <- paste0(
        qmd_yaml, "\n", private$setup_chunk(), "\n",
        doc$cover, "\n\n\\tableofcontents\n\\newpage\n\n", doc$body, "\n"
      )
      qmd_path <- file.path(output_dir, paste0(stem, ".qmd"))
      writeLines(qmd_body, qmd_path)
      private$logger$info("Render (quarto)", modul = doc$number, jenis = doc$kind)
      if (!requireNamespace("quarto", quietly = TRUE) ||
          is.null(quarto::quarto_path())) {
        private$logger$warn("Quarto tidak tersedia; hanya menulis .qmd")
        return(Artifact$new(qmd_path, "qmd"))
      }
      quarto::quarto_render(qmd_path, quiet = TRUE)
      pdf <- sub("\\.qmd$", ".pdf", qmd_path)
      Artifact$new(pdf, "pdf")
    }
  )
)

#' Factory renderer (memilih strategi backend saat runtime)
#' @param backend "bookdown" atau "quarto"
#' @param theme [LatexTheme]
#' @param logger [Logger]
#' @return objek turunan [Renderer]
#' @export
renderer_factory <- function(backend = c("bookdown", "quarto"), theme, logger = NULL) {
  backend <- match.arg(backend)
  cls <- switch(backend, bookdown = BookdownRenderer, quarto = QuartoRenderer)
  cls$new(theme = theme, logger = logger)
}
