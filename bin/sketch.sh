#!/bin/bash
# Minimal script to clean metagenomic reads
# Dependencies:
# FastQC, fastp, kraken2, jq

KRAKEN2_HUMAN=/qi/projects/hostzap/qi/kraken2_human
KRAKEN2_DB=/qi/db/kraken2/Std16/
THREADS=8
MINLEN=80
R1=$1
OUTDIR=$2
FASTQC=$3
# USAGE
# clean.sh File_R1.fq.gz Outdir/ [Fastqc=1]

if [[ ! -e $R1 ]]; then 
  echo "Usage: clean.sh FILE_R1 OUTDIR. Missing input file"; exit 1;
fi

R2=${R1/_R1/_R2}
if [[ $R1 == $R2 ]] || [[ ! -e $R2 ]]; then
  echo "Missing R2 $R2"
  exit 1
fi

# Required variables
BASENAME=$(basename "$R1" | cut -f 1 -d _)

REPORT="$OUTDIR"/${BASENAME}.report.txt


# Check outdir
if [[ ! -d $OUTDIR ]]; then
  echo Missing output dir
  exit 1
fi
mkdir -p "$OUTDIR"/parts

echo "Sample name,$BASENAME" > $REPORT

# Check if FASTP was already out
if [[ -e "$OUTDIR"/${BASENAME}.fastp.json ]]; then
  echo "Output found: $OUTDIR/${BASENAME}.fastp.json"
  exit
fi

set -euxo pipefail

# Preliminary FASTQC
if [[ $FASTQC == 1 ]]; then
  fastqc --threads $THREADS -o "$OUTDIR"/ "$R1" "$R2"
  rm "$OUTDIR"/${BASENAME}*.zip
  mv "$OUTDIR"/${BASENAME}*R1*html "$OUTDIR"/${BASENAME}_R1.fastqc.html
  mv "$OUTDIR"/${BASENAME}*R2*html "$OUTDIR"/${BASENAME}_R2.fastqc.html
fi

# Run Kraken2 to remove human reads
echo -n "Total reads," >> $REPORT
kraken2 --db $KRAKEN2_HUMAN --threads $THREADS \
  --paired --memory-mapping \
  --report "$OUTDIR"/${BASENAME}.tsv \
  --unclassified-out "$OUTDIR"/${BASENAME}-nohost#.fq \
  --classified-out "$OUTDIR"/${BASENAME}-host#.fq \
  "$R1" "$R2"  2>&1 >/dev/null | grep -Po "\d+" | head -n 1 >> $REPORT

# Minimal Quality filter
fastp -w $THREADS -i "$OUTDIR"/${BASENAME}-nohost_1.fq -I "$OUTDIR"/${BASENAME}-nohost_2.fq \
  -o "$OUTDIR"/${BASENAME}_R1.fq.gz -O "$OUTDIR"/${BASENAME}_R2.fq.gz \
  -h "$OUTDIR"/${BASENAME}-report.html -j "$OUTDIR"/${BASENAME}.fastp.json \
  --detect_adapter_for_pe --disable_quality_filtering  \
  -l $MINLEN --failed_out "$OUTDIR"/${BASENAME}.failed.fq.gz

sed -i 's/-nohost_.//g' "$OUTDIR"/${BASENAME}.fastp.json

# Kraken2 on filtered
echo -n "Classified Std," >> $REPORT
kraken2 --db $KRAKEN2_DB --threads $THREADS \
  --paired --memory-mapping \
  --report "$OUTDIR"/profile_${BASENAME}.tsv \
  "$OUTDIR"/${BASENAME}_R1.fq.gz "$OUTDIR"/${BASENAME}_R2.fq.gz   2>&1 >/dev/null \
  | grep "sequences classified" | grep -Po "\d+" | head -n 1 >> $REPORT
  
# Remove kraken unclassified (now filtered)
rm "$OUTDIR"/${BASENAME}-nohost_*

#Move unnecessary files
mv -v "$OUTDIR"/${BASENAME}*{host,failed}* "$OUTDIR"/parts/

# Compress
pigz -p $THREADS "$OUTDIR"/parts/${BASENAME}*.fq

# Mini report

echo -n "Reads no-host," >> $REPORT
jq.py -a read1_before_filtering,total_reads  "$OUTDIR"/${BASENAME}.fastp.json >> $REPORT
echo -n "Reads filtered," >> $REPORT
jq.py -a read1_after_filtering,total_reads  "$OUTDIR"/${BASENAME}.fastp.json  >> $REPORT