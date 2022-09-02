/*
 Human genome specific check
*/

process CHECK_REPORT {
 
    tag "$sample_id"
    label 'process_low'
 
    input:
    tuple val(sample_id), path(report) 
   
    
    output:
    path("${sample_id}.ratio.txt") 
 
    script:
    """
    check-report.py ${report} > ${sample_id}.ratio.txt
    """  
}  