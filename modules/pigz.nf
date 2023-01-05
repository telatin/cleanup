process PIGZ_READS {
 
    tag "$sample_id"
    label 'process_medium'

    publishDir "$params.outdir/raw-reads/", 
        pattern: "*gz",
        mode: 'copy',
        enabled: params.saveraw

    input:
    tuple val(sample_id), path(reads) 
   
    
    output:
    tuple val(sample_id), path("${sample_id}*.gz"), emit: reads

    /*
       gz.py --verbose --force *.fq
    */
    script:
    """
    cat ${reads[0]} | pigz -c --verbose  -p ${task.cpus} > ${reads[0]}.gz   
    cat ${reads[1]} | pigz -c --verbose  -p ${task.cpus} > ${reads[1]}.gz   
    """  
}  

process PIGZ_HOST {
 
    tag "$sample_id"
    label 'process_medium'

    publishDir "$params.outdir/host-reads/", 
        pattern: "*gz",
        mode: 'copy',
        enabled: params.savehost

    input:
    tuple val(sample_id), path(reads) 
   
    
    output:
    tuple val(sample_id), path("${sample_id}_hostreads_R{1,2}.fastq.gz"), emit: reads

    /*
       gz.py --verbose --force *.fq
    */
    script:
    """
    echo COMPRESS R1: ${reads[0]}
    cat ${reads[0]} | pigz -c --verbose  -p ${task.cpus} > ${sample_id}_tmphostreads_R1.fastq.gz   
    echo COMPRESS R2: ${reads[1]}
    cat ${reads[1]} | pigz -c --verbose  -p ${task.cpus} > ${sample_id}_tmphostreads_R2.fastq.gz   
    echo MOVE/RENAME
    mv ${sample_id}_tmphostreads_R1.fastq.gz ${sample_id}_hostreads_R1.fastq.gz
    mv ${sample_id}_tmphostreads_R2.fastq.gz ${sample_id}_hostreads_R2.fastq.gz
    echo ---
    ls -lh *gz
    """  
}  

