#' Bangkitkan data simulasi dari resep (recipe)
#'
#' Mendukung `kind`:
#' - `mvn`: multivariat normal satu kelompok
#' - `grouped_mvn`: multivariat normal antar kelompok (ragam sama)
#' - `tabular`: peubah numerik/kategorik campuran (uniform/normal/kategori) untuk
#'   modul pemrograman & inferensia dasar
#' - `categorical`: beberapa peubah nominal dari arketipe laten (untuk MCA)
#' - `latent_class`: butir kategorik integer dari kelas laten (untuk LCA)
#' - `file`: **memakai berkas data nyata apa adanya**, tanpa simulasi
#'
#' @param recipe list resep mentah hasil pembacaan YAML
#' @return list resep dengan nama kunci yang sudah dibakukan
#' @keywords internal
normalize_recipe_names <- function(recipe) {
  nm <- names(recipe)
  if (is.null(nm)) return(recipe)
  # YAML 1.1: kunci telanjang `n` terbaca sebagai logical FALSE sehingga namanya
  # menjadi "FALSE"; kembalikan menjadi "n" agar ukuran contoh tetap terbaca.
  nm[nm %in% c("FALSE", "false")] <- "n"
  names(recipe) <- nm
  recipe
}

#' Bangkitkan satu data.frame dari resep data
#'
#' Menerjemahkan resep deklaratif (`kind`, `n`, `seed`, `columns`) menjadi
#' data.frame simulasi yang reprodusibel.
#'
#' Untuk `kind: file`, data \strong{tidak} dibangkitkan melainkan dibaca dari berkas
#' yang ditunjuk `path` (CSV, TSV, atau RDS). Path relatif dihitung terhadap letak
#' berkas spesifikasi YAML bila spesifikasi dimuat dengan [module_spec_from_yaml()],
#' atau terhadap direktori kerja bila resep dibuat langsung di R.
#'
#' @param recipe list resep (kind, n, seed, columns, ...)
#' @return data.frame
#' @export
generate_dataset <- function(recipe) {
  recipe <- normalize_recipe_names(recipe)
  kind <- recipe$kind %||% "mvn"
  seed <- recipe$seed %||% 2025
  set.seed(seed)
  switch(kind,
    mvn = private_gen_mvn(recipe),
    grouped_mvn = private_gen_grouped_mvn(recipe),
    tabular = private_gen_tabular(recipe),
    categorical = private_gen_categorical(recipe),
    latent_class = private_gen_latent_class(recipe),
    file = private_gen_file(recipe),
    stop(sprintf("recipe.kind '%s' tidak dikenal", kind), call. = FALSE)
  )
}

# ---- tabular: peubah numerik/kategorik campuran ----
# recipe$columns: named list; tiap kolom {type: numeric|integer|category,
#   dan parameter: min/max (numeric/integer) atau levels+probs (category)}
private_gen_tabular <- function(recipe) {
  n <- recipe$n %||% 100
  cols <- recipe$columns
  if (is.null(cols)) {
    # fallback: seluruh vars sebagai numeric uniform 0..100
    cols <- stats::setNames(
      lapply(recipe$vars, function(v) list(type = "numeric", min = 0, max = 100)),
      recipe$vars)
  }
  out <- lapply(names(cols), function(nm) {
    c1 <- cols[[nm]]; type <- c1$type %||% "numeric"
    if (type == "numeric") {
      round(stats::runif(n, c1$min %||% 0, c1$max %||% 1), c1$digits %||% 2)
    } else if (type == "integer") {
      as.integer(round(stats::runif(n, c1$min %||% 0, c1$max %||% 100)))
    } else if (type == "category") {
      lv <- c1$levels; pr <- c1$probs %||% rep(1 / length(lv), length(lv))
      factor(sample(lv, n, replace = TRUE, prob = pr), levels = lv)
    } else if (type == "balanced") {
      # Taraf diulang berimbang (rancangan faktorial). Argumen `each` menentukan
      # panjang blok pengulangan; bawaannya 1 sehingga taraf berselang-seling.
      lv <- c1$levels
      each <- c1$each %||% 1
      pola <- rep(rep(lv, each = each), length.out = n)
      factor(pola, levels = lv)
    } else {
      stop(sprintf("tipe kolom '%s' tidak dikenal", type), call. = FALSE)
    }
  })
  df <- as.data.frame(out, stringsAsFactors = FALSE)
  names(df) <- names(cols)
  df
}

