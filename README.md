# cleanup

[![nextflow-ci](https://github.com/telatin/cleanup/actions/workflows/ci.yaml/badge.svg)](https://github.com/telatin/cleanup/actions/workflows/ci.yaml)
[![last commit](https://img.shields.io/github/last-commit/telatin/cleanup)](https://github.com/telatin/cleanup)
[![last commit](https://img.shields.io/github/v/release/telatin/cleanup)](https://github.com/telatin/cleanup)

![Cleanup Pipeline](cleanup.jpg)

Nextflow pipeline to preprocess metagenomics reads:

1. Discarding failed samples (< 1000 reads)
2. Host removal (Kraken2, tipically against _Homo sapiens_)
3. Removal of specific contaminants sequences via bwa mapping (including Sars-Cov-2, PhiX. _optional_)
4. Adapter filtering (fastp, quality filtering is disabled)
5. Fast profiling (Kraken2) to evaluate the fluctuations in unclassified reads
6. MultiQC report

## Phylosophy

This is a preprocessing pipeline that aims at the minimal loss of information,
while allowing to store the reads in general purpose storage (where Human reads
are not allowed).

The "Fastp" step disables any quality filtering, limiting its action to the
adaptor removal and discarding reads that are too short afterwards.

## Dependencies

The pipeline is written in [Nextflow](https://www.nextflow.io/), 
and its dependencies are available as a
docker container `andreatelatin/cleanup:1.3`.

The YAML file with the conda environment with the required tools
(fastp, kraken2, MultiQC) is provided in `deps/`.

## Databases

The program requires two databases: a **host db** used to remove matchin sequences, and a generic
database to perform a profiling.

Default databases can be downloaded with:

```bash
nextflow run telatin/cleanup -entry getdb --dbdir /path/to/databases/
```

This will download the _host database_ and the _gutcheck_ profiling database (see below).

### Host database

A **custom database** with masked/filtered Human genome, PhiX and Sars-Cov-2 is [available from Zenodo](https://zenodo.org/record/7044072), (see [databases](md/databases.md).

Alternatively, a plain Human database can be downloaded as follows (RefSeq version of GRCh38.p13):

```bash
curl -L -o kraken2_human_db.tar.gz https://ndownloader.figshare.com/files/23567780
tar -xzvf kraken2_human_db.tar.gz
```

### Profiling database

The preliminar profiling is used to evaluate abnormal fractions of unclassified reads.

A minimal databases to detect some common gut microbial species using < 8 GB of RAM is available
from zenodo (see [databases](md/databases.md).

#### Other profiling databases

Two valid options to perform a general purpose profiling are:

* [Standard database with Plants and Fungi (16Gb)](https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16gb_20210517.tar.gz): a small database as provided by [benlangmead](https://benlangmead.github.io/aws-indexes/k2). Useful for execution in local machines with limited memory.
* [kraken2_db_uhgg_v2](http://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0/kraken2_db_uhgg_v2/): a gut specific database from [a unified catalogue of gastrointestinal genomes](https://www.ebi.ac.uk/about/news/service-news/uhgg-v20-released-mgnify), version 2.0

:bulb: To download the human database and the standard database capped at 8Gb, you can run the `bash bin/utils/download.sh` script.

## Usage

```bash
nextflow run main.nf  --reads 'data/*_R{1,2}.fastq.gz' \
   --hostdb $DB/kraken2_human/ --krakendb $DB/std16/ [--contaminants contam.fa] [-profile docker]
```

Notable options:

* `--saveraw`: save reads after host removal but prior to FASTP filtering [default: false]
* `--savehost`: save the reads flagged as host [default: false]
* `--contaminants FASTA`: also filter against a fasta file [:warning: experimental]
* `--denovo`: enable assembly

Profiles:

* `-profile docker`: use a Docker container for dependencies (will fetch it from DockerHub)
* `-profile singularity`: use a Singularity image for dependencies (will be created from DockerHub)
* `-profile test`: will test the pipeline with minimal reads and databases (requires: 8 cores, 16Gb ram)
* `-profile nbi,slurm`: will use default location in the NBI cluster and SLURM scheduler
* `-profile nbi --max_cpus INT --max_memory INT.GB`: will use local resources of a QIB Virtual Machine

## Output directory

The output directory contains a [MultiQC report](https://telatin.github.io/microbiome-bioinformatics/attachments/cleaner_report.html), and the following subdirectories:

* **reads**: the main output: final reads without adapters and host contamination
* **host-reads**: FASTQ files with the host reads (files can be empty) (requires `--savehost`)
* **raw-reads**: FASTQ files after host removal(requires `--saveraw`)
* **kraken**: kraken reports with the classification against the selected database
* **pipeline_info**: execution [report](https://telatin.github.io/microbiome-bioinformatics/attachments/cleaner_execution.html) and [timeline](https://telatin.github.io/microbiome-bioinformatics/attachments/cleaner_timeline.html).

## Example logs and running output

* [Shell output](md/running.md)
* [Execution report](https://telatin.github.io/microbiome-bioinformatics/attachments/cleaner_execution.html)
* [Timeline](https://telatin.github.io/microbiome-bioinformatics/attachments/cleaner_timeline.html)
