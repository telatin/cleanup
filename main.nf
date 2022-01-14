/* 
 
*/

/* 
 *   Input parameters 
 */
nextflow.enable.dsl = 2
params.reads = "$baseDir/nano/*_R{1,2}.fastq.gz"
params.minlen = 50
params.outdir = "$baseDir/denovo"
params.hostdb = "$baseDir/DB/kraken2_human/"
params.krakendb = "$baseDir/DB/std/"
params.krakendb = false

        
// prints to the screen and to the log
log.info """
         Denovo Pipeline (version 5)
         ===================================
         input reads  : ${params.reads}
         outdir       : ${params.outdir}
         host db      : ${params.hostdb}
         kraken db    : ${params.krakendb}
         """
         .stripIndent()

/* 
   check reference path exists 
*/

def hostPath = file(params.hostdb, checkIfExists: true)
file("${params.hostdb}/hash.k2d", checkIfExists: true)

def reportPath = file(params.krakendb, checkIfExists: true)
file("${params.krakendb}/hash.k2d", checkIfExists: true)

/*
  Modules
*/

include { KRAKEN2_HOST; KRAKEN2_REPORT } from './modules/kraken'
include { FASTP; MULTIQC; TRACKFILES  } from './modules/cleaner'
/* 
 *   DSL2 allows to reuse channels
 */
reads = Channel
        .fromFilePairs(params.reads, checkIfExists: true)


 
workflow {

 
    KRAKEN2_HOST( reads, hostPath)
    FASTP( KRAKEN2_HOST.out.reads, params.minlen )
    KRAKEN2_REPORT( FASTP.out.reads, reportPath )
    
    TRACKFILES(FASTP.out.json.mix( KRAKEN2_HOST.out.txt ).collect() )
    MULTIQC( FASTP.out.json.mix( KRAKEN2_REPORT.out, TRACKFILES.out ).collect() )
 
}