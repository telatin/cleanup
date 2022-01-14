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