process FASTP {
    /* 
       fastp process to remove adapters and low quality sequences
    */
    
    tag "$sample_id"
    label 'process_medium'

    publishDir "$params.outdir/reads/", 
        pattern: "*gz",
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads) 
    val(minlen)
    
    output:
    tuple val(sample_id), path("${sample_id}_R{1,2}.fastq.gz"), emit: reads
    path("${sample_id}-report.html"), emit: html
    path("${sample_id}.fastp.json"), emit: json

    /*
       "sed" is a hack to remove _R1 from sample names for MultiQC
        (clean way via config "extra_fn_clean_trim:\n    - '_R1'")
    */
    script:
    """
    fastp -w ${task.cpus} -i ${reads[0]} -I ${reads[0]} \
        -o ${sample_id}_R1.fastq.gz -O ${sample_id}_R2.fastq.gz \
        -h ${sample_id}-report.html -j ${sample_id}.fastp.json \
        --detect_adapter_for_pe --disable_quality_filtering  \
        -l ${minlen}  
    
    sed -i.bak 's/-nohost_1//g' *.json 
    """
    //sed -i 's/-nohost_.//g' "$OUTDIR"/${BASENAME}.fastp.json
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