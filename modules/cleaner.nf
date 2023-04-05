process GETLEN {
    /* get estimate read length of the reads */
    input:
    path("*")

    output:
    path "len.txt" optional true

    script:
    """
    seqfu cat --min-len 30 | seqfu head --skip 2 -n 4000 * | seqfu stats | cut -f 10 | tail -n 1 > len.txt
    """
}

process RELABEL {
    /* rename the reads also for Kneadata sanity */
    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads) 
    val(separator)
    val(tag1)
    val(tag2)

    output:
    tuple val(sample_id), path("${sample_id}_R{1,2}.fastq") 

    script:
    def forwardtag = tag1 ? "--append ${tag1}"  : ""
    def reversetag = tag2 ? "--append ${tag2}"  : ""
    """
    seqfu cat --strip-comments --strip-name --prefix ${sample_id}${separator} ${forwardtag} ${reads[0]} > ${sample_id}_R1.fastq
    seqfu cat --strip-comments --strip-name --prefix ${sample_id}${separator} ${reversetag} ${reads[1]} > ${sample_id}_R2.fastq
    """   
}
process MINREADS {
    tag "$sample_id"
    label 'process_low'

    input:
    tuple val(sample_id), path(reads) 
    val(min)
    
    output:
    tuple val(sample_id), path("pass/${sample_id}_R*.fastq.gz"), emit: reads optional true 
    
    script:
    // # TOT=\$(seqfu count ${reads[0]} ${reads[1]} | cut -f 2 )
    """
    TOT=\$(seqfu head -n ${min} ${reads[0]} | seqfu count | cut -f 2 )
    echo "HEAD READS ${reads[0]}: \$TOT"
    mkdir -p pass
    # Seqfu head will get always UP TO ${min} reads, so we need to check if we have enough (not -gt!)
    if [[ \$TOT -eq ${min} ]]; then
        echo "PASS"
        mv ${reads[0]} pass/${sample_id}_R1.fastq.gz
        mv ${reads[1]} pass/${sample_id}_R2.fastq.gz
    else
        echo "FAIL: \$TOT < ${min}"
    fi
    #file ${reads[0]}
    
    """
}
process INDEX {
    label 'process_low'

    input:
    path fastadb

    output:
    path("contaminants-ref")

    script:
    """
    mkdir -p contaminants-ref
    cp ${fastadb} contaminants-ref/contaminants.fasta
    bwa index contaminants-ref/contaminants.fasta
    """
}

process MAP_CONTAMINANTS {
    tag "$sample_id"
    label "process_filtering"
    
    input:
    tuple val(sample_id), path(reads)
    path db

    output:
    tuple val(sample_id), path("contaminants.bam"), emit: bam
    
    script:
    """
    # Align reads against the contaminants db
    bwa mem -t ${task.cpus} -L 10,10 contaminants-ref/contaminants.fasta "${reads[0]}" "${reads[1]}" | samtools view -bS > contaminants.bam
    """
}

process REMOVE_MAPPED {
    tag "$sample_id"
    label "process_filtering"
    input:
    tuple val(sample_id), path("contaminants.bam")

    output:
    tuple val(sample_id), path("${sample_id}_{1,2}.fq.gz"), emit: reads optional true
    path("${sample_id}.contaminants.txt"), emit: contaminants optional true
    
    script:
    """
    # Extract the unaligned reads keep only 12=unmapped, but not 256=not-primary-alignment
    samtools fastq -f 12 -F 256  -1 ${sample_id}_1.fq -2 ${sample_id}_2.fq contaminants.bam
    # Gather statistics on mapped reads
    samtools stats contaminants.bam | grep ^SN | cut -f 2- |  grep "reads mapped:" > ${sample_id}.contaminants.txt
    # compress decontaminated reads
    pigz -p ${task.cpus} ${sample_id}_{1,2}.fq
    """
}


