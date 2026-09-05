#' Muat bank istilah (glosarium)
#'
#' Membaca bank istilah Analisis Peubah Ganda dari berkas YAML bawaan package
#' atau berkas kustom.
#'
#' @param path path YAML glosarium; default bawaan package
#' @return list istilah (tiap elemen: istilah, inggris, definisi, kbbi, topik)
#' @export
load_glossary <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("glossary", "istilah_apg.yml", package = "modulstis")
    if (path == "" || !file.exists(path)) {
      path <- file.path("inst", "glossary", "istilah_apg.yml")
    }
  }
  raw <- yaml::read_yaml(path)
  raw$istilah %||% list()
}

#' Saring istilah berdasarkan topik
#'
#' @param terms list istilah (dari [load_glossary])
#' @param topics vektor topik yang disertakan; "umum" selalu disertakan.
#'   `NULL` berarti semua istilah.
#' @return list istilah tersaring
#' @export
filter_glossary <- function(terms, topics = NULL) {
  if (is.null(topics)) return(terms)
  keep <- c("umum", topics)
  Filter(function(t) (t$topik %||% "umum") %in% keep, terms)
}

# amankan karakter khusus LaTeX pada teks glosarium (text mode)
.gloss_esc <- function(x) {
  if (is.null(x)) return("")
  x <- gsub("(?<!\\\\)&", "\\\\&", x, perl = TRUE)
  gsub("(?<!\\\\)_", "\\\\_", x, perl = TRUE)
}

#' Bangun blok LaTeX Daftar Istilah
#'
#' Menyusun daftar istilah (terurut abjad) sebagai blok LaTeX memakai perintah
#' `\istilahitem` dan `\istilahkbbi` dari tema. Istilah baku KBBI/glosarium yang
#' jarang dipakai umum ditandai baris "KBBI:".
#'
#' @param terms list istilah (dari [load_glossary] / [filter_glossary])
#' @param heading judul bagian (default "Daftar Istilah")
#' @return string LaTeX/Markdown
#' @export
glossary_latex <- function(terms, heading = "Daftar Istilah") {
  # urutkan abjad menurut istilah
  ord <- order(vapply(terms, function(t) tolower(t$istilah), character(1)))
  terms <- terms[ord]
  items <- vapply(terms, function(t) {
    s <- sprintf("\\istilahitem{%s}{%s}{%s}",
                 .gloss_esc(t$istilah), .gloss_esc(t$inggris %||% ""),
                 .gloss_esc(t$definisi %||% ""))
    if (!is.null(t$kbbi)) {
      s <- paste0(s, "\n\\istilahkbbi{", .gloss_esc(t$kbbi), "}")
    }
    s
  }, character(1))
  body <- paste0(
    "\\begin{kotakistilah}\n",
    "{\\small\\itshape Istilah bertanda \\textbf{\\color{bpsoranye}KBBI} adalah ",
    "bentuk baku menurut KBBI/glosarium yang masih jarang dipakai secara umum.}\\par\\vspace{6pt}\n",
    paste(items, collapse = "\n"),
    "\n\\end{kotakistilah}"
  )
  paste0("# ", heading, "\n\n", body)
}

#' Bagian Daftar Istilah (Section)
#'
#' Bila `content` kosong, otomatis memakai bank istilah bawaan (disaring
#' menurut `spec$topic` bila relevan).
#'
#' @export
GlossarySection <- R6::R6Class("GlossarySection", inherit = Section,
  public = list(
    #' @description Render isi daftar istilah
    #' @param ctx [RenderContext]
    render_body = function(ctx) {
      terms <- self$content
      if (is.null(terms) || length(terms) == 0) {
        terms <- load_glossary()
      }
      # keluarkan hanya bagian body (tanpa heading, karena Section$render sudah menambah judul)
      block <- glossary_latex(terms, heading = "")
      sub("^#\\s*\n\n", "", block)
    }
  )
)
