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
process MINREADS {
    tag "filter $sample_id"
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
    if [[ \$TOT -eq ${min} ]]; then
        echo "PASS"
        mv ${reads[0]} pass/${sample_id}_R1.fastq.gz
        mv ${reads[1]} pass/${sample_id}_R2.fastq.gz
    fi
    file ${reads[0]}
    
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
process CONTAMINANTS {
    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads)
    path db

    output:
    tuple val(sample_id), path("${sample_id}_{1,2}.fq.gz"), emit: reads
    path("${sample_id}.contaminants.txt"), emit: contaminants
    
    script:
    """
    # Align reads against the contaminants db
    bwa mem -t ${task.cpus} contaminants-ref/contaminants.fasta "${reads[0]}" "${reads[1]}" | samtools view -bS > contaminants.bam
    # Extract the unaligned reads
    samtools fastq -f 12 -F 256  -1 ${sample_id}_1.fq -2 ${sample_id}_2.fq contaminants.bam
    # Gather statistics on mapped reads
    samtools stats contaminants.bam | grep ^SN | cut -f 2- |  grep "reads mapped:" > ${sample_id}.contaminants.txt
    # compress decontaminated reads
    pigz -p ${task.cpus} ${sample_id}_{1,2}.fq
    """
}
process FASTP {
    /* 
       fastp process to remove adapters and low quality sequences
    */
    
    tag "$sample_id"
    label 'process_filtering'

    publishDir "$params.outdir/reads/", 
        pattern: "*gz",
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads) 
    val(minlen)
    val(minqual)
    
    output:
    tuple val(sample_id), path("${sample_id}_R{1,2}.fastq.gz"), emit: reads
    path("${sample_id}-report.html"), emit: html
    path("${sample_id}.fastp.json"), emit: json

    /*
       "sed" is a hack to remove _R1 from sample names for MultiQC (clean way via config "extra_fn_clean_trim:\n    - '_R1'")
    */
    
    script:
    """
    if [[ ${minqual} -gt 0 ]]; then
        quality_param="--qualified_quality_phred ${minqual}"
    else
        quality_param="--disable_quality_filtering"
    fi
    fastp -w ${task.cpus} -i ${reads[0]} -I ${reads[1]} \
        -o ${sample_id}_R1.fastq.gz -O ${sample_id}_R2.fastq.gz \
        -h ${sample_id}-report.html -j ${sample_id}.fastp.json \
        --detect_adapter_for_pe \$quality_param   \
        --length_required ${minlen}  
    
    sed -i.bak 's/-nohost_1//g' *.json 
    sed -i.bak 's/_1.fq.gz//g' *.json
    """
}

process MULTIQC {
    label 'process_low'
    publishDir "$params.outdir/", 
        mode: 'copy'
        
    input:
    path '*'  
    
    output:
    path 'multiqc_*'
     
    script:
    """
    multiqc . 
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
