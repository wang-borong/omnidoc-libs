# OmniDoc shared themes

Theme bundles have machine-readable manifests under `themes/`. Inspect and
validate the installed contracts with:

```bash
omnidoc theme list
omnidoc theme inspect engineering-book
omnidoc theme validate engineering-book
```

## Engineering textbook

The engineering textbook theme provides matching PDF, HTML, and EPUB styles.

Select the bundle once in `.omnidoc.toml`:

```toml
[theme]
name = "engineering-book"
version = "1"
compatibility = "readium"
```

OmniDoc resolves the matching HTML/EPUB CSS, Lua filters, and PDF header from
the bundle manifest. HTML and EPUB use the same responsive typography,
admonition styling, MathML layout, tables, code blocks, and dark mode. Desktop
HTML is centered at a maximum reading width of 56rem.

Optional PDF cover fields can still be set from document metadata:

```yaml
header-includes:
  - \renewcommand{\OmniBookSubtitle}{A reusable subtitle}
  - \renewcommand{\OmniBookImprint}{2026}
```

The package is installed as `texmf/tex/common/omni-engineering-book.sty` and
loaded automatically through `pandoc/headers/engineering-book.tex` when the
project selects `[theme] name = "engineering-book"`. It provides the cover,
engineering color palette, CJK typography, headings, headers and footers,
quote boxes, and alternating table rows. The subtitle and imprint commands are
optional; without them, the subtitle is omitted and the document date is used.
The package loads its required XeLaTeX/CJK and admonition support itself, so a
theme selection is sufficient to compile its declared components.

For source images that remain SVG in HTML and EPUB, place a pre-rendered PDF
with the same basename next to the SVG (for example, `diagram.svg` and
`diagram.pdf`). PDF/LaTeX builds select that sibling deterministically without
requiring shell escape or Inkscape, and OmniDoc records both assets in the
target dependency graph.
