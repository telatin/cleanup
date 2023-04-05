#!/usr/bin/env python
"""
Andrea Telatin 2022

Pedantic check of fastq files (single-end and paired-end)
 * Only ASCII characters
 * No empty lines
 * Length of quality and sequence match
 * Only DNA chars in sequence

NOW IN SEQFU: seqfu check 
"""

from copy import deepcopy
import sys
import os
import argparse
import gzip
import json
from datetime import datetime

def checkGZ(filename):
    """
    Check if a file is GZipped
    """
    with open(filename, 'rb') as f:
        return f.read(2) == b'\x1f\x8b'

def stringIsAscii(s):
    return all(ord(c) < 128 for c in s)

def inc(d, key):
    if key in d:
        d[key] += 1
    else:
        d[key] = 1
    
    return d
def checkSE(file):
    errors = {}
    data = {"libType": "SE", "totalBp": 0, "countReads": 0, "sFirst": None, "sLast": None}

    if checkGZ(file):
        fh = gzip.open(file, 'rt')
    else:
        fh = open(file, 'r')
    
    for i, line in enumerate(fh):
        if not stringIsAscii(line):
            errors = inc(errors, "non-ascii")
            

        
        if i % 4 == 0:
            
            if line.startswith("@"):
                data["countReads"] += 1
            else:
                errors = inc(errors, "nonHeaderAtStart")
            if i == 0:
                data["sFirst"] = line[1:].strip().split()[0] 
            data["sLast"] = line[1:].strip().split()[0]
            
        elif i % 4 == 1:
            # check if sequence is DNA
            if not all(c in "ACGTN" for c in line.strip().upper()):
                errors = inc(errors, "nonDNA")
            length = len(line.strip())
            data["totalBp"] += length
        elif i % 4 == 2:
            if not line.startswith("+"):
                errors = inc(errors, "nonPlusAtStart")
        elif i % 4 == 3:
            if length != len(line.strip()):
                errors = inc(errors, "lengthMismatch")
                print("Length mismatch at line %d: %d/%d: %s" % (i, length, len(line.strip()), line))
    

        

    return errors, data
            
def checkPE(file1, file2):
    errors = {}
    
    e1, d1 = checkSE(file1)
    e2, d2 = checkSE(file2)
    data = deepcopy(d1)
    data["libType"] = "PE"
    if len(e1) > 0 or len(e2) > 0:
        print("Errors in %s: %s" % (file1, e1))
        print("Errors in %s: %s" % (file2, e2))
        # Combine dictionaries e1 and e2
        errors = {**e1, **e2}
    
    if d1["sFirst"] == d2["sFirst"]:
        pass
    elif d1["sFirst"][:-2] == d2["sFirst"][:-2]:
        data["sFirst"] = d1["sFirst"][:-2] 
    elif d1["sFirst"][:-3] == d2["sFirst"][:-3]:
        data["sFirst"] = d1["sFirst"][:-3] 
        if len(data["sFirst"]) < 2:
            errors = inc(errors, "sFirstTooShort")
    else:
        errors = inc(errors, "sFirstMismatch")
        data["sFirst"] = d1["sFirst"][:-2] + " / " + d2["sFirst"][:-2]
    
    if d1["sLast"] == d2["sLast"]:
        pass
    elif d1["sLast"][:-2] == d2["sLast"][:-2]:
        data["sLast"] = d1["sLast"][:-2] 
    elif d1["sLast"][:-3] == d2["sLast"][:-3]:
        data["sLast"] = d1["sLast"][:-3] 
        if len(data["sLast"]) < 2:
            errors = inc(errors, "sLastTooShort")
    else:
        errors = inc(errors, "sLastMismatch")
        data["sLast"] = d1["sLast"][:-2] + " / " + d2["sLast"][:-2]

    if d1["countReads"] != d2["countReads"]:
        errors = inc(errors, "readsCountMismatch")

    return errors, data

def inputFilesCheck(files):
    """
    Check if input files exist
    """
    for f in files:
        if not os.path.exists(f):
            print("File %s not found (%s)" % (f, len(files)))
            sys.exit(1)
        elif os.path.isdir(f):
            print("File %s is a directory (%s)" % (f, len(files)))
            sys.exit(1)

def detectRev(fwd):
    files = []
    if "_R1." in fwd:
        
        files.append( fwd.replace("_R1.", "_R2.") )
    elif "_1." in fwd:
        files.append( fwd.replace("_1.", "_2.") )
    elif "_R1_" in fwd:
        files.append( fwd.replace("_R1_", "_R2_") )
    elif "_1_" in fwd:
        files.append( fwd.replace("_1_", "_2_") )
    elif "_R1" in fwd:
        files.append( fwd.replace("_R1", "_R2") )
    elif "_1" in fwd:
        files.append( fwd.replace("_1", "_2") )

    for f in files:
        if os.path.isfile(f):
            return f

if __name__ == "__main__":
    args = argparse.ArgumentParser()
    args.add_argument('-1', dest="FOR", help='FASTQ file', required=True)
    args.add_argument('-2', dest="REV", help='Reverse FASTQ file', default=None)
    
    args.add_argument('--pe',help='Autodetect PE',action='store_true')
    
    args.add_argument('--verbose',help='Verbose output',action='store_true')
    args = args.parse_args()

    errors = None
    data = None
    REV = detectRev(args.FOR)
    startTime = datetime.now()
    if args.REV is None and not args.pe:
        
        inputFilesCheck([args.FOR])

        if REV is not None:
            print("WARNING: Reverse file detected: %s" % REV, file=sys.stderr)
            
        errors, data = checkSE(args.FOR)
    else:
        if args.REV is not None:
            REV = args.REV
        if args.verbose:
            print("Checking PE:\n - %s\n - %s" % (args.FOR, REV), file=sys.stderr)
        inputFilesCheck([args.FOR, REV])
        errors, data = checkPE(args.FOR, REV)
    
    if len(errors) > 0:
        print("ERRORS: %s" % errors)
        print(data)
        exit(1)
    
    print(json.dumps(data, indent=4, sort_keys=True))

    if args.verbose and data["countReads"] > 0:
        # Calculate sequence/second
        duration = datetime.now() - startTime
        print("Duration: %s" % duration, file=sys.stderr)
        reads = data["countReads"] if data["libType"] == "SE" else data["countReads"] * 2
        try:
            print("Sequences/second: %d" % (reads / duration.total_seconds()), file=sys.stderr)
        except Exception:
            pass
        