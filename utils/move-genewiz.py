#!/usr/bin/env python3
"""
A program to move all the files produced by GeneWiz in a single directory, with renaming options
"""
version = "0.1"
import os, sys, argparse, re
from shutil import copyfile

def printVersion():
    print("Version:", version)
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def checkFilename(filename):
    """
    Check if filename is in the SAMPLE_S{number}_R{1,2}_001.fastq.gz format
    """
    if re.match(r'.+_S\d+_R\d+_001.fastq.gz', filename):
        return True
    else:
        return False
def rename(filename):
    """
    Rename the file to the standard GeneWiz naming convention
    if the filename contains a pattern, remove it
    """
    pattern = re.compile(r'PID-\d+-')
    if pattern.search(filename):
        filename = pattern.sub('', filename)
    return filename

    
if __name__ == "__main__":
    arguments = argparse.ArgumentParser(description="Collapse files produced by GeneWiz")
    arguments.add_argument("-i", "--input", help="Input directory")
    arguments.add_argument("-o", "--output", help="Output directory")
    arguments.add_argument("-r", "--rename", help="Auto rename files", action="store_true")
    arguments.add_argument("-s", "--suffix", help="Suffix to add to renamed files", default="")
    arguments.add_argument("-p", "--prefix", help="Prefix to add to renamed files", default="")
    arguments.add_argument("-d", "--delete", help="Delete original files", action="store_true")
    arguments.add_argument("-f", "--force", help="Force overwrite of existing files", action="store_true")
    arguments.add_argument("--version", help="Print version", action="store_true")
    args = arguments.parse_args()

    if args.version:
        printVersion()
        sys.exit(0)
    elif args.input is None or args.output is None:
        
        arguments.print_help()
        eprint("Input and output directories are required")
        sys.exit(1)

    if not os.path.isdir(args.input):
        eprint("Input directory does not exist")
        sys.exit(1)

    if not os.path.exists(args.output):
        try:
            os.makedirs(args.output)
        except Exception as e:
            eprint("Could not create output directory:", e)
            sys.exit(1)

    # Store files to be moved in a path -> destname dict
    files = {}

    action = "copy" if not args.delete else "move"

    # Scan input directory (contains a subdir per sample)
    for sample in os.listdir(args.input):
        sampleDir = os.path.join(args.input, sample)
        if not os.path.isdir(sampleDir):
            eprint("Skipping file :", sampleDir, "(expecting a sample directory)")
            continue
        for filename in os.listdir(sampleDir):
            sourcePath = os.path.join(sampleDir, filename)

            if not checkFilename(sourcePath):
                eprint("Skipping file (unrecognized format):", sourcePath)
                continue
            
            if args.rename:
                destName = rename(filename)
            else:
                destName = filename

            if args.suffix:
                destName = destName + args.suffix
            
            if args.prefix:
                destName = args.prefix + destName

            destPath = os.path.join(args.output, destName)
            files[sourcePath] = destPath

            destPath = os.path.join(args.output, destName)
            files[sourcePath] = destPath
            eprint("Preparing to ", action, ":", sourcePath, "to", destPath)
    
    # Check if files has duplicated values
    if len(files) != len(set(files.values())):
        eprint("Duplicated destination files!")
        sys.exit(1)

    # Move or copy files
    for sourcePath, destPath in files.items():
        if os.path.exists(destPath) and not args.force:
            eprint("Skipping file (already exists):", destPath)
            continue
        print("-", sourcePath, "to", destPath, end="", flush=True)
        if args.delete:
            try:
                os.rename(sourcePath, destPath)
            except Exception as e:
                print(" ERROR")
                eprint("Could not move file:", e)
                sys.exit(1)
            print(" MOVED")
        else:
            
            try:
                copyfile(sourcePath, destPath)
            except Exception as e:
                print("ERROR")
                eprint("Could not link file:", e)
                sys.exit(1)
            print(" COPIED")(base)