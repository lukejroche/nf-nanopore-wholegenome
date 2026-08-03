process SV {

    container "quay.io/biocontainers/sniffles:2.6.3--pyhdfd78af_0"
    label "process_medium"
    publishDir "${params.outdir}/SV_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    path "${sample_id}_sv.vcf"

    script:
    """
    sniffles \
        --input ${bam} \
        --vcf ${sample_id}_sv.vcf \
        --threads ${task.cpus} \
        --reference ${ref} \
        --snf ${sample_id}_sv.snf
        --minsupport 4 
    """
}
