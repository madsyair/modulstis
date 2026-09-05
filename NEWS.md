# modulstis 0.3.8

## Perubahan penempatan Buku Pedoman

* **Buku Pedoman tidak lagi dipasang sebagai vignette PDF.** `R CMD check` memeriksa ukuran
  seluruh PDF di bawah `inst/doc` dan memberi WARNING bila `gs+qpdf` masih dapat
  memampatkannya secara berarti. Buku ini memuat sampul dan ilustrasi beresolusi cetak
  (~1,5 Mb sebelum dipadatkan), sehingga peringatan itu akan muncul kembali setiap kali
  seseorang membangun ulang buku tanpa memadatkannya --- memadatkan secara otomatis (0.3.7)
  hanya menutup jalur yang paling sering, bukan semuanya.

  Sejak versi ini buku disimpan **hanya** di `inst/pedoman/Pedoman_modulstis.pdf`, dan
  vignette `pedoman-modulstis` berubah menjadi halaman HTML ringan berisi daftar isi serta
  cara membukanya. Karena pemeriksaan ukuran hanya berlaku bagi `inst/doc`, WARNING tersebut
  kini **tidak mungkin** muncul --- pada mesin siapa pun, dengan atau tanpa
  `--compact-vignettes=both`.

* **Fungsi baru `buka_pedoman()`** membuka PDF dengan pembaca bawaan sistem, atau
  mengembalikan path-nya dengan `buka_pedoman(buka = FALSE)`. Rujukan pada berkas
  `PANDUAN.md` yang dibuat `buat_proyek_modul()` ikut diperbarui.

* `R.rsp` dikeluarkan dari `Suggests` dan `VignetteBuilder` karena tidak ada lagi vignette
  `.asis`; kedua vignette kini ditangani `knitr`. Ukuran paket terpasang turun sekitar 1,5 Mb
  karena PDF tidak lagi digandakan di `inst/doc`.

# modulstis 0.3.7

## Perbaikan

* **`R CMD check` tidak lagi memberi WARNING ukuran PDF vignette.** Buku Pedoman yang baru
  dibangun berukuran sekitar 1,5 Mb; bila belum dipadatkan, `R CMD build` memasangnya apa
  adanya ke `inst/doc` sehingga check melaporkan *sizes of PDF files under inst/doc*.
  Pemadatan kini menjadi bagian dari `inst/pedoman/bangun_pedoman.R`: setelah ketujuh bagian
  digabung, PDF dipadatkan (`tools::compactPDF(gs_quality = "ebook")`, ~1,5 Mb → ~0,7 Mb),
  disalin ke `vignettes/pedoman-modulstis.pdf`, dan berkas antara dibersihkan --- tidak ada
  lagi langkah yang harus diingat sendiri.

* **Seluruh peringatan roxygen2 hilang** (sebelumnya 46). Parameter konstruktor `ModuleSpec$new()`
  dan `Document$new()` yang semula ditulis `@param ...` kini didokumentasikan satu per satu, dan
  `LatexTheme$preamble()` melengkapi `@param course` yang hilang.

## Dokumentasi

* `Makefile` menambahkan sasaran `make pedoman` (bangun ulang buku) dan `make check-cepat`;
  sasaran `make check` kini memakai `--compact-vignettes=both` sebagai jaring pengaman kedua.

* README `inst/pedoman/` menjelaskan alur bangun ulang beserta alasan pemadatan wajib.

# modulstis 0.3.6

## Perubahan isi paket

* **Spesifikasi contoh dibatasi pada dua yang benar-benar didampingkan:**
  `inst/specs_ps/` (Pemrograman Statistika D-IV, 14 modul) dan `inst/specs_d3/`
  (Pemrograman Statistika D-III, 14 modul). Spesifikasi Analisis Peubah Ganda
  (`inst/specs/`) dan Data Mining (`inst/specs_dm/`) dikeluarkan dari paket karena
  berkas pendampingnya memang tidak disebarkan bersama paket --- menyertakannya membuat
  dokumentasi menjanjikan sesuatu yang tidak ada. Kedua spesifikasi yang tersisa sekaligus
  menjadi contoh penerapan **kedua backend** (bookdown dan Quarto), sehingga seluruh contoh
  pada vignette dan Buku Pedoman dapat dijalankan ulang apa adanya setelah paket dipasang.

* Ukuran paket terpasang menyusut karena dua himpunan spesifikasi beserta datanya tidak lagi
  ikut. Tidak ada kode, fungsi, atau uji yang bergantung pada kedua himpunan itu, sehingga
  API tidak berubah.

## Dokumentasi

* Tabel **Berkas Pendamping** pada Buku Pedoman, kolofon, dan vignette diselaraskan: 28
  spesifikasi dari dua program studi, bukan 65 dari empat mata kuliah.

