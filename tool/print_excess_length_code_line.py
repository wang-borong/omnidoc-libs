#!/usr/bin/env python

import re
import argparse


def get_excess_length_code_line(file, maxlen):
    lnr = 0
    with open(file, 'r') as f:
        lines = f.readlines()
        for line in lines:
            lnr += 1
            if '//' in line or re.match(r'.*\/?\*.*', line):
                if len(line) > maxlen:
                    print('{} +{} -> "{}"'.format(file, lnr, line))


def cli():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-M', '--maxlen', type=int,
                        default=80,
                        help='set the max line length')
    parser.add_argument('files', nargs='+',
                        help='the files')
    args = parser.parse_args()

    return args


if __name__ == '__main__':
    args = cli()

    for file in args.files:
        get_excess_length_code_line(file, args.maxlen)
