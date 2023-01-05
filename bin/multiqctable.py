#!/usr/bin/env python3
"""
Generate a MultiQC ready table.
Receives a list of *.fastp.json files and from those rescue the basename.*.txt
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
#         placement: 10
#     col2:
#         title: 'Host (%)'
#         description: 'Fraction of host reads'
#         placement: 20
#     col3:
#         title: 'Non-host reads'
#         description: 'Number of reads after host removal'
#         format: '{:,.0f}'
#         placement: 30
#     col4:
#         title: 'PF (%)'
#         description: 'Fraction of reads passing filters (host removal and adapter trimming)'
#         placement: 40
#     col5:
#         title: 'Cleaned reads'
#         description: 'Number of reads after fastp filter'
#         format: '{:,.0f}'
#         placement: 50
#     col6:
#         title: 'Contaminants reads'
#         description: 'Number of contaminants reads (optional step)'
#         format: '{:,.0f}'
#         placement: 60
#     col7:
#         title: 'HG-Check'
#         description: 'Ratio of large chromosomes/total human chromosomes'
#         placement: 70
Sample\tcol1\tcol2\tcol3\tcol4\tcol5\tcol6\tcol7
"""

def loadHost(filename):
    data = {
        "Human": 0,
        "Non-human": 0,
    }

    # Return empty dict if file does not exist
    if not os.path.isfile(filename):
        return data

    with open(filename, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            key, val = line.strip().split(':')
            data[key] = val
    return data

def checkContaminants(file):
    try:
        with open(file, 'r') as f:
            for line in f:
                if line.startswith('reads mapped:') or line.startswith('#Matched'):
                    return int(line.split(':')[1].strip())
    except Exception as e:
        return "N/A"

def slurp(filename):
    try:
        with open(filename, 'r') as f:
            return f.read()
    except Exception as e:
        return "N/A"

if __name__ == "__main__":
    args = argparse.ArgumentParser(description='Generate a MultiQC ready table')
    args.add_argument('-j', '--fastp-json', help='FASTP json files', nargs='+')
    args.add_argument('-s', '--json-suffix', help='Suffix of the json files [default: %(default)s]', default='.fastp.json')
    args.add_argument('-z', '--host-suffix', help='Suffix of the host files [default: %(default)s]', default='.host.txt')
    args.add_argument('--contam-suffix', help='Suffix of the host files [default: %(default)s]', default='.contaminants.txt')
    args.add_argument('--ratiocheck-suffix', help='Suffix of the ratio check files [default: %(default)s]', default='.ratio.txt')
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

        # Output columns
        # 1. Total
        row.append(str(total))
        # 2. HostRatio
        row.append(hostRatio.__format__('.2%'))
        # 3. Non-host
        row.append(str( host_data["Non-human"] ))
        # 4. FiltRatio
        row.append(filtRatio.__format__('.2%'))
        # 5. Cleaned
        row.append(str(fastp_json["read1_after_filtering"]["total_reads"]))
        # 6. Contaminants
        contamfile = file.replace(opts.json_suffix, opts.contam_suffix)
        row.append(str( checkContaminants(contamfile)))
        # 7. RatioCheck
        ratiocheckfile = file.replace(opts.json_suffix, opts.ratiocheck_suffix)
        row.append( str( slurp(ratiocheckfile) ))
        print("\t".join(row), file=outfile)



