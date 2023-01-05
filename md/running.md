# Example execution

## Command

```bash
nextflow run telatin/cleanup -r main -profile nbi,slurm \
  --reads "reads/*_{1,2}.fastq.gz" \
  --savehost
```

## Runtime output

```text
N E X T F L O W  ~  version 21.10.6

GMH Cleanup pipeline (version 1.4)
====================================

reads        : sub/*_R{1,2}.fastq.gz
outdir       : ./cleaned_reads/
min reads    : 1000
host db      : /qib/platforms/Informatics/transfer/outgoing/databases/kraken2/cleanup-db
kraken db    : /qib/platforms/Informatics/transfer/outgoing/databases/kraken2/gutcheck-db
-----------------------------------
Extras       : None

Monitor the execution with Nextflow Tower using this url https://tower.nf/user/andreatelatin-gh/watch/2CxGJczqNUEaez
executor >  slurm (49)
[30/52c42a] process > MINREADS (A02)            [100%] 4 of 4 ✔
[e7/fef238] process > ILLUMINA_INDEX (A02)      [100%] 4 of 4 ✔
[e1/40efdc] process > ILLUMINA_TABLE            [100%] 1 of 1 ✔
[d6/8eecc2] process > KRAKEN2_HOST (A01)        [100%] 4 of 4 ✔
[e4/dc8635] process > CHECK_REPORT (A01)        [100%] 4 of 4 ✔
[29/058805] process > PIGZ_READS (A01)          [100%] 4 of 4 ✔
[67/66a1dc] process > PIGZ_HOST (A01)           [100%] 4 of 4 ✔
[fa/d49d1a] process > HOSTQC                    [100%] 1 of 1 ✔
[3c/2b725b] process > MINREADS_FINALCHECK (A01) [100%] 4 of 4 ✔
[2a/fa48cc] process > RELABEL (A01)             [100%] 4 of 4 ✔
[49/8dfd60] process > FASTP (B10)               [100%] 4 of 4 ✔
[d2/20c1c2] process > KRAKEN2_REPORT (B10)      [100%] 4 of 4 ✔
[33/0b35b4] process > GETLEN                    [100%] 1 of 1 ✔
[1e/d365d5] process > BRACKEN (B10.kraken2.tsv) [100%] 4 of 4 ✔
[d6/e51310] process > TRACKFILES                [100%] 1 of 1 ✔
[6f/4fab8c] process > MULTIQC                   [100%] 1 of 1 ✔
Completed at: 05-Jan-2023 15:47:08
Duration    : 36m 10s
CPU hours   : 17.7
```
