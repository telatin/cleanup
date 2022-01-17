# cleanup

![Cleanup Pipeline](cleanup.jpg)

Nextflow pipeline to preprocess metagenomics reads:

1. Discarding failed samples (< 1000 reads)
2. Host removal (Kraken2, tipically against _Homo sapiens_)
3. Adapter filtering (fastp, quality filtering is disabled)
4. Fast profiling (Kraken2) to evaluate the fluctuations in unclassified reads
5. MultiQC report

## Phylosophy

This is a preprocessing pipeline that aims at the minimal loss of information,
while allowing to store the reads in general purpose storage (where Human reads
are not allowed).

The "Fastp" step disables any quality filtering, limiting its action to the
adaptor removal and discarding reads that are too short afterwards.