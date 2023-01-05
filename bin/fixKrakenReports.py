#!/usr/bin/env python
"""
Edit in-place kraken2 reports with 1 line in total
"""

import sys
import os
import argparse

args = argparse.ArgumentParser()
args.add_argument('REPORT', help='Kraken2 report', nargs='+')
args = args.parse_args()

for report in args.REPORT:
    with open(report, 'r') as f:
        lines = f.readlines()
        if len(lines) == 1:
            print("WARNING: {report} has only 1 line.\n Adding a dummy line to avoid errors in MultiQC".format(report=report), file=sys.stderr)
        lines.append("0.0\t0\t0\tU\t0\tunclassified\n")
        
        with open(report, 'w') as o:
            o.write("".join(lines))