* Contoh kunci `prodi` pada Bab 4 diganti menjadi perbandingan D-IV versus D-III --- keduanya
  kini benar-benar tersedia di dalam paket dan dapat diperiksa pembaca.

# modulstis 0.3.5

## Dokumentasi

* **Buku Pedoman kini memuat petunjuk memilih backend.** Sebelumnya Quarto hanya disebut
  sepintas pada katalog kelas dan glosarium --- tidak ada petunjuk praktisnya. Bab 2 kini
  memiliki bagian **"Memilih Backend: R Markdown atau Quarto"** berisi perbandingan kedua
  backend, cara berpindah (satu argumen), cara memasang dan memeriksa Quarto CLI, panduan
  memilih, serta peringatan agar tidak mencampur kedua backend dalam satu buku. Quarto
  ditambahkan sebagai prasyarat opsional pada daftar prasyarat dan daftar periksa kesiapan.

* **Tanggal buku mengikuti tanggal pembangunan ulang.** Sampul memuat baris "Diperbarui
  <tanggal>", sedangkan tahun hak cipta, penanggalan kata pengantar, dan kolofon dihitung dari
  `Sys.Date()` --- bukan angka yang ditulis manual, sehingga tidak lagi tertinggal dari isinya.

* Sub judul buku menjadi *Panduan R Markdown, Quarto, LaTeX, dan Otomatisasi*; daftar isi,
  penomoran halaman berlanjut, dan peta halaman pada README diselaraskan (buku menjadi 82
  halaman, isi 1--75).

# modulstis 0.3.4

## Fitur baru

* **Data nyata dapat dipakai langsung, tanpa simulasi.** Sebelumnya setiap `datasets[*]`
  wajib memiliki `recipe.kind` dari lima jenis pembangkit simulasi, sehingga modul yang
  memakai data sungguhan (mis. hasil Susenas atau berkas kompilasi tim) tidak dapat
  dideklarasikan pada spesifikasi. Kini tersedia `kind: file`:

  ```yaml
  datasets:
    - name: sosek_kabkota
      role: contoh
      recipe:
        kind: file
        path: data_asli/sosek_2024.csv     # relatif terhadap letak berkas YAML
        columns: [kab, RLS, AHH, Sanitasi] # opsional: pilih & urutkan kolom
        rename: {AHH: harapan_hidup}       # opsional
        n: 100                             # opsional: ambil n baris pertama
  ```

  Format yang didukung: `.csv`, `.csv2`, `.tsv`, `.txt`, dan `.rds`. Data dibaca apa adanya
  (tidak ada `set.seed()`, tidak ada pembangkitan), lalu disalin ke `data/<nama>.csv` di
  direktori modul dan kunci seperti dataset simulasi.

* **Path relatif diselesaikan terhadap berkas YAML.** `module_spec_from_yaml()` menyuntikkan
  `base_dir` sehingga `path` pada resep dihitung relatif terhadap letak spesifikasi, bukan
  direktori kerja pemanggil --- proyek tetap dapat dipindah-pindah.

* **Validasi ikut memeriksa keberadaan berkas.** `spec$validate()` melaporkan
  `dataset 'x': berkas tidak ditemukan (...)` sebelum render dijalankan, sejalan dengan
  prinsip *fail-fast* paket.

# modulstis 0.3.3

## Perbaikan

* **Direktori kunci jawaban kini menerima berkas data.** Dokumen kunci membaca data dengan
  path relatif `data/...` sama seperti modul, tetapi `generate_data()` hanya menulis data ke
  direktori modul. Akibatnya `render_module()` selalu gagal pada tahap kunci dengan pesan
  `cannot open the connection` --- pada **kedua** backend. Kini `render_module()` menyalin data
  ke direktori kunci sebelum merender.

## Dokumentasi

* **Vignette penerapan penuh ditulis ulang dengan dua backend.** Sebelumnya hanya
  memperagakan Analisis Peubah Ganda lewat bookdown, sehingga backend Quarto tidak punya
  contoh. Kini vignette memperagakan **Pemrograman Statistika D-IV lewat bookdown** (`.Rmd`)
  dan **Pemrograman Statistika D-III lewat Quarto** (`.qmd`), dari spesifikasi yang bentuknya
  sama --- pergantian backend hanya satu argumen. Ditambahkan pula perbandingan keluaran kedua
  backend beserta peringatan agar tidak mencampur keduanya dalam satu buku.

# modulstis 0.3.2

## Perbaikan

