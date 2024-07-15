#!/usr/bin/env bash

toolpath=$(dirname $(realpath --no-symlinks $0))
rootpath=$(dirname $toolpath)

if [[ -z $CSS ]]; then
    CSS=pandoc/css/advance-editor.css
fi

PANDOC_OPTS=(
  -f markdown
  -t html
  --lua-filter=include-code-files.lua
  --lua-filter=include-files.lua
  --lua-filter=diagram-generator.lua
  --metadata=pythonPath:"python3"
  --lua-filter=fonts-and-alignment.lua
  -F pandoc-crossref
  -M "crossrefYaml=pandoc/data/crossref.yaml"
  --data-dir=$rootpath/pandoc/data
  --standalone
  --embed-resources
  --resource-path=$rootpath:$rootpath/pandoc/headers:$rootpath/pandoc/csl:$rootpath/image:$rootpath/images:$rootpath/figure:rootpath/figures
  --css $CSS
)

args=()
fpath="."
skiplevel=".."
for arg in $@; do
  if [[ -f $arg && ${arg##*.} == "md" ]]; then
    fpath="$(dirname $arg)"
    args=(${args[@]} $(basename $arg))
  elif [[ -f $arg && ${arg##*.} == "html" ]]; then
    fptmp=$fpath
    while [[ $(dirname $fptmp) != "." ]]; do
      fptmp=$(dirname $fptmp)
      skiplevel="$skiplevel/.."
    done
    args=(${args[@]} $skiplevel/$arg)
  else
    args=(${args[@]} $arg)
  fi
done
cd $fpath
# echo ${args[@]}
# pwd

pandoc ${PANDOC_OPTS[@]} ${args[@]}

