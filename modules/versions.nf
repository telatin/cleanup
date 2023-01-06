process VERSIONS {
    input:
    val(version)
    val(host)
    val(profiling)

    output:
    file 'versions_mqc.txt' 

    script:
    """
    #!/bin/bash
    echo -e "# plot_type: 'table'"  >> versions_mqc.txt
    echo -e "# section_name: 'Software and Databases'"  >> versions_mqc.txt
    echo -e "# description: 'Version of the programs used in the pipeline'"  >> versions_mqc.txt
    echo -e "Program\tVersion"  >> versions_mqc.txt
    echo -e "cleanup/pipeline\tv${version}"  >> versions_mqc.txt
    echo -e "fastp\tv\$(fastp --version |& cut -f 2 -d ' ')"  >> versions_mqc.txt
    echo -e "seqfu\tv\$(seqfu version)"  >> versions_mqc.txt
    echo -e "kraken2\tv\$(kraken2 --version | grep version | rev | cut -f 1 -d ' ' | rev)"  >> versions_mqc.txt
    echo -e "pigz\tv\$(pigz --version | cut -f 2 -d ' ')"  >> versions_mqc.txt
    echo -e "Host database\t${host}"  >> versions_mqc.txt
    echo -e "Profiling database\t${profiling}"  >> versions_mqc.txt
    

    """
}