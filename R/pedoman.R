#' Buka Buku Pedoman `modulstis`
#'
#' Buku Pedoman *Menyusun Modul Praktikum dengan Paket R `modulstis`* (82 halaman)
#' disertakan sebagai PDF di `inst/pedoman/`, bukan sebagai vignette PDF di
#' `inst/doc/`. Penempatan itu disengaja: `R CMD check` memeriksa ukuran PDF di
#' bawah `inst/doc` dan memberi WARNING bila masih dapat dimampatkan `gs+qpdf`,
#' sedangkan buku ini memuat ilustrasi beresolusi cetak.
#'
#' @param buka bila `TRUE` (bawaan) PDF dibuka dengan pembaca bawaan sistem;
#'   bila `FALSE` hanya path yang dikembalikan
#' @return path berkas PDF (tak tampak bila `buka = TRUE`)
#' @examples
#' # path <- buka_pedoman(buka = FALSE)
#' @export
buka_pedoman <- function(buka = TRUE) {
  path <- system.file("pedoman", "Pedoman_modulstis.pdf", package = "modulstis")
  if (!nzchar(path) || !file.exists(path)) {
    stop("Buku Pedoman tidak ditemukan; pasang ulang paket modulstis.", call. = FALSE)
  }
  if (isTRUE(buka)) {
    if (requireNamespace("rstudioapi", quietly = TRUE) &&
        rstudioapi::isAvailable()) {
      utils::browseURL(path)
    } else {
      utils::browseURL(path)
    }
    return(invisible(path))
  }
  path
}
