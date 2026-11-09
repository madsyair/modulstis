# render_all() harus menyiapkan data di folder modul walaupun generate_data()
# tidak dipanggil lebih dahulu. Sebelum 0.3.11, data hanya disalin ke folder
# kunci, sehingga kode contoh yang membaca "data/..." di modul gagal.

test_that("render_module() menyiapkan data di folder modul dan kunci", {
  dir_spec <- tempfile("spec"); dir.create(dir_spec)
  out <- tempfile("build")
  yml <- file.path(dir_spec, "modul-01-uji.yml")
  writeLines(c(
    "number: 1", "title: Uji data", "short_code: uji",
    "datasets:",
    "  - name: d_uji",
    "    recipe: {kind: tabular, \"n\": 5, seed: 1,",
    "             columns: {x: {type: numeric, min: 0, max: 1}}}"
  ), yml)
  proj <- ModuleProject$new(specs_dir = dir_spec, output_dir = out,
                            log_level = "error")
  # Renderer palsu: hanya mencatat apakah data sudah ada saat render dipanggil
  ada <- logical(0)
  palsu <- R6::R6Class("RendererPalsu", inherit = Renderer, public = list(
    render = function(doc, output_dir) {
      ada[[length(ada) + 1L]] <<- file.exists(file.path(output_dir, "data", "d_uji.csv"))
      Artifact$new(file.path(output_dir, "palsu.pdf"), "pdf")
    }))
  local_mocked_bindings(renderer_factory = function(...) palsu$new(theme = theme_factory()))
  proj$render_module(proj$specs[[1]])
  expect_identical(ada, c(TRUE, TRUE))
  expect_true(file.exists(file.path(out, "modul-01", "data", "d_uji.csv")))
  expect_true(file.exists(file.path(out, "kunci-01", "data", "d_uji.csv")))
})
