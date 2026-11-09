#' Palet warna BPS bawaan
#' @export
bps_palette <- function() {
  list(
    navy      = "#123A6B",
    biru      = "#0B6FB4",
    birumuda  = "#6FB3E0",
    oranye    = "#F58220",
    hijau     = "#00A651",
    abuteks   = "#45505C"
  )
}

#' Tema LaTeX bernuansa warna logo BPS
#'
#' Memusatkan seluruh keputusan tampilan sebagai design token dan
#' menghasilkan preamble LaTeX untuk modul maupun kunci jawaban.
#' Mengikuti prinsip DRY: satu sumber tampilan untuk kedua backend
#' (bookdown dan Quarto).
#'
#' @export
LatexTheme <- R6::R6Class("LatexTheme",
  public = list(
    #' @field palette daftar warna (navy, biru, ...)
    palette = NULL,
    #' @field font nama font utama untuk teks dan judul
    font = "Carlito",

    #' @description Buat tema baru
    #' @param palette "bps" atau list warna kustom; unsur yang tidak disebut
    #'   memakai warna bawaan [bps_palette()]
    #' @param font nama font yang terpasang di sistem operasi (bawaan
    #'   `"Carlito"`)
    initialize = function(palette = "bps", font = "Carlito") {
      if (!is.character(font) || length(font) != 1L || !nzchar(font)) {
        stop("font harus berupa satu nama font", call. = FALSE)
      }
      self$font <- font
      if (identical(palette, "bps")) {
        self$palette <- bps_palette()
      } else if (is.list(palette)) {
        self$palette <- modifyList(bps_palette(), palette)
      } else {
        stop("palette harus 'bps' atau list warna", call. = FALSE)
      }
    },

    #' @description Bangun preamble LaTeX lengkap
    #' @param number nomor modul
    #' @param topic topik/judul header
    #' @param variant "modul" atau "kunci"
    #' @param course metadata mata kuliah (matkul, kode, prodi, ...); `NULL`
    #'   memakai nilai bawaan Analisis Peubah Ganda
    #' @return string preamble
    preamble = function(number, topic, variant = c("modul", "kunci"),
                        course = NULL) {
      variant <- match.arg(variant)
      tmpl <- private$read_template()
      label <- if (variant == "kunci") "Kunci Modul" else "Modul"
      aksen <- if (variant == "kunci") "bpshijau" else "bpsoranye"
      # identitas kursus; default = APG demi kompatibilitas mundur
      cc <- modifyList(list(
        matkul = "Analisis Peubah Ganda",
        matkul_besar = "ANALISIS PEUBAH GANDA",
        kode = "K203318",
        ta = "2025/2026",
        semester = "5 (Ganjil)",
        prodi = "D-IV Komputasi Statistik",
        penyusun = "Achmad Syahrul Choir",
        halaman_awal = 1
      ), course %||% list())
      # daftar penyusun boleh berupa vektor; dirangkai dengan koma
      cc$penyusun <- paste(cc$penyusun, collapse = ", ")
      out <- tmpl
      out <- gsub("@@NOMOR@@", as.character(number), out, fixed = TRUE)
      # Judul header dapat memuat karakter khusus LaTeX (mis. "&" pada
      # "Reduksi & Anomali"). Tanpa diloloskan, fancyhdr menafsirkannya
      # sebagai pemisah kolom dan kompilasi gagal.
      out <- gsub("@@TOPIK@@", esc_latex(topic), out, fixed = TRUE)
      out <- gsub("@@LABEL@@", label, out, fixed = TRUE)
      out <- gsub("@@AKSEN@@", aksen, out, fixed = TRUE)
      out <- gsub("@@MATKUL@@", esc_latex(cc$matkul), out, fixed = TRUE)
      out <- gsub("@@MATKULBESAR@@", esc_latex(cc$matkul_besar), out, fixed = TRUE)
      out <- gsub("@@KODEMK@@", cc$kode, out, fixed = TRUE)
      out <- gsub("@@TA@@", cc$ta, out, fixed = TRUE)
      out <- gsub("@@SEMESTER@@", cc$semester, out, fixed = TRUE)
      out <- gsub("@@PRODI@@", esc_latex(cc$prodi), out, fixed = TRUE)
      out <- gsub("@@PENYUSUN@@", cc$penyusun, out, fixed = TRUE)
      out <- gsub("@@HALAWAL@@", as.character(cc$halaman_awal), out, fixed = TRUE)
      out <- private$terapkan_tampilan(out)
      if (variant == "kunci") out <- private$recolor_cover_green(out)
      out
    },

    #' @description Bangun blok kotak berwarna
    #' @param type jenis kotak (info, tujuan, interpretasi, ...)
    #' @param body isi kotak
    #' @param title judul opsional
    #' @return string LaTeX
    box = function(type, body, title = NULL) {
      env <- paste0("kotak", type)
      opt <- if (!is.null(title)) paste0("[", title, "]") else ""
      sprintf("\\begin{%s}%s\n%s\n\\end{%s}", env, opt, body, env)
    },

    #' @description Bangun makro sampul pembatas
    #' @param number nomor modul
    #' @param title judul (huruf besar)
    #' @param pertemuan baris pertemuan
    #' @param sub_cpmk teks sub-CPMK
    #' @param badge label badge opsional (mis. "KUNCI JAWABAN")
    #' @return string pemanggilan \\coverpembatas
    cover = function(number, title, pertemuan, sub_cpmk, badge = NULL) {
      opt <- if (!is.null(badge)) paste0("[", badge, "]") else ""
      # amankan '&' pada teks bebas agar tidak dibaca sebagai tab alignment
      amp <- function(x) gsub("(?<!\\\\)&", "\\\\&", x, perl = TRUE)
      sprintf("\\coverpembatas%s{%s}{%s}{%s}{%s}",
              opt, number, amp(title), amp(pertemuan), amp(sub_cpmk))
    }
  ),
  private = list(
    # Menerapkan palet dan font tema ke preamble. Templat menulis warna BPS
    # dan font Carlito secara tetap; nilai-nilai itu diganti dengan milik tema.
    terapkan_tampilan = function(x) {
      peta <- c(navy = "bpsnavy", biru = "bpsbiru", birumuda = "bpsbirumuda",
                oranye = "bpsoranye", hijau = "bpshijau", abuteks = "abuteks")
      for (k in names(peta)) {
        hex <- toupper(sub("^#", "", self$palette[[k]] %||% ""))
        if (!grepl("^[0-9A-F]{6}$", hex)) {
          stop(sprintf("warna '%s' harus berbentuk heksadesimal enam digit, mis. \"#123A6B\"", k),
               call. = FALSE)
        }
        pola <- sprintf("\\\\definecolor\\{%s\\}\\{HTML\\}\\{[0-9A-Fa-f]{6}\\}", peta[[k]])
        ganti <- sprintf("\\\\definecolor{%s}{HTML}{%s}", peta[[k]], hex)
        x <- sub(pola, ganti, x, perl = TRUE)
      }
      font <- gsub("\\\\", "\\\\\\\\", self$font)
      x <- gsub("\\\\set(main|sans)font\\{Carlito\\}",
                paste0("\\\\set\\1font{", font, "}"), x, perl = TRUE)
      x
    },
    read_template = function() {
      path <- system.file("templates", "preamble.tex.tmpl", package = "modulstis")
      if (path == "" || !file.exists(path)) {
        # fallback saat pengembangan (belum terinstal)
        path <- file.path("inst", "templates", "preamble.tex.tmpl")
      }
      paste(readLines(path, warn = FALSE), collapse = "\n")
    },
    recolor_cover_green = function(x) {
      # ubah pita atas sampul navy/biru -> hijau untuk varian kunci
      x <- gsub(
        "\\fill[bpsnavy] (current page.north west) -- ++(0,-7.4cm) --",
        "\\fill[bpshijau!75!black] (current page.north west) -- ++(0,-7.4cm) --",
        x, fixed = TRUE)
      x <- gsub(
        "\\fill[bpsbiru, opacity=0.9] (current page.north west) -- ++(0,-5.5cm) --",
        "\\fill[bpshijau, opacity=0.9] (current page.north west) -- ++(0,-5.5cm) --",
        x, fixed = TRUE)
      x
    }
  )
)

#' Factory tema
#' @param palette "bps" atau list warna, mis. `list(navy = "#5B2C6F")`
#' @param font nama font yang terpasang di sistem operasi
#' @return objek [LatexTheme]
#' @export
theme_factory <- function(palette = "bps", font = "Carlito") {
  LatexTheme$new(palette = palette, font = font)
}
