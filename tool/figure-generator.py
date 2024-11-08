#!/usr/bin/env python


import re
import os
import sys
import zlib
import base64
import requests
import argparse
import subprocess
from multiprocessing import Pool, Process


class FigEngine:
    def __init__(self, appath) -> None:
        self.appath = appath
        self._types = []

    def eprint(self, *args, **kwargs):
        print(*args, file=sys.stderr, **kwargs)

    def shelldo(self, cmd):
        subprocess.run(cmd, shell=True, check=True)

    def check_file_existence(self, file_path):
        return os.path.exists(file_path) and os.path.isfile(file_path)

    def _get_cmd(self, *args):
        return f'echo FigEngine: {args}'

    def conv_single_to(self, file,  target, type='pdf', force=False):
        figfn = re.sub(r'\.\w+$', r'', os.path.basename(file))
        figpath = os.path.dirname(file)
        target = target if target else figpath + '/figure'
        if not os.path.exists(target):
            os.mkdir(target)

        if self._types and type not in self._types:
            self.eprint(f'Error: {self.appath} can not convert to {type}')
            exit(1)

        fig_path = '{}/{}.{}'.format(target, figfn, type)
        if force or not self.check_file_existence(fig_path):
            cmd = self._get_cmd(self.appath, type, fig_path, file)
            try:
                self.shelldo(cmd)
            except:
                self.eprint(f'Error: {self.appath} execute failed')

    def conv_to(self, files, output, type='pdf', force=False):
        args = [(file, output, type, force) for file in files]
        with Pool(processes=8) as p:
            rs = [p.apply_async(self.conv_single_to, args=_args) for _args in args]
            for r in rs:
                r.get()

class Drawio(FigEngine):
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

    def _convert(self, args):
        if len(args) == 0:
            return
        cmd = f'{args[0]} --export --format {args[1]} --page-index {args[2]} ' \
            f'{args[3]} --output {args[4]} {args[5]} >/dev/null 2>&1'
        try:
            subprocess.run(cmd, shell=True, check=True)
            print(f'{args[5]} [P{args[2]}] -> {args[4]}')
        except:
            self.eprint(f'Error: Convert {args[5]} [P{args[2]}] failed')

    def conv_single_to(self, file,  target, type='pdf', force=False):
        diofn = os.path.basename(file).replace('.drawio', '')
        diopath = os.path.dirname(file)
        target = target if target else diopath + '/figure'
        if not os.path.exists(target):
            os.mkdir(target)
        _types = ["pdf", "png", "jpg", "svg", "vsdx", "xml"]
        if type not in _types:
            self.eprint('Error: drawio can not convert to {}'.format(type))
            exit(1)
        diagnames = self._get_diagram_names(file)
        addopt = '--crop' if type == 'pdf' else ''

        fig_paths = [f'{target}/{diofn}{diagname}.{type}' for diagname in diagnames]
        cmds = [[self.appath, type, i, addopt, fig_paths[i], file] if not
            self.check_file_existence(fig_paths[i]) or force else [] for i in range(0, len(diagnames))]

        with Pool(processes=8) as p:
            result = p.map_async(self._convert, cmds)
            result.wait()

    def conv_to(self, files, output, type='pdf', force=False):
        args = [(file, output, type, force) for file in files]
        ps = [Process(target=self.conv_single_to, args=_args) for _args in args]
        for p in ps:
            p.start()
        for p in ps:
            p.join()


class Gradot(FigEngine):
    def __init__(self, appath) -> None:
        super().__init__(appath)
        self._types = ["pdf", "ps", "png", "svg", "fig",
                       "gif", "jpg", "jpeg", "json"]

    def _get_cmd(self, *args):
        return '{} -T{} -o {} {}'.format(*args)


class Inkcvt(FigEngine):
    def __init__(self, appath) -> None:
        super().__init__(appath)
        self._types = ["eps", "emf", "wmf", "xaml", "pdf", "ps", "png", "svg"]

    def _get_cmd(self, *args):
        return '{} --export-type={} -o {} {}'.format(*args)



class Immcvt(FigEngine):
    def __init__(self, appath) -> None:
        super().__init__(appath)
        # ImageMagick supported image formats over 200, no need
        # to check the file's type.

    def _get_cmd(self, *args):
        return '{} {} {}'.format(args[0], args[3], args[2])


class Kroki(FigEngine):
    def __init__(self) -> None:
        self._tool_box = {'.mmd': 'mermaid', '.dot': 'graphviz',
                          '.puml': 'plantuml'}

    def conv_single_to(self, file, target, type='svg', force=False):
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

        if not os.path.exists(target):
            os.mkdir(target)
        fig_path = '{}/{}.{}'.format(target, fname, type)
        if force or not self.check_file_existence(fig_path):
            response = requests.get(kroki_url)
            if response.status_code == 200:
                with open(fig_path, "wb") as fw:
                    fw.write(response.content)
            else:
                self.eprint('Error: Remote response error')


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
                        default='/usr/bin/magick',
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
    parser.add_argument('source', nargs='*',
                        help='the drawio source files')
    args = parser.parse_args()

    return args


if __name__ == "__main__":
    args = cli()

    # drawio
    drawios = []
    dotfiles = []
    mmds = []
    figs = []

    filter_re = re.compile(r'.*[.](\w+)$')
    for file in args.source:
        if not os.path.exists(file):
            print(f'No such file: {file}, ignore it')
            continue
        m = filter_re.search(file)
        if not m:
            print(f'figure-generator can not get {file} type, ignore it')
            continue
        ext = m.group(1)
        if ext == 'drawio':
            drawios.append(file)
        elif ext == 'dot':
            dotfiles.append(file)
        elif ext == 'mmd':
            mmds.append(file)
        else:
            figs.append(file)

    if figs:
        if not args.convert:
            print(f'Specify --convert option when convert figures')
            exit(1)
        else:
            svgs = [f for f in figs if '.svg' in f]
            others = [f for f in figs if '.svg' not in f]
            if svgs:
                Inkcvt(args.inkscape).conv_to(svgs, args.output, args.format, args.force)
            if others:
                Immcvt(args.imagemagick).conv_to(others, args.output, args.format, args.force)

    if drawios:
        args_drawio = args.drawio
        if not os.path.exists(args_drawio):
            res = subprocess.run(['whereis', '-b', 'drawio'], capture_output = True, text = True)
            args_drawio = res.stdout.replace('drawio: ', '').strip()
        Drawio(args_drawio).conv_to(drawios, args.output, args.format, args.force)
            
    if dotfiles:
        Gradot(args.gradot).conv_to(dotfiles, args.output, args.format, args.force)

    if mmds:
        Kroki().conv_to(mmds, args.output, args.format, args.force)

