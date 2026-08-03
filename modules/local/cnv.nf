process CNV {

    container "spectre:0.2.1"
    label "process_medium"
    publishDir "${params.outdir}/CNV_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref
    tuple path(regions), path(csi), path(summary)

    output:
    tuple path("${sample_id}.vcf.gz"),
          path("${sample_id}.vcf.gz.tbi"),
          path("${sample_id}_cnv.bed.gz"),
          path("${sample_id}_cnv.bed.gz.tbi")

    script:
    """
    spectre CNVCaller \
        --coverage ${regions} \
        --output-dir ./ \
        --sample-id ${sample_id} \
        --reference ${ref} \
        --threads ${task.cpus} \
        --min-variant-reads 5
    """
}
