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

"$root/scripts/check-pandoc-latex-template.sh"

echo "omnidoc-libs filter smoke test passed"
