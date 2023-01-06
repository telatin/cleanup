process VERSIONS {
    input:
    val(version)

    output:
    file 'versions_mqc.txt' 

    script:
    """
    #!/bin/bash
    echo -e "# plot_type: 'table'"  >> versions_mqc.txt
    echo -e "# section_name: 'Software and Databases'"  >> versions_mqc.txt
    echo -e "# description: 'Version of the programs used in the pipeline'"  >> versions_mqc.txt
    echo -e "Program\tVersion"  >> versions_mqc.txt
    echo -e "cleanup/pipeline\t${version}"  >> versions_mqc.txt
    echo -e "fastp\t\$(fastp --version |& cut -f 2 -d ' ')"  >> versions_mqc.txt
    echo -e "seqfu\t\$(seqfu version)"  >> versions_mqc.txt
    echo -e "kraken2\t\$(kraken2 --version | grep version | rev | cut -f 1 -d ' ' | rev)"  >> versions_mqc.txt
    echo -e "pigz\t\$(pigz --version | cut -f 2 -d ' ')"  >> versions_mqc.txt
    echo -e "Host database\t"  >> versions_mqc.txt
    echo -e "Profiling database\t"  >> versions_mqc.txt
    

    """
}