* **Judul label kini aman terhadap karakter khusus LaTeX.** `\contoh{}`, `\kode{}`,
  `\latihan{}`, dan `\tugas{}` sebelumnya hanya meng-escape `&` dan `_`. Judul yang
  memuat `^` atau `~` --- misalnya "Arah pembeda Sp^{-1} dan kaitannya dengan T^2" ---
  menghentikan kompilasi LaTeX dengan pesan yang menyesatkan (knitr menyarankan
  menambahkan `$ $` di sekitar ekspresi R inline, padahal persoalannya pada judul).
  Kini `%` dan `#` ikut ditangani, `^` dan `~` diubah menjadi `\textasciicircum{}`
  dan `\textasciitilde{}`, dan karakter yang sudah ter-escape tidak di-escape ganda.

* **Matematika ringkas tetap boleh dipakai pada judul label.** Bagian di dalam
  pasangan `$...$` dibiarkan apa adanya, sehingga judul seperti
  `Uji $T^2$ Hotelling` atau `Arah pembeda $\mathbf{S}_p^{-1}(\bar{x}_1 - \bar{x}_2)$`
  tetap tercetak sebagai matematika. Inilah cara yang dianjurkan untuk menulis rumus
  pada judul.

# modulstis 0.3.1

## Fitur baru

* **Templat proyek RStudio.** Setelah paket terpasang, pilih **File > New Project >
  New Directory > Proyek Modul Praktikum (modulstis)**. RStudio menanyakan nama mata
  kuliah, kode, program studi, semester, penyusun, dan banyaknya modul, lalu menyiapkan
  folder `spec/`, `modul/`, dan `buku/` beserta `render_modul.R` dan `README.md`.
  Sebelumnya paket hanya menyediakan Addins, sehingga kerangka proyek harus disusun
  manual. Fungsi `buat_proyek_modul()` juga dapat dipanggil langsung dari konsol.

* **Spesifikasi contoh yang siap dirender.** Proyek baru menyertakan satu berkas
  `spec/modul-01-contoh.yml` yang lolos validasi apa adanya dan langsung menghasilkan
  PDF modul beserta kunci jawabannya, sehingga alur kerja dapat diuji sebelum menulis
  isi sungguhan.

## Perbaikan

* **Backend Quarto kini teruji.** `renderer_factory("quarto")` sebelumnya ada
  tetapi belum pernah dijalankan. Tiga penghalang diperbaiki: `titlesec` kini
  memiliki format bagi `\paragraph` dan `\subparagraph` (Quarto memetakan judul
  `####` ke sana, dan tanpa format kompilasi berhenti), `latex_prose_safe()`
  meloloskan `^` dan `~`, serta judul sampul tidak lagi bertindih.

* **Judul sampul tiga baris.** Font kini ditetapkan lewat opsi `font=` pada simpul
  TikZ, bukan di dalam badannya --- bila di dalam badan, TikZ sudah mengunci jarak
  baris dari font luar sehingga baris judul saling bertindih. Ukurannya disesuaikan
  ke 28/33 pt, pemenggalan dimatikan, dan simpul di bawahnya diturunkan. Cacat ini
  memengaruhi bookdown maupun Quarto.


* **Pemenggalan kata bahasa Indonesia.** Preamble kini memilih pola pemenggalan
  Indonesia melalui `\language=\csname l@indonesian\endcsname`. Sebelumnya LaTeX
  memakai kaidah bahasa Inggris sehingga kata terpotong keliru --- misalnya
  `meny-atakan` alih-alih `me-nyatakan`. Cara ini dipilih karena tidak menambah
  ketergantungan paket, tidak mengubah penamaan bagian, dan tidak bentrok dengan
  makro sampul.

* **Sintaks `data.table` saat render.** Penanda `.datatable.aware <- TRUE`
  ditambahkan pada `R/utils.R`. Tanpa penanda ini, `data.table` menolak
  mengaktifkan sintaks khasnya ketika render dipanggil dari dalam paket, sehingga
  `dt[, list(...), by = ...]` gagal dengan pesan `could not find function "."`
  atau `object 'x' not found`.

* **Lebar nomor pada daftar isi.** Lebar kotak nomor diperlebar
  (`cftsecnumwidth` dan seterusnya) agar modul bernomor dua digit --- misalnya
  bagian `10.10` atau `10.5.0.1` --- tidak melimpah dari kotaknya.

* **Pelolosan karakter khusus pada judul dan ringkasan solusi.** Judul header
  yang memuat `&` (misalnya "Reduksi & Anomali Keamanan") sebelumnya membuat
  `fancyhdr` membacanya sebagai pemisah kolom. Ringkasan solusi yang memuat `$`
  atau `^` --- misalnya `cmdscale(...)$GOF` atau `rho^2` --- membuka mode
  matematika. Keduanya kini diloloskan otomatis.

