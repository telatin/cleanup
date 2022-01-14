# cleanup

Nextflow pipeline to preprocess metagenomics reads:

1. Host removal (Kraken2, tipically against _Homo sapiens_)
2. Adapter filtering (fastp, quality filtering is disabled)
3. Fast profiling (Kraken2)
4. MultiQC report