process MULTIQC {
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
    input:
    path '*'

    output:
    path 'summary_mqc.txt'

    script:
    """
    multiqctable.py -j *json
    """
}
/* 
process FASTP {
 
    tag "filter $sample_id"

    input:
    tuple val(sample_id), path(reads) 
    
    output:
    tuple val(sample_id), path("${sample_id}_filt_R*.fastq.gz"), emit: reads
    path("${sample_id}.fastp.json"), emit: json

 
    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} \\
      -o ${sample_id}_filt_R1.fastq.gz -O ${sample_id}_filt_R2.fastq.gz \\
      --detect_adapter_for_pe -w ${task.cpus} -j report.json

    
    sed 's/_R1//g' report.json > ${sample_id}.fastp.json 
    """  
}  
 */
 

