#!/usr/bin/env python
"""
Check Kraken2 report done with a chromosome-by-chromosome contaminants DB
"""

import os, sys

controls = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8", "chr9", "chr10", "chr11", "chr12", "chr13", "chr14", "chr15", "chr16", "chr17", "chr18", "chr19", "chr20", "chr21", "chr22", "chrX", "chrY"]
detectable = ["chr1", "chr2", "chr3", "chr4"]
if __name__ == "__main__":
    import argparse
    args = argparse.ArgumentParser()
    args.add_argument("REPORT", help="Kraken2 report", type=argparse.FileType('r'))
    args.add_argument("-o", "--output", help="Output file", default=sys.stdout)
    args.add_argument("-m", "--min-ratio", help="Minimum ratio of control chromosomes/total chromosomes", default=0.2)
    args.add_argument("-c", "--min-classified", help="Minimum 'host' reads", default=0.03)
    # Add a list of strings
    args.add_argument("-d", "--controls", help="List of taxa (denominator)", nargs="*", default=controls)
    args.add_argument("-n", "--numerator", help="List of taxa (numerator)", nargs="*", default=detectable)
    args.add_argument("--fail-safe", help="Return 0, even if control fails", action="store_true")
    args.add_argument("--debug", help="Debug mode", action="store_true")
    args = args.parse_args()

    if args.debug:
        print(" - Checking %s" % args.REPORT.name, file=sys.stderr)
        print(" - Controls: %s" % args.controls, file=sys.stderr)
    percentages = {}
    counts = {}
    total_pct = 0
    numerator_pct = 0
    for line in args.REPORT:
        if line.startswith("#"):
            continue
        # Split by spaces (1 or more)
        data = line.split()

        if len(data) > 6:
            # join all the fields after the 6th one
            data[5] = " ".join(data[5:])
            # Remove fields after the 6th one
            data = data[:6]
            if args.debug:
                print("   INFO: species with spaces: '%s' [%s]" % (data[5],len(data)), file=sys.stderr)
        
        try:
            (percentage, tot, clade, rank, taxid, taxname) = data
        except ValueError:
            print("Error: %s" % line, file=sys.stderr)
            continue
        percentages[taxname] = float(percentage)
        counts[taxname] = int(tot)
        if taxname in args.controls:
            total_pct += float(percentage)
            numerator_pct += float(percentage) if taxname in detectable else 0
            

    if total_pct == 0:
        print("No chr contam", file=args.output)
        sys.exit(0)
    ratio = numerator_pct / total_pct
    if args.debug:
        print(" - Unclassified %s" % percentages["unclassified"], file=sys.stderr)
        print(" - Total classified %.2f" % total_pct, file=sys.stderr)
        for chr in args.controls:
            # format chr with leading spaces (width=10)
            if (100-percentages["unclassified"]) > 0: 
                print(" - chr:%15s\t%.3f" % (chr, 100*percentages[chr]/(100-percentages["unclassified"])), file=sys.stderr)
    
    # Print ratio with 2 decimals
    print("%s" % ("%.2f" % ratio), file=args.output)

    if ratio < float(args.min_ratio) and total_pct > float(args.min_classified):
        print("FAIL: Ratio is below %s, classified above %s" % (args.min_ratio, args.min_classified), file=sys.stderr)
        if not args.fail_safe:
            sys.exit(1)
        else:
            sys.exit(0)
    else:
        print("PASS: Ratio is above or equal to %s (and classified > %s)" %  (args.min_ratio, args.min_classified), file=sys.stderr)

        