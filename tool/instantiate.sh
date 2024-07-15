#!/usr/bin/env bash

usage() {
    echo "$0 -t <title> [-m <metafile> -a <author> -d <date> -w <cwd> -n <docnum> -v <docver>]"
}

while getopts "m:t:a:d:w:h" o; do
    case "${o}" in
        t)
            __title=${OPTARG}
            ;;
        a)
            __author=${OPTARG}
            ;;
        d)
            __date=${OPTARG}
            ;;
        w)
            __cwd=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ "$__title" == "" ]]; then
    echo "Documents must has a title!"
    usage
    exit 1
fi

_title=$(echo $__title | perl -CSD -Mutf8 -pe \
    's/(\p{Han}) *([(0-9a-zA-Z_\/\-])/$1 $2/g; s/([0-9a-zA-Z_)\/\-]) *(\p{Han})/$1 $2/g;')
_filename=$(echo $_title | sed 's/\s*//g')
_author=${__author:-"王伯榕"}
_date=${__date:-"$(date '+%Y/%m/%d')"}

CWD=${__cwd:-"$PWD"}
MAINTEX=$CWD/main.tex
MAINMD=$CWD/main.md
MAKEFILE=$CWD/Makefile

sed -E -i "s|(TARGET\s*\?\=).*|\1 $_filename|" \
    $MAKEFILE

if [[ -f $MAINTEX ]]; then
    sed -E -i -e "s/(author\{).*\}/\1$_author\}/" \
        -e "s|(title\{).*\}|\1$_title\}|" \
        -e "s|(date\{).*\}|\1$_date\}|" \
        $MAINTEX
fi

if [[ -f $MAINMD ]]; then
    sed -E -i -e "s|(title:\s*).*|\1$_title|" \
        -e "/author:/{ n; s|( *\- *).*|\1$_author| }" \
        -e "/date:/{ n; s|( *\- *).*|\1$_date| }" \
        $MAINMD
fi
