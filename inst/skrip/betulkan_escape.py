#!/usr/bin/env python3
"""Membetulkan jumlah garis miring terbalik pada perintah LaTeX di spesifikasi.

Latar belakang
--------------
Isi modul ditulis dalam dua bentuk YAML yang memperlakukan garis miring
terbalik secara berbeda:

* blok lipat ``- >``  -> isinya diteruskan apa adanya, sehingga perintah
  LaTeX cukup ditulis dengan **satu** garis miring (``\\emph{...}``);
* string berkutip ``- "..."`` -> YAML memampatkan ``\\\\`` menjadi satu,
  sehingga perintah LaTeX harus ditulis dengan **dua** garis miring.

Bila blok lipat terlanjur ditulis memakai dua atau empat garis miring,
Pandoc menafsirkannya sebagai garis miring harfiah sehingga yang tercetak
di PDF adalah teks ``\\emph{...}``, bukan huruf miring.

Skrip ini menelusuri berkas spesifikasi baris demi baris, mengenali baris
yang berada di dalam blok lipat, lalu merapikan garis miring berlebih pada
baris tersebut saja. String berkutip tidak disentuh.

Pemakaian
---------
    python3 betulkan_escape.py <berkas.yml> [berkas.yml ...]
    python3 betulkan_escape.py --periksa <berkas.yml>   # hanya melaporkan
"""

import re
import sys

# Perintah LaTeX yang lazim dipakai pada prosa modul.
PERINTAH = (
    "emph", "texttt", "textbf", "textit", "textasciitilde",
    "textasciicircum", "textbackslash", "quad", "times", "leq", "geq",
    "neq", "chi", "eta", "alpha", "beta", "mu", "sigma", "sum", "sqrt",
    "frac", "dfrac", "bar", "hat", "square", "item", "begin", "end",
)
POLA = re.compile(r"\\{2,}(" + "|".join(PERINTAH) + r")\b")

# Karakter khusus LaTeX yang diloloskan (\_, \%, \$, \&, \#, \{, \}).
# Jumlah garis miringnya harus ikut dirapikan; bila hanya perintahnya yang
# dirapikan sedangkan karakter ini tertinggal, LaTeX gagal dikompilasi.
POLA_KHUSUS = re.compile(r"\\{2,}([_%$&#{}])")


def _blok_lipat(baris: list[str]) -> list[bool]:
    """Menandai baris mana saja yang berada di dalam blok lipat ``>``."""
    di_dalam = [False] * len(baris)
    aktif = False
    indent_blok = 0
    for i, b in enumerate(baris):
        telanjang = b.strip()
        if not telanjang:
            continue
        indent = len(b) - len(b.lstrip())
        # penanda pembuka blok lipat, mis. "- >" atau "deskripsi: >"
        if re.search(r"(^|\s)-?\s*[\w_]*:?\s*>-?\s*$", b) and telanjang.endswith(">"):
            aktif = True
            indent_blok = indent
            continue
        if aktif:
            # blok berakhir ketika indentasi kembali sama atau lebih dangkal
            if indent <= indent_blok:
                aktif = False
            else:
                di_dalam[i] = True
    return di_dalam


def betulkan(teks: str) -> tuple[str, int]:
    baris = teks.split("\n")
    tanda = _blok_lipat(baris)
    jumlah = 0
    for i, dalam in enumerate(tanda):
        if not dalam:
            continue
        baru, n1 = POLA.subn(r"\\\1", baris[i])
        baru, n2 = POLA_KHUSUS.subn(r"\\\1", baru)
        if n1 or n2:
            baris[i] = baru
            jumlah += n1 + n2
    return "\n".join(baris), jumlah


def main(argv: list[str]) -> int:
    periksa = "--periksa" in argv
    berkas = [a for a in argv if not a.startswith("--")]
    total = 0
    for f in berkas:
        s = open(f, encoding="utf-8").read()
        baru, n = betulkan(s)
        total += n
        if n:
            print(f"  {f.split('/')[-1]}: {n} perintah dirapikan")
            if not periksa:
                open(f, "w").write(baru)
    print(("[periksa] " if periksa else "") + f"total: {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
