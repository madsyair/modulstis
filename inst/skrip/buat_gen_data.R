#!/usr/bin/env Rscript
# ============================================================================
# buat_gen_data.R
#
# Membangkitkan berkas gen_data.R yang BENAR-BENAR mereproduksi data modul,
# diturunkan langsung dari resep pada spesifikasi YAML.
#
# Latar belakang: gen_data.R lama ditulis tangan sehingga tidak lagi sejalan
# dengan resep pada spesifikasi -- menjalankannya menghasilkan data yang
# berbeda dari berkas .csv yang dikirimkan. Skrip ini menutup celah tersebut
# dengan menuliskan kode yang mengikuti persis urutan pembangkitan pada
# generate_dataset(): satu set.seed di awal, lalu tiap kolom dibangkitkan
# berurutan sesuai tipenya.
#
# Pemakaian:
#   Rscript buat_gen_data.R <folder_modul>
# ============================================================================

suppressMessages(library(yaml))

# --- penulis potongan kode untuk satu kolom ------------------------------
kode_kolom <- function(nama, k) {
  tipe <- k$type %||% "numeric"
  if (tipe == "numeric") {
    sprintf('  %s = round(runif(n, %s, %s), %s),',
            nama, k$min %||% 0, k$max %||% 1, k$digits %||% 2)
  } else if (tipe == "integer") {
    sprintf('  %s = as.integer(round(runif(n, %s, %s))),',
            nama, k$min %||% 0, k$max %||% 100)
  } else if (tipe == "category") {
    lv <- paste0('"', k$levels, '"', collapse = ", ")
    pr <- if (!is.null(k$probs)) paste(k$probs, collapse = ", ")
          else paste(rep(round(1/length(k$levels), 6), length(k$levels)), collapse = ", ")
    sprintf('  %s = factor(sample(c(%s), n, replace = TRUE, prob = c(%s)),\n                    levels = c(%s)),',
            nama, lv, pr, lv)
  } else if (tipe == "balanced") {
    lv <- paste0('"', k$levels, '"', collapse = ", ")
    sprintf('  %s = factor(rep(rep(c(%s), each = %s), length.out = n),\n                    levels = c(%s)),',
            nama, lv, k$each %||% 1, lv)
  } else {
    stop("tipe kolom tidak dikenal: ", tipe)
  }
}

`%||%` <- function(a, b) if (is.null(a)) b else a

buat <- function(dir_modul) {
  yml <- list.files(dir_modul, "\\.yml$", full.names = TRUE)[1]
  if (is.na(yml)) return(invisible(FALSE))
  spec <- yaml::read_yaml(yml)
  ds <- spec$datasets
  if (is.null(ds) || !length(ds)) return(invisible(FALSE))

  baris <- c(
    "# ============================================================================",
    sprintf("# gen_data.R - Data simulasi Modul %s: %s", spec$number, spec$title),
    sprintf("# Mata kuliah %s (%s), Program Studi %s.",
            spec$course$matkul %||% "-", spec$course$kode %||% "-",
            spec$course$prodi %||% "-"),
    "#",
    "# Skrip ini diturunkan langsung dari resep pada berkas spesifikasi, sehingga",
    "# menjalankannya menghasilkan berkas .csv yang identik dengan yang dikirimkan.",
    "#",
    "# CATATAN: seluruh data adalah SIMULASI, bukan data resmi BPS.",
    "# ============================================================================",
    "",
    'dir.create("data", showWarnings = FALSE)',
    ""
  )

  for (d in ds) {
    r <- d$recipe
    # kunci `n` pada YAML 1.1 terbaca sebagai FALSE; kembalikan namanya
    nm <- names(r); nm[nm %in% c("FALSE", "false")] <- "n"; names(r) <- nm
    baris <- c(baris,
      sprintf("# --- %s (peran: %s) ---", d$name, d$role %||% "-"),
      sprintf("set.seed(%s)", r$seed %||% 2025),
      sprintf("n <- %s", r$n %||% 100),
      sprintf("%s <- data.frame(", d$name),
      vapply(names(r$columns), function(nm2) kode_kolom(nm2, r$columns[[nm2]]),
             character(1), USE.NAMES = FALSE),
      "  stringsAsFactors = FALSE",
      ")",
      sprintf('write.csv(%s, "data/%s.csv", row.names = FALSE)', d$name, d$name),
      sprintf('cat("  data/%s.csv :", nrow(%s), "baris x", ncol(%s), "kolom\\n")',
              d$name, d$name, d$name),
      ""
    )
  }
  baris <- c(baris, 'cat("Data simulasi selesai dibangkitkan.\\n")')

  writeLines(baris, file.path(dir_modul, "gen_data.R"))
  invisible(TRUE)
}

arg <- commandArgs(trailingOnly = TRUE)
if (length(arg)) {
  for (d in arg) {
    ok <- buat(d)
    message(if (isTRUE(ok)) "  dibuat: " else "  dilewati: ", basename(d))
  }
}
