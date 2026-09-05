#' Logger terstruktur berjenjang
#'
#' Pembungkus logging ringan dengan antarmuka yang kompatibel dengan `lgr`.
#' Mendukung level trace/debug/info/warn/error/fatal, appender konsol dan
#' berkas, field terstruktur, serta pengukuran waktu (`with_timing`).
#'
#' @export
Logger <- R6::R6Class("Logger",
  public = list(
    #' @field name nama logger
    name = NULL,

    #' @description Buat logger baru
    #' @param name nama logger
    #' @param console_level ambang level untuk konsol
    #' @param logfile path berkas log (opsional)
    #' @param file_level ambang level untuk berkas
    initialize = function(name = "modulstis",
                          console_level = "info",
                          logfile = NULL,
                          file_level = "trace") {
      self$name <- name
      private$console_level <- private$level_num(console_level)
      private$file_level <- private$level_num(file_level)
      private$logfile <- logfile
      if (!is.null(logfile)) ensure_dir(fs::path_dir(logfile))
    },

    #' @description Log level trace
    #' @param msg pesan
    #' @param ... field terstruktur
    trace = function(msg, ...) private$emit("trace", msg, ...),
    #' @description Log level debug
    #' @param msg pesan
    #' @param ... field terstruktur
    debug = function(msg, ...) private$emit("debug", msg, ...),
    #' @description Log level info
    #' @param msg pesan
    #' @param ... field terstruktur
    info  = function(msg, ...) private$emit("info", msg, ...),
    #' @description Log level warn
    #' @param msg pesan
    #' @param ... field terstruktur
    warn  = function(msg, ...) private$emit("warn", msg, ...),
    #' @description Log level error
    #' @param msg pesan
    #' @param ... field terstruktur
    error = function(msg, ...) private$emit("error", msg, ...),
    #' @description Log level fatal
    #' @param msg pesan
    #' @param ... field terstruktur
    fatal = function(msg, ...) private$emit("fatal", msg, ...),

    #' @description Jalankan ekspresi sambil mencatat durasinya
    #' @param label label kegiatan
    #' @param expr ekspresi yang dievaluasi
    #' @param ... field terstruktur
    with_timing = function(label, expr, ...) {
      t0 <- Sys.time()
      private$emit("info", paste(label, "mulai"), ...)
      res <- force(expr)
      dur <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)
      private$emit("info", paste(label, "selesai"), ..., durasi_dtk = dur)
      invisible(res)
    }
  ),
  private = list(
    console_level = 3L,
    file_level = 1L,
    logfile = NULL,
    levels = c(trace = 1L, debug = 2L, info = 3L, warn = 4L, error = 5L, fatal = 6L),

    level_num = function(x) {
      if (is.numeric(x)) return(as.integer(x))
      out <- private$levels[[tolower(x)]]
      if (is.null(out)) 3L else out
    },

    fmt_fields = function(fields) {
      if (length(fields) == 0) return("")
      kv <- vapply(names(fields), function(k) {
        paste0(k, "=", format(fields[[k]]))
      }, character(1))
      paste0(" ", paste(kv, collapse = " "))
    },

    emit = function(level, msg, ...) {
      lvl <- private$level_num(level)
      fields <- list(...)
      ts <- format(Sys.time(), "%H:%M:%S")
      line <- sprintf("%-5s [%s] %s%s",
                      toupper(level), ts, msg, private$fmt_fields(fields))
      if (lvl >= private$console_level) {
        con <- if (lvl >= private$levels[["warn"]]) stderr() else stdout()
        cat(line, "\n", file = con, sep = "")
      }
      if (!is.null(private$logfile) && lvl >= private$file_level) {
        cat(line, "\n", file = private$logfile, append = TRUE, sep = "")
      }
      invisible(NULL)
    }
  )
)

#' Bangun logger standar
#' @param name nama logger
#' @param console_level ambang konsol
#' @param logfile path berkas log (opsional)
#' @return objek [Logger]
#' @export
build_logger <- function(name = "modulstis", console_level = "info", logfile = NULL) {
  Logger$new(name = name, console_level = console_level, logfile = logfile)
}
