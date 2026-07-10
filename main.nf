#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
 * ============================================================================
 * Pipeline Parameters
 * ============================================================================
 */

// Input files
params.pod5       = null
params.fastq      = null
params.bam        = null
params.reference  = null

// Analyses to perform (comma-separated)
params.analysis   = ''
params.skip_sort = false

// General
params.outdir     = "results"
params.threads    = 8


/*
 * ============================================================================
 * Parse analysis list
 * ============================================================================
 */

/*def analysis = params.analysis
 *                   .split(',')
 *                   .trim()
 *                   .toLowerCase()
*/

boolean runAnalysis(String name) {
    params.analysis.contains(name)
}



/*
 * ============================================================================
 * Main Workflow
 * ============================================================================
 */

workflow {

    /*
     * Determine pipeline entry point
     */

    
    bam_ch = Channel
    .fromPath(params.bam)
    .map { bam ->
        def sample_id = bam.baseName.split('_')[0]
        tuple(sample_id, bam)
    }

if (params.skip_sort) {

    sorted_bam = bam_ch.map { sample_id, bam ->
        tuple(sample_id, bam, file("${bam}.bai"))
    }

} else {

    sorted_bam = SORT_INDEX(bam_ch)
}
    




/*    if (params.bam) {
*
*        println "Starting from aligned BAM"
*
*        bam_ch = Channel.fromPath(params.bam)
*
*    }
*    else if (params.fastq) {
*
*        println "Starting from FASTQ"
*
*        bam_ch = ALIGN(params.fastq)
*
*    }
*    else {
*
*        error """
*        No valid input supplied.
*
*        Please provide one of:
*
*            --bam
*            --fastq
*            --pod5
*        """
*
*    }
*/

    /*
     * Downstream analyses
     */
    if (runAnalysis('qc'))
        QC(sorted_bam)

    if (runAnalysis('snv'))
        SNV(sorted_bam, params.reference)

    if (runAnalysis('sv'))
        SV(sorted_bam, params.reference)

    if (runAnalysis('str'))
        STR(sorted_bam, params.reference)

    if (runAnalysis('cnv'))
        CNV(sorted_bam, params.reference)
    if (runAnalysis('mosdepth'))
        mosdepth(sorted_bam)


/*
* 
*       
*
*
*    if (runAnalysis('meth')
*        METHYLATION(bam_ch)
*
*    if (runAnalysis('benchmark'))
*        BENCHMARK()
*
*    if (runAnalysis('annotate'))
*        ANNOTATE()
*/
}

/*
=====================================================
  ALIGNMENT (minimap2)
=====================================================
*/

process ALIGN {

    input:
    path reads
    path ref

    output:
    path "aligned.bam"

    script:
    """
    minimap2 -ax map-ont $ref $reads \
        | samtools sort -o aligned.bam

    samtools index aligned.bam
    """
}

process SORT_INDEX {


    cpus 2
    memory '3 GB'
    
    publishDir "${params.outdir}/sorted_bams", mode: 'copy'
    
    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id),
    path("${sample_id}_sorted.bam"),
    path("${sample_id}_sorted.bam.bai")

    script:
    """
    samtools sort -@ ${task.cpus} -m 1G -T ${sample_id}.tmp -o ${sample_id}_sorted.bam $bam
    samtools index -@ ${task.cpus} ${sample_id}_sorted.bam
   
    rm -f ${sample_id}.tmp
     """

}



/*
=====================================================
  QC (post-alignment) (fastqc, multiqc, mosdepth, seqkit)
=====================================================
*/

process QC {

    input:
    path bam

    output:
    path "qc.txt"

    script:
    """ 
    echo 'running flagstat'
    samtools flagstat $bam > qc.txt
    echo 'running stats'
    samtools stats $bam >> qc.txt
    """
}


/*
=====================================================
  SNV CALLING (clair3)
=====================================================
*/

process SNV {
    
    container "hkubal/clair3:latest"
    cpus 4

    publishDir "${params.outdir}/SNV_calls", mode: 'copy'

    input:
    tuple val(sample_id),path(bam),path(bai)
    path ref

    output:
    tuple val(sample_id),
    path("${sample_id}_snv.vcf.gz"),
    path("${sample_id}_snv.vcf.gz.tbi")

    script:
    """
    /opt/bin/run_clair3.sh \
    -b $bam \
    -f $ref \
    -m /opt/models/r1041_e82_400bps_hac_v600 \
    --threads ${task.cpus} \
    --platform ont \
    --output snv_out

    mv snv_out/merge_output.vcf.gz ${sample_id}_snv.vcf.gz
    mv snv_out/merge_output.vcf.gz.tbi ${sample_id}_snv.vcf.gz.tbi
    """
}


/*
=====================================================
  SV CALLING (sniffles2)
=====================================================
*/

process SV {


    container "quay.io/biocontainers/sniffles:2.6.3--pyhdfd78af_0"
    cpus 4

    publishDir "${params.outdir}/SV_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path(ref)

    output:
    path "${sample_id}_sv.vcf"

    script:
    """
    sniffles \
        --input $bam \
        --vcf ${sample_id}_sv.vcf \
        --threads ${task.cpus} \
        --reference $ref
        --snf ${sample_id}_sv.snf
    """
}


process STR {

    container 'straglr:1.5.6'
    cpus 4

    publishDir "${params.outdir}/STR_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai) 
    path(ref)

    output:
    path "${sample_id}_str*"

    script:
    """
    straglr.py \
        $bam \
        $ref \
        ${sample_id}_str \
        --nprocs ${task.cpus}
    """
}

process mosdepth {

    container "spectre:0.2.1"
    cpus 4

    publishDir "${params.outdir}/mosdepth", mode: 'copy',
    saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(bam), path(bai)
    
    output:
    path("${sample_id}.regions.bed.gz")
    path("${sample_id}.regions.bed.gz.csi")
    path("${sample_id}.mosdepth.summary.txt")

    

    script:
    """
    mosdepth -t ${task.cpus} -x -b 1000 -Q 20 ${sample_id} ${bam}
    """
}

/*
=====================================================
  CNV (placeholder) (Spectre)
=====================================================
*/

process CNV {
    
    container "spectre:0.2.1"
    cpus 4

    publishDir "${params.outdir}/STR_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    path "${sample_id}_cnv.vcf"

    script:
    """
    mosdepth -t 8 -x -b 1000 -Q 20 ${params.outdir}/${sample_id} ${bam}
    
    
    
    spectre CNVCaller \
        --bam $bam \
        --output-dir ${params.outdir} \
        --output-file ${sample_id}_cnv \
        --reference $ref
        --threads ${task.cpus}
    """
}


/*
=====================================================
  METHYLATION (placeholder) (modkit)
=====================================================
*/

process METH {

    input:
    path bam

    output:
    path "methylation.txt"

    script:
    """
    modkit
    """
}

/* PHASING 


/*
=====================================================
  REPORTING (very simple aggregator)
=====================================================
*/

process REPORT {

    input:
    path qc
    path snv
    path sv
    path cnv
    path meth

    output:
    path "report.txt"

    script:
    """
    echo "MULTI-OMICS REPORT" > report.txt
    echo "==================" >> report.txt

    echo "\nQC:" >> report.txt
    cat $qc >> report.txt

    echo "\nSNVs:" >> report.txt
    cat $snv >> report.txt

    echo "\nSVs:" >> report.txt
    cat $sv >> report.txt

    echo "\nCNVs:" >> report.txt
    cat $cnv >> report.txt

    echo "\nMethylation:" >> report.txt
    cat $meth >> report.txt
    """
}
