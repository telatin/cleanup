
process GETHOSTDB {
 
    tag "$outdir"
    label 'process_low'
 
    
    input:
    val(outdir)

    output:
    path("cleanup-db.zip") 
 
    script:
    """
    wget -O cleanup-db.zip "https://zenodo.org/record/7044072/files/cleanup-db.zip?download=1"
    unzip cleanup-db.zip
    mv cleanup-db ${outdir}
    """

}

process GETKRAKENDB {
 
    tag "$outdir"
    label 'process_low'
 
    
    input:
    val(outdir)

    output:
    path("k2_standard_08gb_20220607.tar.gz") 
 
    script:
    """
    wget "https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20220607.tar.gz"
    tar xfz k2_standard_08gb_20220607.tar.gz
    rm *.tar.gz
    mv *.* ${outdir}
    """

}