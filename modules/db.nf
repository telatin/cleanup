
process GETHOSTDB {
 
    tag "$outdir"
    label 'process_low'
 
    publishDir "$outdir/", 
        mode: 'copy'
    
    input:
    val(outdir)

    output:
    path("cleanup-db") 
 
    script:
    """
    wget -O cleanup-db.zip "https://zenodo.org/record/7044072/files/cleanup-db.zip?download=1"
    unzip cleanup-db.zip
    """

}

process GETKRAKENDB {
 
    tag "$outdir"
    label 'process_low'
 
    publishDir "$outdir/", 
        mode: 'copy'
    
    input:
    val(outdir)

    output:
    path("kraken2-standard-8gb") 
 
    script:
    """
    echo MAKE TMP DIR
    mkdir -p kraken2-standard-8gb
    
    echo DOWNLOAD
    wget "https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20220607.tar.gz" > wget.log 2>&1
    tar xvfz k2_standard_08gb_20220607.tar.gz > tar.log 2>&1
    
    echo REMOVE k2_standard_08gb_20220607.tar.gz
    rm *.tar.gz
    mv -v *.* "kraken2-standard-8gb"
    """

}


process GETCHECKDB {
 
    tag "$outdir"
    label 'process_low'
 
    publishDir "$outdir/", 
        mode: 'copy'


    input:
    val(outdir)

    output:
    path("gutcheck-db") 
 
    script:
    """
    wget "https://zenodo.org/record/7050266/files/gutcheck-db.zip?download=1"
    unzip "gutcheck-db.zip?download=1"
    """

}