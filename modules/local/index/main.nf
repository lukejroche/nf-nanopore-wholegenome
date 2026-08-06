process SORT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'conda "${moduleDir}/environment.yml"
    container 'mgibio/samtools:v1.21-noble'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path("${bam}.bai"), emit: bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    samtools index -@ ${task.cpus} ${bam}

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
