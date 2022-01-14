#!/usr/bin/env python3
"""
Generate a MultiQC ready table
"""
import sys, os, json
import argparse

report_header = """
# plot_type: 'table'
# section_name: 'Host removal'
# description: 'Summary host removal and read filtering step'
# pconfig:
#     namespace: 'Cust Data'
# headers:
#     col1:
#         title: 'Raw sequences'
#         description: 'Initial number of sequences'
#         format: '{:,.0f}'
#     col2:
#         title: '% Host'
#         description: 'Fraction of host reads'
#     col3:
#         title: 'Non-host reads'
#         description: 'Number of reads after host removal'
#         format: '{:,.0f}'
#     col4:
#         title: '% Passing Filters'
#         description: 'Fraction of reads passing filters (host removal and adapter trimming)'
#     col5:
#         title: 'Cleaned reads'
#         description: 'Number of reads after fastp filter'
#         format: '{:,.0f}'
Sample\tcol1\tcol2\tcol3\tcol4\tcol5
"""

def loadHost(filename):
    data = {}
    with open(filename, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            key, val = line.strip().split(':')
            data[key] = val
    return data

if __name__ == "__main__":
    args = argparse.ArgumentParser(description='Generate a MultiQC ready table')
    args.add_argument('-j', '--fastp-json', help='FASTP json files', nargs='+')
    args.add_argument('-s', '--json-suffix', help='Suffix of the json files [default: %(default)s]', default='.fastp.json')
    args.add_argument('-z', '--host-suffix', help='Suffix of the host files [default: %(default)s]', default='.host.txt')
    args.add_argument('-o', '--output', help='Output file [default: %(default)s]', default='summary_mqc.txt')
    opts = args.parse_args()

    outfile = open(opts.output, 'w') if opts.output is not None else sys.stdout
    print (report_header.strip(), file=outfile)
    # Existing files
    for file in opts.fastp_json:
        basename = os.path.basename(file).replace(opts.json_suffix, "")
        fastp_json = json.load(open(file))
        host_data  = loadHost(file.replace(opts.json_suffix, opts.host_suffix))
        row = [basename]
        # Total reads
        total = int(host_data["Human"]) + int(host_data["Non-human"])
        # % host
        hostRatio =   int(host_data["Human"]) / total
        # % filtered
        filtRatio = int(fastp_json["read1_after_filtering"]["total_reads"]) / total

        row.append(str(total))
        row.append(hostRatio.__format__('.2%'))
        row.append(str( host_data["Non-human"] ))
        row.append(filtRatio.__format__('.2%'))
        row.append(str(fastp_json["read1_after_filtering"]["total_reads"]))
        print("\t".join(row), file=outfile)



