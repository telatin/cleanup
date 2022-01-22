mamba create -n cleanup -y -c conda-forge -c bioconda \
  nextflow pigz "seqfu>=1.9" "kraken2=2.1.0" "krakentools>=1.2" bracken "samtools>=1.12" bwa kaiju fastp "multiqc>1.9" \
  "megahit" prodigal 
