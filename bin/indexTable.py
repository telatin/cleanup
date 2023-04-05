#!/usr/bin/env python
"""
Prepare a MultiQC table from a set of txt file with information on indexes produced by seqfu.

Input:
A set of files (tsv)

Output:
a table with header: index_mqc.txt

"""
# Requires a SeqFu version >1.14
SEQFU_FIELDS = 7
import os
import sys
import argparse
import json


#Filename       Index   Ratio   Pass    Instrument      Run     Flowcell
report_header = """
# plot_type: 'table'
# section_name: 'Illumina indexes'
# description: 'Index data as found in the FASTQ files'
# pconfig:
#     namespace: 'Cust Data'
# headers:
#     col1:
#         title: 'Index'
#         description: 'Detected Illumina index'
#         placement: 20
#     col2:
#         title: 'Ratio'
#         description: 'Ratio of reads with the most common index on the total'
#         format: '{:,.2f}'
#         placement: 30
#     col3:
#         title: 'PASS'
#         description: 'Enough reads have the same index'
#         placement: 11
#     col4:
#         title: 'Instrument'
#         description: 'Intrument ID'
#         placement: 50
#         format: '{:,.0f}'
#     col5:
#         title: 'Run'
#         description: 'Run'
#         placement: 60
#         format: '{:,.0f}'
#     col6:
#         title: 'Flowcell'
#         description: 'Ratio of large chromosomes/total human chromosomes'
#         placement: 70
#         format: '{:,.0f}'
Sample\tcol1\tcol2\tcol3\tcol4\tcol5\tcol6
"""
def main():
    args = argparse.ArgumentParser()
    args.add_argument('TABLE', help='Tsv file with index information', nargs='+')
    args.add_argument('-o', '--output', help='Output file name [default: %(default)s]', default='index_mqc.txt')
    args = args.parse_args()

    # Read the input files
    index = {}

    try:
        outfile = open(args.output, 'w')
    except IOError:
        sys.stderr.write('Cannot write to file: %s' % args.output)
        sys.exit(1)

    for f in args.TABLE:
        try:
            with open(f) as fh:
                for line in fh:
                    if line.startswith('#'):
                        continue
                    line = line.rstrip().split('\t')
                    if len(line) != SEQFU_FIELDS:
                        sys.stderr.write('Invalid line in %s (%s fields required):\n%s' % (f, SEQFU_FIELDS, line))
                        continue

                    filename = os.path.basename(line[0]).replace('.gz', '').replace('.fastq', '').replace('.fq', '')
                    tags = {
                        '_R1': 'R1',
                        '_R2': 'R2',
                        '_1.':  'R1',
                        '_2.':  'R2',
                        '_1_':  'R1',
                        '_2_':  'R2',

                    }
                    # Starting from the end of the string "filename", identify the first occurrence of a tag (from the end!)
                    # and remove it from the filename
                    strand = 'NA'
                    for i in range(len(filename), 0, -1):
                        for t in tags:
                            if filename[:i].endswith(t):
                                filename = filename[:-len(t)]
                                filename = filename[:i-len(t)]
                                strand = tags[t]
                                break
                        if strand != 'NA':
                            break
                    
        

                    if filename not in index:
                        index[filename] = {}
                    index[filename][strand] = line[1:]
        except IOError:
            sys.stderr.write('Cannot read file: %s' % f)
            sys.exit(1)


    print(report_header.strip(), file=outfile)

    for sampleID, hash in index.items():
        #index, ratio, pass, instrument, run, flowcell
        if "R1" in hash and "R2" in hash:
            data = hash["R1"]
            if data[0] != hash["R2"][0]:
                sys.stderr.write('Different indexes found for %s: %s vs %s' % (sampleID, data[0], hash["R2"][0]))
                data[2] = "FAIL"
                data[1] += " / " + hash["R2"][1]
            
            data[1] = (float(data[1]) + float(hash["R2"][1])) / 2
        elif "R1" in hash:
            data = hash["R1"]
        elif "R2" in hash:
            # Error?
            data = hash["R1"]
            data[2] = "FAIL"
            data[0] += " (Missing R1)"
        
        data[4] = "n_" + data[4]
        print(sampleID, "\t".join([str(x) for x in data]), sep='\t', file=outfile)


if __name__ == '__main__':
    main()