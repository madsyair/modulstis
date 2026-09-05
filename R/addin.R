#' Buat berkas kerangka modul praktikum baru
#'
#' Menyalin skeleton R Markdown template modul dan mengisi nomor serta topik.
#' Dapat dipakai langsung (skrip) atau lewat RStudio Add-in.
#'
#' @param number nomor modul
#' @param topic topik/judul modul
#' @param path direktori tujuan (default: direktori kerja)
#' @param open buka berkas di editor RStudio (bila tersedia)
#' @return path berkas .Rmd yang dibuat (tak terlihat)
#' @export
new_module_rmd <- function(number = 1, topic = "Judul Modul Anda",
                           path = ".", open = TRUE) {
  private_scaffold(kind = "modul", number = number, topic = topic,
                   path = path, open = open)
}

#' Buat berkas kerangka kunci jawaban baru
#'
#' @param number nomor modul
#' @param topic topik/judul modul
#' @param path direktori tujuan
#' @param open buka berkas di editor RStudio
#' @return path berkas .Rmd yang dibuat (tak terlihat)
#' @export
new_answerkey_rmd <- function(number = 1, topic = "Judul Modul Anda",
                              path = ".", open = TRUE) {
  private_scaffold(kind = "kunci", number = number, topic = topic,
                   path = path, open = open)
}

# helper internal: salin skeleton template & isi nomor/topik
private_scaffold <- function(kind, number, topic, path, open) {
  tmpl_name <- if (kind == "kunci") "kunci_jawaban" else "modul_praktikum"
  skel <- system.file("rmarkdown", "templates", tmpl_name,
                       "skeleton", "skeleton.Rmd", package = "modulstis")
  if (skel == "" || !file.exists(skel)) {
    skel <- file.path("inst", "rmarkdown", "templates", tmpl_name,
                      "skeleton", "skeleton.Rmd")
  }
  txt <- readLines(skel, warn = FALSE)
  txt <- sub("^nomor_modul <- .*$",
             sprintf("nomor_modul <- %s", number), txt)
  txt <- sub('^topik_modul <- .*$',
             sprintf('topik_modul <- "%s"', topic), txt)
  prefix <- if (kind == "kunci") "Kunci" else "Modul"
  out <- file.path(path, sprintf("%s_%02d_%s.Rmd", prefix,
                                 as.integer(number), slugify(topic)))
  ensure_dir(path)
  writeLines(txt, out)
  if (open && requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(out)
  }
  message(sprintf("Berkas dibuat: %s", out))
  invisible(out)
}

#' Add-in: buat modul praktikum baru (interaktif)
#' @export
addin_new_module <- function() {
  vals <- private_prompt_module()
  new_module_rmd(number = vals$number, topic = vals$topic, path = ".", open = TRUE)
}

#' Add-in: buat kunci jawaban baru (interaktif)
#' @export
addin_new_answerkey <- function() {
  vals <- private_prompt_module()
  new_answerkey_rmd(number = vals$number, topic = vals$topic, path = ".", open = TRUE)
}

#' Add-in: render modul + kunci dari berkas spesifikasi .yml (interaktif)
#' @export
addin_render_spec <- function() {
  if (!requireNamespace("rstudioapi", quietly = TRUE) ||
      !rstudioapi::isAvailable()) {
    stop("Add-in ini memerlukan RStudio.", call. = FALSE)
  }
  yml <- rstudioapi::selectFile(
    caption = "Pilih berkas spesifikasi modul (.yml)",
    filter = "YAML (*.yml)")
  if (is.null(yml)) return(invisible(NULL))
  spec <- module_spec_from_yaml(yml)
  rep <- spec$validate()
  if (!rep$ok) {
    rstudioapi::showDialog("Spesifikasi tidak valid",
      paste(rep$messages, collapse = "<br/>"))
    return(invisible(NULL))
  }
  res <- render_module(spec, backend = "bookdown", theme = "bps",
                       output_dir = "build")
  rstudioapi::showDialog("Selesai",
    sprintf("PDF dibuat:<br/>%s<br/>%s", res$modul$path, res$kunci$path))
  invisible(res)
}

# prompt interaktif (fallback ke default bila bukan RStudio)
private_prompt_module <- function() {
  number <- 1L; topic <- "Judul Modul Anda"
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    n <- rstudioapi::showPrompt("Nomor Modul", "Masukkan nomor modul:", "1")
    t <- rstudioapi::showPrompt("Topik Modul", "Masukkan topik/judul modul:",
                                "Judul Modul Anda")
    if (!is.null(n) && nzchar(n)) number <- suppressWarnings(as.integer(n)) %||% 1L
    if (!is.null(t) && nzchar(t)) topic <- t
  }
  list(number = number %||% 1L, topic = topic)
}
