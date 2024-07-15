#!/usr/bin/env python


import re
import os
import sys
import zlib
import base64
import requests
import argparse
import subprocess


def shelldo(cmd):
    subprocess.call(cmd, shell=True)


def check_file_existence(file_path):
    return os.path.exists(file_path) and os.path.isfile(file_path)


class Drawio():
    def __init__(self, appath) -> None:
        self.appath = appath

    def _get_diagram_names(self, diofile):
        diagnames = []
        diagname_re = re.compile(r' *<diagram.*name=\"([\w-]*)\".*>')
        with open(diofile, 'r', encoding='utf-8') as f:
            drawio_cont = f.readlines()
            diaglines = [line for line in drawio_cont if '<diagram' in line]
            if len(diaglines) > 1:
                for dc in diaglines:
                    diagmatches = diagname_re.match(dc)
                    if diagmatches:
                        diagnames.append('-' + diagmatches.group(1))
                    else:
                        diagnames.append('-page-{}'.format(len(diagnames)+1))
            elif len(diaglines) == 1:
                diagnames.append('')
            else:
                pass
        return diagnames

    def conv_to(self, diofile,  tgtpath, type='pdf', force=False):
        diofn = os.path.basename(diofile).replace('.drawio', '')
        diopath = os.path.dirname(diofile)
        tgtpath = tgtpath if tgtpath else diopath + '/figure'
        if not os.path.exists(tgtpath):
            os.mkdir(tgtpath)
        _types = ["pdf", "png", "jpg", "svg", "vsdx", "xml"]
        if type not in _types:
            print('drawio can not convert to {}'.format(type))
            exit(1)
        diagnames = self._get_diagram_names(diofile)
        for i in range(0, len(diagnames)):
            addopt = '--crop' if type == 'pdf' else ''
            fig_path = '{}/{}{}.{}'.format(tgtpath, diofn,
                                           diagnames[i], type)
            if check_file_existence(fig_path) and not force:
                continue
            drawio_conv_cmd = '{} --export --format {} --page-index {} ' \
                '{} --output {} {}'.format(self.appath, type, i,
                                           addopt, fig_path, diofile)
            shelldo(drawio_conv_cmd)


class Gradot():
    def __init__(self, appath) -> None:
        self.appath = appath

    def conv_to(self, dotfile,  tgtpath, type='pdf', force=False):
        dotfn = os.path.basename(dotfile).replace('.dot', '')
        dotpath = os.path.dirname(dotfile)
        tgtpath = tgtpath if tgtpath else dotpath + '/figure'
        if not os.path.exists(tgtpath):
            os.mkdir(tgtpath)
        _types = ["pdf", "ps", "png", "svg", "fig",
                  "gif", "jpg", "jpeg", "json"]
        if type not in _types:
            print('gradot can not convert to {}'.format(type))
            exit(1)

        fig_path = '{}/{}.{}'.format(tgtpath, dotfn, type)
        if force or not check_file_existence(fig_path):
            gradot_conv_cmd = '{} -T{} ' \
                '-o {} {}'.format(self.appath, type, fig_path, dotfile)
            shelldo(gradot_conv_cmd)


class Inkcvt():
    def __init__(self, appath) -> None:
        self.appath = appath

    def conv_to(self, figfile,  tgtpath, type='pdf', force=False):
        figfn = re.sub(r'\.\w+$', r'', os.path.basename(figfile))
        figpath = os.path.dirname(figfile)
        tgtpath = tgtpath if tgtpath else figpath + '/figure'
        if not os.path.exists(tgtpath):
            os.mkdir(tgtpath)
        _types = ["eps", "emf", "wmf", "xaml", "pdf", "ps", "png", "svg"]
        if type not in _types:
            print('inkscape can not convert to {}'.format(type))
            exit(1)

        fig_path = '{}/{}.{}'.format(tgtpath, figfn, type)
        if force or not check_file_existence(fig_path):
            inkscape_conv_cmd = '{} --export-type={} ' \
                '-o {} {}'.format(self.appath, type, fig_path, figfile)
            shelldo(inkscape_conv_cmd)


