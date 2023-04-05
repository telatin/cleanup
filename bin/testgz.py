from gz import gzip_pipe
import argparse
import sys, os

args = argparse.ArgumentParser(description="Compress files using a stream rather than invoking gzip (original file is preserved, symlink friendly). Do not compress emtpy files.")
args.add_argument("files", nargs="+", help="Files to compress")
args.add_argument("-o", "--output-directory", help="Output directory [default: %(default)s]", default=".")
args = args.parse_args()

if not os.path.exists(args.output_directory):
    os.makedirs(args.output_directory)

for file in args.files:
    if file.endswith(".gz"):
        print("      |Skipping {}".format(file), file=sys.stderr)
        continue
    output = os.path.join(args.output_directory, file + ".gz")
    print(file)
    if gzip_pipe(file, output):
        print("OK    | Compressed {} to {}".format(file, output))
    else:
        print("FAIL  |Error compressing {}".format(file))
        sys.exit(1)