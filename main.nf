/*  Input parameters   */
nextflow.enable.dsl = 2
params.reads = "$baseDir/nano/*_R{1,2}.fastq.gz"
params.outdir = "$baseDir/cleanup"
params.minlen = 50
params.minreads = 1000
params.minqual = 0
params.hostdb = false
params.krakendb = false
params.krakendb = false
params.contaminants = false
params.denovo = false
        
// prints to the screen and to the log
log.info """
         GMH Cleanup pipeline (version 1.6)
         ===================================
         input reads  : ${params.reads}
         outdir       : ${params.outdir}
         min reads    : ${params.minreads}
         host db      : ${params.hostdb}
         kraken db    : ${params.krakendb}
         contaminants : ${params.contaminants}
         denovo       : ${params.denovo}
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

/*    Modules  */
include { KRAKEN2_HOST; KRAKEN2_REPORT; BRACKEN } from './modules/kraken'
include { FASTP; MULTIQC; TRACKFILES; GETLEN; INDEX; 
          REMOVE_CONTAMINANTS; REMOVE_MAPPED; MAP_CONTAMINANTS; 
          MINREADS; MINREADS as MINREADS_FINALCHECK } from './modules/cleaner'
include { PIGZ_READS } from './modules/pigz'
include { DENOVO; PRODIGAL  } from './modules/denovo'

reads = Channel
        .fromFilePairs(params.reads, checkIfExists: true)


workflow {
  // Discard samples not passing the min reads filter
  MINREADS(reads, params.minreads)

  // Host removal (Human reads)
  KRAKEN2_HOST( MINREADS.out.reads, hostPath)
  PIGZ_READS(KRAKEN2_HOST.out.reads)
  // If a FASTA contaminats is passed, filter the reads against it with BWA
  if (params.contaminants == false) {
    TOFILTER = PIGZ_READS.out
    CONTAMLOG = Channel.empty()
  } else {
    TOFILTER = REMOVE_CONTAMINANTS(PIGZ_READS, contaminantsPath )
    CONTAMLOG = TOFILTER.stats
  }
  
  // Remove adapters
  MINREADS_FINALCHECK(TOFILTER.reads, params.minreads)
  FASTP(MINREADS_FINALCHECK.out.reads , params.minlen, params.minqual )

  
  // Kraken2 profiling
  KRAKEN2_REPORT( FASTP.out.reads, reportPath )   
  // Guess length for Bracken
  GETLEN( TOFILTER.reads.map{it -> it[1]}.collect() )
  BRACKEN( KRAKEN2_REPORT.out, GETLEN.out, reportPath) 

  // Optional minimal denovo profiling
  if (params.denovo == false) {
    CONTIGS = Channel.empty()
  } else {
    CONTIGS = DENOVO( FASTP.out.reads )
    PRODIGAL( CONTIGS )
  }
  // MultiQC
  TRACKFILES(FASTP.out.json.mix( KRAKEN2_HOST.out.txt, CONTAMLOG ).collect() )
  MULTIQC( FASTP.out.json.mix( KRAKEN2_REPORT.out, TRACKFILES.out ).collect() )
}