class Immcvt():
    def __init__(self, appath) -> None:
        self.appath = appath

    def conv_to(self, figfile,  tgtpath, type='pdf', force=False):
        figfn = re.sub(r'\.\w+$', r'', os.path.basename(figfile))
        figpath = os.path.dirname(figfile)
        tgtpath = tgtpath if tgtpath else figpath + '/figure'
        if not os.path.exists(tgtpath):
            os.mkdir(tgtpath)

        # ImageMagick supported image formats over 200, no need
        # to check the file's type.

        fig_path = '{}/{}.{}'.format(tgtpath, figfn, type)
        if force or not check_file_existence(fig_path):
            convert_cmd = '{} {} {}'.\
                format(self.appath, figfile, fig_path)
            shelldo(convert_cmd)


class Kroki():
    def __init__(self) -> None:
        self._tool_box = {'.mmd': 'mermaid', '.dot': 'graphviz',
                          '.puml': 'plantuml'}
        pass

    def conv_to(self, file,  tgtpath, type, force=False):
        _fname = os.path.basename(file)
        (fname, fsufx) = os.path.splitext(_fname)
        with open(file, 'r') as fr:
            reqstr = base64.urlsafe_b64encode(
                zlib.compress(fr.read().encode('utf-8'), 9)).decode('ascii')
        tool = self._tool_box[fsufx]

        kroki_url = "https://kroki.io/{}/{}/{}".format(
            tool,
            type,
            reqstr
        )

        fig_path = '{}/{}.{}'.format(tgtpath, fname, type)
        if force or not check_file_existence(fig_path):
            response = requests.get(kroki_url)
            if response.status_code == 200:
                with open(fig_path, "wb") as fw:
                    fw.write(response.content)
            else:
                print('remote response error')


def cli():
    parser = argparse.ArgumentParser(description='drawio converter')
    parser.add_argument('-d', '--drawio', type=str,
                        default='/opt/drawio/drawio',
                        help='the drawio path')
    parser.add_argument('-g', '--gradot', type=str,
                        default='/usr/bin/dot',
                        help='the gradot (graphviz dot) path')
    parser.add_argument('-i', '--inkscape', type=str,
                        default='/usr/bin/inkscape',
                        help='the inkscape path')
    parser.add_argument('-m', '--imagemagick', type=str,
                        default='/usr/bin/convert',
                        help='the imagemagick path')
    parser.add_argument('-c', '--convert', action="store_true",
                        help='use inkscape or imagemagick convertor')
    parser.add_argument('-f', '--format', type=str, default='pdf',
                        help='export format, default is pdf')
    parser.add_argument('-F', '--force', action="store_true",
                        help='force generate or convert figures')
    parser.add_argument('-o', '--output', type=str, default='figures',
                        help='output path, default is the figures directory'
                        ' in current working directory')
    parser.add_argument('source', nargs='+',
                        help='the drawio source files')
    args = parser.parse_args()

    return args


if __name__ == "__main__":
    args = cli()

    dio = Drawio(args.drawio)
    dot = Gradot(args.gradot)
    kroki = Kroki()
    ink = Inkcvt(args.inkscape)
    imm = Immcvt(args.imagemagick)
    for file in args.source:
        _, fext = os.path.splitext(file)
        if fext == '.drawio':
            dio.conv_to(file, args.output, args.format, args.force)
        elif fext == '.dot':
            dot.conv_to(file, args.output, args.format, args.force)
        elif fext == '.mmd':
            kroki.conv_to(file, args.output, args.format, args.force)
        else:
            if args.convert and fext == '.svg':
                ink.conv_to(file, args.output, args.format, args.force)
            else:
                imm.conv_to(file, args.output, args.format, args.force)

