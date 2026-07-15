process STR {

    container "straglr:1.5.6"
    label "${params.machine}"
    publishDir "${params.outdir}/STR_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    path "${sample_id}_str*"

    script:
    """
    straglr.py \
        ${bam} \
        ${ref} \
        ${sample_id}_str \
        --nprocs ${task.cpus}
    """
}
