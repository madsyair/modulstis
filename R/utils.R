#' Utilitas internal
#'
#' @keywords internal
#' @noRd
NULL

#' Escape karakter khusus LaTeX pada teks biasa
#' @param x karakter
#' @return karakter ter-escape
#' @export
esc_latex <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x
}

#' Escape hanya garis bawah (untuk nama berkas/variabel dalam teks)
#' @param x karakter
#' @export
esc_underscore <- function(x) gsub("_", "\\\\_", x)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

#' Gabungkan potongan teks dengan pemisah baris ganda
#' @param ... potongan karakter
#' @noRd
join_blocks <- function(...) {
  parts <- unlist(list(...))
  parts <- parts[!vapply(parts, is.null, logical(1))]
  paste(parts, collapse = "\n\n")
}

#' Pastikan direktori ada
#' @param path path direktori
#' @noRd
ensure_dir <- function(path) {
  if (!fs::dir_exists(path)) fs::dir_create(path, recurse = TRUE)
  invisible(path)
}

#' Slug aman untuk nama berkas
#' @param x karakter
#' @noRd
slugify <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_|_$", "", x)
}

#' Amankan teks prosa yang disisipkan ke dalam kotak LaTeX mentah.
#' Mengubah `kode` (backtick markdown) menjadi perintah `\\texttt{}` LaTeX lalu meng-escape
#' underscore telanjang agar tidak memicu mode matematika. Pendekatan token demi
#' token agar seluruh teks terjaga.
#' @param x karakter
#' @return karakter aman-LaTeX
#' @export
latex_prose_safe <- function(x) {
  if (is.null(x) || length(x) == 0) return(x)
  one <- function(s) {
    s <- as.character(s)
    # pisahkan menjadi token: `...` (kode) atau teks biasa
    pieces <- regmatches(s, gregexpr("`[^`]+`|[^`]+", s, perl = TRUE))[[1]]
    out <- vapply(pieces, function(p) {
      if (startsWith(p, "`") && endsWith(p, "`")) {
        inner <- substr(p, 2, nchar(p) - 1)
        inner <- gsub("(?<!\\\\)([_%$&#])", "\\\\\\1", inner, perl = TRUE)
        # ^ dan ~ bukan sekadar karakter khusus: keduanya berdiri sendiri
        # sebagai perintah, sehingga menuntut bentuk \\textasciicircum{}
        # dan \\textasciitilde{} --- bukan penambahan garis miring.
        inner <- gsub("(?<!\\\\)\\^", "\\\\textasciicircum{}", inner, perl = TRUE)
        inner <- gsub("(?<!\\\\)~", "\\\\textasciitilde{}", inner, perl = TRUE)
        paste0("\\texttt{", inner, "}")
      } else {
        # escape karakter khusus LaTeX yang belum ter-escape
        p <- gsub("(?<!\\\\)([_%$&#])", "\\\\\\1", p, perl = TRUE)
        p <- gsub("(?<!\\\\)\\^", "\\\\textasciicircum{}", p, perl = TRUE)
        gsub("(?<!\\\\)~", "\\\\textasciitilde{}", p, perl = TRUE)
      }
    }, character(1), USE.NAMES = FALSE)
    paste0(out, collapse = "")
  }
  vapply(x, one, character(1), USE.NAMES = FALSE)
}

# data.table memeriksa penanda ini pada paket pemanggil sebelum mengaktifkan
# sintaks khasnya (mis. `dt[, list(...), by = ...]`). Tanpa penanda, `[` jatuh
# kembali ke perilaku data.frame sehingga kode modul yang memakai data.table
# gagal dijalankan saat render dipanggil dari dalam paket ini.
.datatable.aware <- TRUE
