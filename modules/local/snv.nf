process SNV {

    container "hkubal/clair3:latest"
    label "process_high"
    publishDir "${params.outdir}/SNV_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    tuple val(sample_id),
          path("${sample_id}_snv.vcf.gz"),
          path("${sample_id}_snv.vcf.gz.tbi")

    script:
    """
    /opt/bin/run_clair3.sh \
        -b ${bam} \
        -f ${ref} \
        -m /opt/models/r1041_e82_400bps_hac_v500 \
        --threads ${task.cpus} \
        --platform ont \
        --output snv_out

    mv snv_out/merge_output.vcf.gz ${sample_id}_snv.vcf.gz
    mv snv_out/merge_output.vcf.gz.tbi ${sample_id}_snv.vcf.gz.tbi
    """
}
