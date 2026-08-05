process MODKIT {

    container "ontresearch/modkit:sha077c7ca8d7bf1cc9e3a4f3400d6e882c495156e4"
    label "process_medium"
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