# ---- categorical: peubah nominal dari arketipe laten (untuk MCA) ----
# recipe$archetypes: named list arketipe -> prob; recipe$vars: named list
#   var -> (named list arketipe -> named prob kategori)
private_gen_categorical <- function(recipe) {
  n <- recipe$n %||% 200
  arche <- recipe$archetypes
  if (is.null(arche) || is.null(recipe$vars_probs)) {
    # fallback sederhana: tiap var kategori seragam
    vars <- recipe$vars
    df <- as.data.frame(lapply(vars, function(v)
      factor(sample(paste0(v, 1:3), n, replace = TRUE))), stringsAsFactors = TRUE)
    names(df) <- vars
    return(df)
  }
  a <- sample(names(arche), n, replace = TRUE, prob = unlist(arche))
  vp <- recipe$vars_probs
  out <- lapply(names(vp), function(v) {
    per_arche <- vp[[v]]
    vapply(a, function(ai) {
      pr <- per_arche[[ai]]
      sample(names(pr), 1, prob = unlist(pr))
    }, character(1))
  })
  df <- as.data.frame(lapply(out, factor), stringsAsFactors = TRUE)
  names(df) <- names(vp)
  df
}

# ---- latent_class: butir kategorik integer 1..K dari kelas laten (untuk LCA) ----
# recipe$classes: named list kelas -> prob; recipe$items: named list
#   item -> (named list kelas -> vektor prob kategori 1..K)
private_gen_latent_class <- function(recipe) {
  n <- recipe$n %||% 300
  classes <- recipe$classes
  items <- recipe$items
  if (is.null(classes) || is.null(items)) {
    stop("recipe latent_class perlu 'classes' dan 'items'", call. = FALSE)
  }
  z <- sample(names(classes), n, replace = TRUE, prob = unlist(classes))
  out <- lapply(names(items), function(it) {
    per_class <- items[[it]]
    vapply(z, function(zi) {
      pr <- per_class[[zi]]
      sample(seq_along(pr), 1, prob = pr)
    }, integer(1))
  })
  df <- as.data.frame(out)
  names(df) <- names(items)
  df
}

# generator MVN sederhana tanpa dependensi MASS (Cholesky)
.rmvn <- function(n, mu, Sigma) {
  p <- length(mu)
  L <- chol(Sigma)
  Z <- matrix(stats::rnorm(n * p), n, p)
  sweep(Z %*% L, 2, mu, `+`)
}

private_gen_mvn <- function(recipe) {
  vars <- recipe$vars
  p <- length(vars)
  mu <- recipe$mu %||% rep(0, p)
  Sigma <- recipe$Sigma %||% diag(p)
  n <- recipe$n %||% 100
  X <- .rmvn(n, mu, matrix(unlist(Sigma), p, p))
  df <- as.data.frame(round(X, 3))
  names(df) <- vars
  df
}

private_gen_grouped_mvn <- function(recipe) {
  vars <- recipe$vars
  p <- length(vars)
  groups <- recipe$groups           # named list: nama -> ukuran
  Sigma <- recipe$Sigma %||% diag(p)
  Sigma <- matrix(unlist(Sigma), p, p)
  # mean per kelompok: gunakan means bila ada, else geser sepanjang gradien
  means <- recipe$means
  gnames <- names(groups)
  out <- purrr::imap(groups, function(nsize, gname) {
    mu <- if (!is.null(means) && !is.null(means[[gname]])) {
      means[[gname]]
    } else {
      idx <- match(gname, gnames)
      rep(idx, p)   # placeholder gradien
    }
    X <- .rmvn(nsize, mu, Sigma)
    d <- as.data.frame(round(X, 3)); names(d) <- vars
    d$kelompok <- gname
    d
  })
  df <- do.call(rbind, out)
  df$kelompok <- factor(df$kelompok, levels = gnames)
  df[, c("kelompok", vars)]
}

