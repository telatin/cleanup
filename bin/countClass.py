#!/usr/bin/env python3
"""
a script counting the lines of input starting as "C" (classified) or "U" (unclassified),
as produced by Kraken. Will print the total that can be relabelled.
"""
import sys

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Count the number of instances of each class in a dataset.')
    parser.add_argument('-i', '--input', help='Input file')
    parser.add_argument('-o', '--output', help='Output file')
    parser.add_argument('-c', '--classified-string', help='String to use to indicate classified reads [default: %(default)s', default="Classified")
    parser.add_argument('-u', '--unclassified-string', help='String to use to indicate unclassified reads [default: %(default)s', default="Unclassified")
    parser.add_argument('--check', help='Check valid Kraken2 output', action='store_true')
    parser.add_argument('--total', help='Add total', action='store_true')
    
    args = parser.parse_args()

    
    inputfile = sys.stdin if args.input is None else open(args.input, 'r')
    outputfile = sys.stdout if args.output is None else open(args.output, 'w')
    

    counter = {
        'C': 0,
        'U': 0
    }
    tot = 0
    # Read from stdin
    for line in inputfile:
        if args.check: 
            tot += 1
        if line[0] in counter:
            counter[line[0]] += 1
        else:
            counter[line[0]] = 1
    
    print("{}:{}".format(args.classified_string,   counter['C']), file=outputfile)
    print("{}:{}".format(args.unclassified_string, counter['U']), file=outputfile)
    if args.total:
        print("{}:{}".format("Total", counter['C']+counter['U']), file=outputfile)
    if args.check:
        if counter['C'] + counter['U'] != tot:
            print("ERROR: Kraken2 output is not valid", file=sys.stderr)
            sys.exit(1)
