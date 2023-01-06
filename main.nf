/*  Input parameters   */
nextflow.enable.dsl = 2

def version = "1.5"
params.dbdir = false
params.reads = "$baseDir/nano/*_R{1,2}.fastq.gz"
params.mqc_conf = "$baseDir/modules/assets/"
params.outdir = "cleanup-output"

// relabeling options
params.separator = "-"    // separator between sample name and progressive number (read number)
params.tag1      = ""     // appended at the end of the name of reads R1
params.tag2      = ""     // appended at the end of the name of reads R2

// Filtering options
params.minlen = 50
params.minreads = 1000
params.minqual = 0

// Databases
params.hostdb = false
params.krakendb = false

// Extra features
params.saveraw = false
params.savehost = false

// Experimental
params.contaminants = false
params.denovo = false

def dbdir = params.dbdir == false ? file("$baseDir/databases/") : file(params.dbdir)

// Splash message labels
def labelSaveReads = params.saveraw ? "Save_Raw_Reads" : ""
def labelSaveHost = params.savehost ? "Save_Host_Reads" : ""
def labelContaminants = params.contaminants ? "Remove_Contaminants" : ""
def labelDeNovo = params.denovo ? "Do_DeNovo" : ""
def labelNone = params.saveraw || params.savehost || params.contaminants || params.denovo ? "" : "None"

// prints to the screen and to the log
log.info """
         GMH Cleanup pipeline (version ${version})
         ===================================
         """
         .stripIndent()

if (params.dbdir == false) {
  log.info """
            reads        : ${params.reads}
            outdir       : ${params.outdir}
            min reads    : ${params.minreads}
            host db      : ${params.hostdb}
            kraken db    : ${params.krakendb}
            -----------------------------------
            Extras       : ${labelNone} ${labelSaveReads} ${labelSaveHost} ${labelDeNovo} ${labelContaminants}
            Relabeling   : separator="${params.separator}" tag1="${params.tag1}" tag2="${params.tag2}"
            """
            .stripIndent()
} else {
  log.info """Downloading databases to: ${dbdir}
  """.stripIndent()
}



/*    Modules  */
include { VERSIONS } from './modules/versions'
include { KRAKEN2_HOST; KRAKEN2_REPORT; BRACKEN } from './modules/kraken'
include { FASTP; MULTIQC; TRACKFILES; GETLEN; INDEX; 
          REMOVE_CONTAMINANTS; REMOVE_MAPPED; MAP_CONTAMINANTS; 
          MINREADS; MINREADS as MINREADS_FINALCHECK; HOSTQC; RELABEL;
          ILLUMINA_INDEX; ILLUMINA_TABLE} from './modules/cleaner'
include { PIGZ_READS; PIGZ_HOST }        from './modules/pigz'
include { DENOVO; PRODIGAL  } from './modules/denovo'
include { CHECK_REPORT;  }      from './modules/hg'
include { GETHOSTDB; GETKRAKENDB; GETCHECKDB }      from './modules/db' 

workflow getdb {
  /* Download standard databases */
  GETCHECKDB(dbdir)
  GETHOSTDB(dbdir)
  GETKRAKENDB(dbdir)
}
reads = Channel
        .fromFilePairs(params.reads, checkIfExists: true)

workflow {
  VERSIONS(version)
  /* Check mandatory arguments */
  if (params.hostdb == false) { log.error("Host database not specified (--hostdb)"); exit(1) }
  if (params.krakendb == false) { log.error("Host database not specified (--krakendb)"); exit(1) }
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
  
  // Discard samples not passing the min reads filter
  MINREADS(reads, params.minreads)
  
  // Extract illumina indexes
  ILLUMINA_INDEX(MINREADS.out.reads)
  ILLUMINA_TABLE(ILLUMINA_INDEX.out.collect())

  // Host removal (Human reads)
  KRAKEN2_HOST( MINREADS.out.reads, hostPath)
  CHECK_REPORT(KRAKEN2_HOST.out.report)
  PIGZ_READS(KRAKEN2_HOST.out.reads)
  PIGZ_HOST(KRAKEN2_HOST.out.host)
  HOSTQC(KRAKEN2_HOST.out.report.map{ it -> it[1] }.collect())
  // Kraken2 Host report (if using custom human db)
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
  RELABEL(MINREADS_FINALCHECK.out.reads, params.separator, params.tag1, params.tag2 )
  FASTP(RELABEL.out, params.minlen, params.minqual )

  
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
  TRACKFILES(FASTP.out.json.mix( KRAKEN2_HOST.out.txt, CONTAMLOG, CHECK_REPORT.out ).collect() )
  MULTIQC( FASTP.out.json.mix( KRAKEN2_REPORT.out, TRACKFILES.out, ILLUMINA_TABLE.out, VERSIONS.out ).collect(), params.mqc_conf )
}