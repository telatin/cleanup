#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Compress files using a stream (cat file | gzip > file.gz) rather than invoking gzip.
Do not compress emtpy files.
"""
import argparse
import gzip
import os, sys
import shutil
import subprocess

def gzip_pipe(input, output):
    """
    perform a "cat input | gzip > output" using subprocess
    """
    cmd = f'cat "{input}" | gzip -c > "{output}"'
    print("| {}".format(cmd))
    proc = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    output = proc.communicate()[0].decode("utf-8")
    print("| {} | {}".format(output, proc.returncode))
    status = proc.returncode
    return status == 0

if __name__ == "__main__":
    args = argparse.ArgumentParser(description="Compress files using a stream rather than invoking gzip (original file is preserved, symlink friendly). Do not compress emtpy files.")
    args.add_argument("files", nargs="+", help="Files to compress")
    args.add_argument("-o", "--output-directory", help="Output directory [default: %(default)s]", default=".")
    args.add_argument("-f", "--force", action="store_true", help="Remove output files if they exist")
    
    other_options = args.add_argument_group("Other options")
    other_options.add_argument("--rm", action="store_true", help="Remove input files after compression")
    other_options.add_argument("--verbose", action="store_true", help="Verbose output")
    args = args.parse_args()

    

    errors = []
    for file in args.files:
        if not os.path.exists(file):
            print("WARNING: File does not exist: {}".format(file))
            continue
        real_file = os.path.realpath(file)
        gz_file = os.path.join(args.output_directory, os.path.basename(file) + ".gz")

        # Chec if output file exists and remove if necessary
        if os.path.exists(gz_file):
            if args.force:
                os.remove(gz_file)
            else:
                print("Output file exists: {}".format(gz_file), file=sys.stderr)
                continue
        # Skip empty files
        if os.path.getsize(real_file) == 0:
            if args.verbose:
                print("Skipping empty file {}".format(file), file=sys.stderr)
            continue

        
        if args.verbose:
            print("Compressing {} to {}".format(file, gz_file), file=sys.stderr)
        
        try:
            with open(real_file, "rb") as f_in:
                with gzip.open(gz_file, "wb") as f_out:
                    shutil.copyfileobj(f_in, f_out)
        except Exception as e:
            print("Error compressing {}: {}".format(file, e), file=sys.stderr)
            errors.append(file)
            continue

        if os.path.getsize(gz_file) == 0:
            print("Error compressing {}: output file is empty, trying shell".format(file), file=sys.stderr)
            if gzip_pipe(file, gz_file):
                print("Compressed {}".format(file), file=sys.stderr)
            else:
                print("Error compressing {}: aborting".format(file), file=sys.stderr)
                errors.append(file)
                continue

    if len(errors) > 0:
        print("Errors occurred during compression of {}".format(", ".join(errors)), file=sys.stderr)
        sys.exit(1)

        