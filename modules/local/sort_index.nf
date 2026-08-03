process SORT_INDEX {
    label "process_medium"
    publishDir "${params.outdir}/sorted_bams", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id),
          path("${sample_id}_sorted.bam"),
          path("${sample_id}_sorted.bam.bai")

    script:
    """
    samtools sort -@ ${task.cpus} -m 1G -T ${sample_id}.tmp -o ${sample_id}_sorted.bam ${bam}
    samtools index -@ ${task.cpus} ${sample_id}_sorted.bam

    rm -f ${sample_id}.tmp
    """
}
