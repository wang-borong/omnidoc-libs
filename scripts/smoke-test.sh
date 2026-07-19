#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for tool in pandoc rg; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

pandoc "$root/tests/filter-smoke.md" \
  --mathml \
  --lua-filter="$root/pandoc/data/filters/display-math.lua" \
  --lua-filter="$root/pandoc/data/filters/include-files.lua" \
  --lua-filter="$root/pandoc/data/filters/emoji.lua" \
  --css="$root/pandoc/css/omnidoc-base.css" \
  --standalone --embed-resources --toc -t html5 -o "$work/smoke.html"

rg -q 'display="inline"' "$work/smoke.html"
rg -q 'class="omni-display-math"' "$work/smoke.html"
rg -q 'display="block"' "$work/smoke.html"
rg -q 'href="#summary-1"' "$work/smoke.html"
rg -q '\.omni-display-math' "$work/smoke.html"
rg -q '🌟' "$work/smoke.html"

cat >"$work/fake-omnidoc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source="$3"
format="svg"
output="."
shift 3
while (($#)); do
  case "$1" in
    --format) format="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    --force) shift ;;
    *) shift ;;
  esac
done
stem="$(basename "${source%.*}")"
test "$format" = svg
label="${BITFIELD_LABEL:-bitfield smoke}"
cat >"$output/$stem.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="24" viewBox="0 0 120 24">
  <text x="4" y="17">$label</text>
</svg>
SVG
EOF
chmod +x "$work/fake-omnidoc"

cat >"$work/bitfield.md" <<'EOF'
```{.bitfield #fig-smoke caption="Bitfield smoke"}
{"entries":[{"name":"VALUE","bits":7},{"name":"READY","bits":1}]}
```
EOF

(
  cd "$work"
  OMNIDOC_BIN="$work/fake-omnidoc" pandoc bitfield.md \
    --lua-filter="$root/pandoc/data/filters/diagram-generator.lua" \
    --standalone --embed-resources -t html5 -o bitfield.html
)
rg -q 'data:image/svg\+xml;base64' "$work/bitfield.html"
rg -q 'Bitfield smoke' "$work/bitfield.html"
rg -q 'bitfield smoke' "$work/figures/fig-smoke.svg"

# A stable figure identifier must not preserve stale rendered bytes when the
# fenced diagram source or renderer output changes.
(
  cd "$work"
  BITFIELD_LABEL="bitfield updated" OMNIDOC_BIN="$work/fake-omnidoc" \
    pandoc bitfield.md \
      --lua-filter="$root/pandoc/data/filters/diagram-generator.lua" \
      --standalone --embed-resources -t html5 -o bitfield-updated.html
)
rg -q 'bitfield updated' "$work/figures/fig-smoke.svg"

"$root/scripts/check-pandoc-latex-template.sh"

echo "omnidoc-libs filter smoke test passed"
