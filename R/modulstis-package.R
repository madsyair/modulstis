#' modulstis: Generator Template Modul Praktikum Bernuansa Warna Logo BPS
#'
#' Menghasilkan template modul praktikum dan buku kunci jawaban dari satu
#' spesifikasi deklaratif (YAML/objek), dengan backend bookdown/Quarto + LaTeX
#' (XeLaTeX) untuk PDF bernuansa warna logo BPS. Menerapkan desain berorientasi
#' objek (R6), pipeline fungsional, logging terstruktur, dan kerangka uji.
#'
#' @section Kelas utama:
#' - [ModuleSpec]: spesifikasi modul deklaratif + validasi.
#' - [LatexTheme]: design token BPS + preamble.
#' - [ModuleBuilder] / [AnswerKeyBuilder]: rakit dokumen (Builder).
#' - [Renderer] / [BookdownRenderer] / [QuartoRenderer]: render (Strategy).
#' - [ModuleProject]: orkestrasi end-to-end (Facade).
#' - [Logger]: log terstruktur berjenjang.
#'
#' @keywords internal
#' @importFrom R6 R6Class
#' @importFrom yaml read_yaml
#' @importFrom purrr map
#' @importFrom fs path
"_PACKAGE"

## usethis namespace: start
#' @importFrom stats rnorm
#' @importFrom utils write.csv
## usethis namespace: end
NULL
