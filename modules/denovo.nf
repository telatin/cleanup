process DENOVO {
    tag "$sample_id"
    label 'process_high'
    publishDir "$params.outdir/denovo/", 
        mode: 'copy'
    
    input:
    tuple val(sample_id), path(reads) 
    
    output:
    tuple val(sample_id), path("${sample_id}_contigs.fasta") optional true

    script:
    """
    megahit -t ${task.cpus} -1 ${reads[0]} -2 ${reads[1]} -o denovo
    if [[ -s denovo/final.contigs.fa ]]; then
        mv denovo/final.contigs.fa ${sample_id}_contigs.fasta
    fi
    """ 
} 

process PRODIGAL {
    tag "$sample_id"
    label 'process_medium'
    publishDir "$params.outdir/denovo/", 
        mode: 'copy'
    
    input:
    tuple val(sample_id), path(contigs) 
    
    output:
    tuple val(sample_id), path("${sample_id}.faa"), emit: faa
    tuple val(sample_id), path("${sample_id}.gff"), emit: gff
    
    script:
    """
    prodigal -i ${contigs} -a ${sample_id}.faa -o ${sample_id}.gff -f gff -p meta
    """ 
}