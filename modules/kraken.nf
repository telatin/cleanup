process KRAKEN2_HOST {
 
    tag "$sample_id"
    label 'process_medium'

    publishDir "$params.outdir/host-reads/", 
        pattern: "*human*gz",
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads) 
    path db
    
    output:
    tuple val(sample_id), path("${sample_id}-nohost_*.fq"), emit: reads optional true
    tuple val(sample_id), path("${sample_id}-human_*.fq.gz"), emit: host optional true
    path("${sample_id}.host.log"), emit: log
    path("${sample_id}.host.txt"), emit: txt
    path("${sample_id}.host.report"), emit: report

    /*
       gz.py --verbose --force *.fq
    */
    script:
    """
    kraken2 --db $db --threads ${task.cpus} \\
      --confidence 0.1 \\
      --unclassified-out ${sample_id}-nohost#.fq \\
      --classified-out ${sample_id}-human#.fq \\
      --report ${sample_id}.host.report \\
      --memory-mapping --paired ${reads[0]} ${reads[1]} 2> ${sample_id}.host.log | \\
      countClass.py -c "Human" -u "Non-human" -o ${sample_id}.host.txt
    
    echo "+ RENAME"
    for i in *_1.fq;
    do
      mv \$i \${i/_1./_R1.}
    done

    for i in *_2.fq;
    do
      mv \$i \${i/_2./_R2.}
    done
    
    echo "+ REMOVE EMTPY FILES"
    rmIfEmpty.py -s fq -d . --verbose

    echo "+ COMPRESS HOST READS"
    gz.py --verbose --force *human*.fq
    """  
}  
 
process KRAKEN2_REPORT {
 
    tag "$sample_id"
    label 'process_medium'
    publishDir "$params.outdir/kraken/", 
        mode: 'copy'

    input:
    tuple val(sample_id), path(reads) 
    path(db)
    
    output:
    path("${sample_id}.kraken2.tsv")

 
    script:
    """
    kraken2 --db $db --threads ${task.cpus} \\
      --report ${sample_id}.kraken2.tsv \\
      --memory-mapping  --paired ${reads[0]} ${reads[1]} > /dev/null
    """  
} 

process COMBINE_KRAKEN {
    tag "$sample_id"
    label 'process_low'
    publishDir "$params.outdir/tables/", 
        mode: 'copy'
    
    input:
    tuple val(sample_id), path("*") 

    
    output:
    path("kraken-report.tsv")
     
    script:
    """
    combine_kreports.py --reports *.kraken2.tsv -o kraken-report.tsv
    """  
}
process COMBINE_BRACKEN {
    tag "$sample_id"
    label 'process_low'
    publishDir "$params.outdir/tables/", 
        mode: 'copy'
    
    input:
    tuple val(sample_id), path("*") 

    
    output:
    path("kraken-report.tsv")
     
    script:
    """
    combine_bracken_outputs.py --files *.bracken.* -o bracken-report.tsv
    """  
}

process BRACKEN {
    /* 
      Attempt a Bracken recalibration of the reads
    */
    tag "$report"
    label 'process_medium'
    publishDir "$params.outdir/bracken/", 
        mode: 'copy'

    input:
    path(report) 
    path("len.txt")
    path(db)
    
    output:
    path("*bracken*") optional true

 
    script:
    """
    LEN=\$(cat len.txt)
    INPUT=$report

    # Check DB file exists
    if [[ ! -e "${db}/*\${LEN}mers.kraken" ]]; then
        echo "Bracken DB file not found"
    fi


    bracken -d ${db} -i ${report} -o \${INPUT/kraken2.tsv/bracken.txt} -w \${INPUT/kraken2/bracken} -r \$LEN -l S -t 10 || echo "Bracken failed" > log.txt
    """      
}
process KRAKEN2 {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? 'bioconda::kraken2=2.1.2 conda-forge::pigz=2.6' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0' :
        'quay.io/biocontainers/mulled-v2-5799ab18b5fc681e75923b2450abaa969907ec98:87fc08d11968d081f3e8a37131c1f1f6715b6542-0' }"

    input:
    tuple val(meta), path(reads)
    path  db

    output:
    tuple val(meta), path('*classified*')  , emit: classified
    tuple val(meta), path('*unclassified*'), emit: unclassified
    tuple val(meta), path('*report.txt')   , emit: txt
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def paired       = meta.single_end ? "" : "--paired"
    def classified   = meta.single_end ? "${prefix}.classified.fastq"   : "${prefix}.classified#.fastq"
    def unclassified = meta.single_end ? "${prefix}.unclassified.fastq" : "${prefix}.unclassified#.fastq"
    """
    kraken2 \\
        --db $db \\
        --threads $task.cpus \\
        --unclassified-out $unclassified \\
        --classified-out $classified \\
        --report ${prefix}.kraken2.report.txt \\
        --gzip-compressed \\
        $paired \\
        $args \\
        $reads
    pigz -p $task.cpus *.fastq
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/^.*Kraken version //; s/ .*\$//')
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}