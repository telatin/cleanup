# Example execution

## Command

```bash
nextflow run telatin/cleanup -r main -profile nbi,slurm \
  --reads "reads/*_{1,2}.fastq.gz" \
  --savehost
```

## Runtime output

```text
GMH Cleanup pipeline (version 1.4)
===================================
input reads  : reads/*_{1,2}.fastq.gz
outdir       : cleaned_v2
min reads    : 1000
host db      : cleanup-db/
kraken db    : gutcheck-db
-----------------------------------
Save host/raw: true/false
Contam/Denovo: false/false

executor >  slurm (74)
[8d/2b0896] process > MINREADS (L15)             [100%] 36 of 36, cached: 36 ✔
[58/6f8d66] process > KRAKEN2_HOST (L2)          [100%] 36 of 36, cached: 36 ✔
[4f/b0bf10] process > CHECK_REPORT (L2)          [100%] 36 of 36, cached: 36 ✔
[cd/d823b9] process > PIGZ_READS (L2)            [100%] 36 of 36, cached: 36 ✔
[33/b35b6a] process > MINREADS_FINALCHECK (L2)   [100%] 36 of 36, cached: 36 ✔
[5e/25d1e3] process > FASTP (L2)                 [100%] 36 of 36, cached: 36 ✔
[b3/d12a5b] process > KRAKEN2_REPORT (L2)        [100%] 36 of 36 ✔
[c0/f3ff8d] process > GETLEN                     [100%] 1 of 1, cached: 1 ✔
[2d/f9b87a] process > BRACKEN (P3-8.kraken2.tsv) [100%] 36 of 36 ✔
[a2/506298] process > TRACKFILES                 [100%] 1 of 1 ✔
[d2/469a5a] process > MULTIQC                    [100%] 1 of 1 ✔
WARN: To render the execution DAG in the required format it is required to install Graphviz -- See http://www.graphviz.org for more info.
Completed at: 05-Sep-2022 10:08:54
Duration    : 23m 24s
CPU hours   : 81.1 (87.3% cached)
Succeeded   : 74
Cached      : 217
```
