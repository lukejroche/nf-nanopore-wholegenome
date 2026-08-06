process SORT {
    tag "$meta.id"
    label 'process_single'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container 'conda "${moduleDir}/environment.yml"
    container 'mgibio/samtools:v1.21-noble'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${sample_id}.sorted.bam"), emit: bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    samtools sort -@ ${task.cpus} -m 1G -T ${sample_id}.tmp -o ${sample_id}_sorted.bam ${bam}
    rm -f ${meta.ia}.tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    """
}