* **Buku Pedoman diperbarui** ke 80 halaman: prasyarat bertambah menjadi lima
  dengan subbab pemasangan pola pemenggalan, dan Lampiran D memuat bagian baru
  "Galat Render yang Sukar Ditelusuri".

## Kebersihan paket

* **Lolos `R CMD check --as-cran`** tanpa WARNING maupun NOTE yang berasal dari
  paket. Empat temuan diperbaiki: PDF vignette dimampatkan (1.498 KB menjadi 717 KB),
  `glue` dan `rlang` yang tidak terpakai dikeluarkan dari `Imports`, `R6` dinyatakan
  tegas lewat `@importFrom`, dan kurung yang hilang pada dokumentasi
  `latex_prose_safe()` dibetulkan.

* **Ukuran terpasang menyusut** dari 10,1 MB menjadi 7,1 MB; berkas antara
  `bagian_*.pdf` pada folder pedoman tidak lagi ikut terpasang.

## Catatan pemasangan

Pola pemenggalan bahasa Indonesia tidak selalu terpasang bawaan. Bila hasil
render masih memenggal dengan kaidah Inggris, pasang `hyphen-indonesian`
lebih dahulu (lihat `SystemRequirements`).

# modulstis 0.3.0

Versi ini merangkum seluruh praktik yang dipakai dalam penyusunan modul praktikum
**Analisis Peubah Ganda (K203318)** dan **Pemrograman Statistika (K242310)**.

## Fitur baru

* **`sampul_buku()`** — membangkitkan sampul buku bergaya BPS/STIS (logo, latar gedung,
  pita diagonal) dari templat bawaan. Varian `"modul"` memakai pita biru, `"kunci"` hijau.
* **`render_berlanjut()`** — merender sekumpulan modul dengan **penomoran halaman
  berlanjut** lintas modul melalui alur dua tahap (ukur, lalu terapkan offset).
* **`gabung_pdf()`** dan **`pdf_halaman()`** — pembantu penyusunan buku gabungan.
* **Aset tema** `logo_stis.png` dan `gedung_bg.png` kini disertakan di
  `inst/themes/bps/img/`.
* **`course$halaman_awal`** — menetapkan nomor halaman pertama sebuah modul; disisipkan
  setelah `\end{titlepage}` agar tidak direset oleh lingkungan `titlepage`.
* **`course$prodi`** --- nama program studi kini menjadi parameter, bukan tertanam pada
  templat. Tampil pada sampul pembatas dan kaki halaman. Bawaannya
  `"D-IV Komputasi Statistik"`; modul Pemrograman Statistika memakai `"D-IV Statistika"`.
* **`course$penyusun`** — menerima vektor, sehingga beberapa penyusun tercantum otomatis
  pada sampul.
* **Bagian `tambahan`** — bagian opsional setelah *Penugasan* (dipakai modul inferensia
  untuk menempatkan penyelesaian dengan fungsi bawaan R). Dilewati bila tidak diisi.
* **Kotak `kotakpenjelasan`** — kotak *Penjelasan Kode* yang dirender sebelum
  *Interpretasi Output*.
* **Kotak `kotakanatomi`** beserta warna padanan, untuk memperagakan pasangan `ui`–`server`
  pada modul RShiny.
* **Tipe kolom `balanced`** pada `DataRecipe`, untuk rancangan faktorial berimbang.

## Perubahan

* **Tahun ajaran dihapus** dari pita sampul modul; kini hanya menampilkan semester.
* `kotakinfo` kini menerima **judul** (sebelumnya argumen opsionalnya keliru diperlakukan
  sebagai opsi tcolorbox sehingga judul tidak tampil dan memicu galat `pgfkeys`).
* `latex_prose_safe()` kini mengamankan `%`, `$`, `&`, dan `#` selain `_`, dengan
  penjagaan agar karakter yang sudah ter-escape tidak diproses ulang.

## Dokumentasi

* **Buku Pedoman disertakan sebagai vignette.** Berkas
  `vignette("pedoman-modulstis", package = "modulstis")` membuka buku pedoman
  setebal 79 halaman: 11 bab dan 5 lampiran, mencakup pemasangan, anatomi
  spesifikasi YAML, sintaks LaTeX dan R Markdown, penyuntingan preamble,
  penyusunan buku gabungan, serta pemecahan masalah.
* Vignette memakai mesin `R.rsp::asis` sehingga PDF disertakan siap pakai --- tidak
  perlu XeLaTeX maupun font Carlito saat pemasangan paket.
* **Sumber pedoman disertakan** di `inst/pedoman/`: tujuh berkas R Markdown, preamble
  tiap bagian, ilustrasi, aset gambar, dan skrip `bangun_pedoman.R` untuk membangun
  ulang beserta penghitungan offset penomoran halaman.

## Catatan

Uji paket: 123 lolos. `R CMD check`: bersih.
