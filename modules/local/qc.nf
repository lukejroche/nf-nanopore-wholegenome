process QC {

    publishDir "${params.outdir}/QC", mode: 'copy'
    label "process_low"
    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    path "${sample_id}_qc.txt"

    script:
    """
    echo 'running flagstat'
    samtools flagstat ${bam} > ${sample_id}_qc.txt
    echo 'running stats'
    samtools stats ${bam} >> ${sample_id}_qc.txt
    """
}
