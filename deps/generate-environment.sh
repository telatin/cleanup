mamba create -n cleanup -y -c conda-forge -c bioconda \
  nextflow pigz "seqfu>=1.14.0" "kraken2=2.1.0" "krakentools>=1.2" bracken  "multiqc>1.9" \
  "samtools>=1.12" bwa kaiju fastp \
  "megahit" minia prodigal quast eggnog-mapper \
  bbmap
