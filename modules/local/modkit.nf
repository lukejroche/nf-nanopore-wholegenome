process MODKIT {

    container "ontresearch/modkit:latest"
    label "${params.machine}"
    publishDir "${params.outdir}/methylation", mode: 'copy',
        saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    path "${sample_id}.bed"

    script:
    """
    modkit pileup \
        ${bam} \
        ${sample_id}.bed \
        --ref ${ref} \
        --threads ${task.cpus}
    """
}
