process PIGZ_READS {
 
    tag "$sample_id"
    label 'process_medium'

    publishDir "$params.outdir/raw-reads/", 
        pattern: "*human*gz",
        mode: 'copy'

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