process REMOVE_CONTAMINANTS {
    tag "$sample_id"
    label "process_mapping"

    publishDir "$params.outdir/contam-reads/", 
        pattern: "contaminants",
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads)
    path db

    output:
    tuple val(sample_id), path("cleaned/${sample_id}_R{1,2}.fastq.gz"), emit: reads optional true
    path("${sample_id}.contaminants.txt"), emit: stats optional true
    tuple val(sample_id), path("contaminants/${sample_id}_R{1,2}.fastq.gz"), emit: contaminantreads optional true
    
    script:
    """
    mkdir -p cleaned
    mkdir -p contaminants
    bbduk.sh in1=${reads[0]} in2=${reads[1]} \
       out1=cleaned/${sample_id}_R1.fastq.gz out2=cleaned/${sample_id}_R2.fastq.gz \
       outm1=contaminants/${sample_id}_R1.fastq.gz outm2=contaminants/${sample_id}_R2.fastq.gz
       k=31 hdist=1 stats=${sample_id}.contaminants.txt threads=${task.cpus}

    # Remove gzipped file if no lines
    LINES=\$(cat cleaned/${sample_id}_R1.fastq.gz | wc -l)
    echo "# LINES: \$LINES"
    if [[ \$LINES -eq 0 ]]; then
        echo "# Removing empty files from cleaned/"
        rm cleaned/${sample_id}_*.fastq.gz
    fi
    """
}

process FASTP {
    /* 
       fastp process to remove adapters and low quality sequences
    */
    
    tag "$sample_id"
    label 'process_filtering'

    publishDir "$params.outdir/", 
        pattern: "reads/*gz",
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads) 
    val(minlen)
    val(minqual)
    
    output:
    tuple val(sample_id), path("reads/${sample_id}_R{1,2}.fastq.gz"), emit: reads
    path("${sample_id}-report.html"), emit: html
    path("${sample_id}.fastp.json"), emit: json

    /*
       "sed" is a hack to remove _R1 from sample names for MultiQC (clean way via config "extra_fn_clean_trim:\n    - '_R1'")
    */
    script:
    """
    mkdir -p reads
    if [[ ${minqual} -gt 0 ]]; then
        quality_param="--qualified_quality_phred ${minqual}"
    else
        quality_param="--disable_quality_filtering"
    fi
    fastp -w ${task.cpus} -i ${reads[0]} -I ${reads[1]} \
        -o reads/${sample_id}_R1.fastq.gz -O reads/${sample_id}_R2.fastq.gz \
        -h ${sample_id}-report.html -j mqc.json \
        --detect_adapter_for_pe \$quality_param   \
        --length_required ${minlen}  
    
    sed 's/-nohost_R1//g' mqc.json |sed 's/_R1//g' | sed 's/fastq.gz//g' | sed 's/fq.gz//g' > ${sample_id}.fastp.json
    """
}
process ILLUMINA_INDEX {
    
    tag "$sample_id"
    label 'process_filtering'

    input:
    tuple val(sample_id), path(reads) 
    
    output:
    path("${sample_id}.index.tsv") optional true

 
    script:
    """
    fu-index --max-reads 20000 --min-ratio 0.8 ${reads[0]} ${reads[1]} > ${sample_id}.index.tsv
    """
}

process ILLUMINA_TABLE {
    
    label 'process_filtering'

    input:
    path("*.tsv")    
    output:
    path("index_mqc.txt") optional true

 
    script:
    """
    indexTable.py *.tsv -o index_mqc.txt
    """
}


process MULTIQC {
    label 'process_low'
    publishDir "$params.outdir/", 
        mode: 'copy'
        
    input:
    path '*'  
    path 'assets'
    val (project)
    
    output:
    path 'multiqc_*' optional true
     
    script:
    """
    # Old MultiQC will crash with Kraken2 reports 100% unclassified
    #fixKrakenReports.py *.kraken2.tsv
    echo "custom_logo: \"\$PWD/assets/cleanup-128.png\"" >> logo.yaml
    multiqc -c assets/multiqc.yaml -c logo.yaml --comment "Project ${project}" --force . 
    """
} 

process TRACKFILES {
    label 'process_low'
    input:
    path '*'

    output:
    path 'summary_mqc.txt'

    script:
    """
    multiqctable.py -j *json
    """
} 

process HOSTQC {
    label 'process_low'
    publishDir "$params.outdir/", 
        mode: 'copy'
        
    input:
    path '*'  
    
    output:
    path 'host-qc'
     
    script:
    """
    mkdir -p host-qc
    multiqc -f -o host-qc .
    """
} 