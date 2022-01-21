/* 
 
*/

/* 
 *   Input parameters 
 */
nextflow.enable.dsl = 2
params.reads = "$baseDir/nano/*_R{1,2}.fastq.gz"
params.minlen = 50
params.minreads = 1000
params.outdir = "$baseDir/cleanup"
params.hostdb = "$baseDir/DB/kraken2_human/"
params.krakendb = "$baseDir/DB/std/"
params.krakendb = false
params.contaminants = false
        
// prints to the screen and to the log
log.info """
         GMH Cleanup pipeline (version 1.1)
         ===================================
         input reads  : ${params.reads}
         outdir       : ${params.outdir}
         min reads    : ${params.minreads}
         host db      : ${params.hostdb}
         kraken db    : ${params.krakendb}
         contaminants : ${params.contaminants}
         """
         .stripIndent()

/* 
   check reference path exists 
*/

def hostPath = file(params.hostdb, checkIfExists: true)
file("${params.hostdb}/hash.k2d", checkIfExists: true)

def reportPath = file(params.krakendb, checkIfExists: true)
file("${params.krakendb}/hash.k2d", checkIfExists: true)

def contaminantsPath = false
if (params.contaminants) {
  contaminantsPath = file(params.contaminants, checkIfExists: true)
}

/*
  Modules
*/

include { KRAKEN2_HOST; KRAKEN2_REPORT } from './modules/kraken'
include { FASTP; MULTIQC; TRACKFILES; MINREADS; INDEX; CONTAMINANTS  } from './modules/cleaner'
/* 
 *   DSL2 allows to reuse channels
 */
reads = Channel
        .fromFilePairs(params.reads, checkIfExists: true)


 
workflow {
  MINREADS(reads, params.minreads)
  KRAKEN2_HOST( MINREADS.out.reads, hostPath)
  if (params.contaminants == false) {
    TOFILTER = KRAKEN2_HOST.out
    CONTAMLOG = Channel.empty()
  } else {
    INDEX(contaminantsPath)
    TOFILTER = CONTAMINANTS( KRAKEN2_HOST.out.reads, INDEX.out )
    CONTAMLOG = TOFILTER.contaminants
  }
  
  FASTP(TOFILTER.reads , params.minlen )
  KRAKEN2_REPORT( FASTP.out.reads, reportPath )    
  TRACKFILES(FASTP.out.json.mix( KRAKEN2_HOST.out.txt, CONTAMLOG ).collect() )
  MULTIQC( FASTP.out.json.mix( KRAKEN2_REPORT.out, TRACKFILES.out ).collect() )
}