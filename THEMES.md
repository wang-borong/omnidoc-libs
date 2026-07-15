# OmniDoc shared themes

## Engineering textbook

The engineering textbook theme provides matching PDF, HTML, and EPUB styles.

Use the shared CSS by name in `.omnidoc.toml`:

```toml
[pandoc]
css = "engineering-book.css"
epub_css = "engineering-book.css"
```

OmniDoc first checks the project path, then resolves the name from
`omnidoc-libs/pandoc/css/`. HTML and EPUB use the same responsive typography,
admonition styling, MathML layout, tables, code blocks, and dark mode. Desktop
HTML is centered at a maximum reading width of 56rem.

Use the matching PDF package from document metadata:

```yaml
header-includes:
  - \usepackage{omni-engineering-book}
  - \renewcommand{\OmniBookSubtitle}{A reusable subtitle}
  - \renewcommand{\OmniBookImprint}{2026}
```

The package is installed as `texmf/tex/common/omni-engineering-book.sty` and
provides the cover, engineering color palette, CJK typography, headings,
headers and footers, quote boxes, and alternating table rows. The subtitle and
imprint commands are optional; without them, the subtitle is omitted and the
document date is used.