# ---- file: memakai berkas data nyata, tanpa simulasi ----
# recipe$path   : letak berkas (.csv/.csv2/.tsv/.txt/.rds); wajib
# recipe$columns: (opsional) nama kolom yang dipakai, sekaligus urutannya
# recipe$rename : (opsional) peta nama lama -> nama baru
# recipe$n      : (opsional) ambil n baris pertama saja
# recipe$na     : (opsional) penanda nilai hilang, mis. c("", "NA", "-")
private_gen_file <- function(recipe) {
  path <- recipe$path %||% recipe$file %||%
    stop("recipe.kind 'file' menuntut `path`", call. = FALSE)
  path <- resolve_data_path(path, recipe$base_dir)
  if (!file.exists(path)) {
    stop(sprintf("berkas data tidak ditemukan: %s", path), call. = FALSE)
  }
  ext <- tolower(tools::file_ext(path))
  na_str <- recipe$na %||% c("NA", "")
  df <- switch(ext,
    rds  = readRDS(path),
    tsv  = utils::read.delim(path, na.strings = na_str, stringsAsFactors = FALSE),
    txt  = utils::read.delim(path, na.strings = na_str, stringsAsFactors = FALSE),
    csv2 = utils::read.csv2(path, na.strings = na_str, stringsAsFactors = FALSE),
    utils::read.csv(path, na.strings = na_str, stringsAsFactors = FALSE)
  )
  df <- as.data.frame(df, stringsAsFactors = FALSE)

  if (!is.null(recipe$columns)) {
    kol <- unlist(recipe$columns, use.names = FALSE)
    hilang <- setdiff(kol, names(df))
    if (length(hilang)) {
      stop(sprintf("kolom tidak ada pada %s: %s", basename(path),
                   paste(hilang, collapse = ", ")), call. = FALSE)
    }
    df <- df[, kol, drop = FALSE]
  }
  if (!is.null(recipe$rename)) {
    for (lama in names(recipe$rename)) {
      if (lama %in% names(df)) names(df)[names(df) == lama] <- recipe$rename[[lama]]
    }
  }
  n <- recipe$n %||% NULL
  if (!is.null(n) && is.numeric(n) && n > 0 && n < nrow(df)) {
    df <- df[seq_len(n), , drop = FALSE]
  }
  rownames(df) <- NULL
  df
}

#' Selesaikan path berkas data relatif terhadap letak spesifikasi
#'
#' @param path path pada resep
#' @param base_dir direktori acuan (biasanya letak berkas YAML); `NULL` berarti
#'   direktori kerja
#' @return path yang sudah diselesaikan
#' @keywords internal
resolve_data_path <- function(path, base_dir = NULL) {
  if (is.null(base_dir) || !nzchar(base_dir)) return(path)
  if (grepl("^(/|[A-Za-z]:)", path)) return(path)   # sudah absolut
  file.path(base_dir, path)
}

#' Bangkitkan seluruh dataset sebuah spec
#' @param spec [ModuleSpec]
#' @param output_dir direktori untuk menulis CSV (opsional)
#' @return list data.frame bernama
#' @export
generate_module_data <- function(spec, output_dir = NULL) {
  res <- purrr::map(spec$datasets, function(ds) {
    df <- generate_dataset(ds$recipe)
    if (!is.null(output_dir)) {
      ensure_dir(file.path(output_dir, "data"))
      utils::write.csv(df, file.path(output_dir, "data", paste0(ds$name, ".csv")),
                       row.names = FALSE)
    }
    df
  })
  names(res) <- vapply(spec$datasets, function(d) d$name, character(1))
  res
}
