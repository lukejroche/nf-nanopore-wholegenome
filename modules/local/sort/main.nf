process SORT {
    tag "$meta.id"
    label 'process_single'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container 'mgibio/samtools:v1.21-noble'

    input:
    tuple val(meta), path(bam), path(reference)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), path(reference), emit: bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    samtools sort -@ ${task.cpus} -m 1G -T ${meta.id}.tmp -o ${meta.id}_sorted.bam ${bam}
    rm -f ${meta.id}.tmp

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
