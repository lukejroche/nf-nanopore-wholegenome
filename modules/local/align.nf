process ALIGN {

    input:
    path reads
    path ref

    output:
    path "aligned.bam"

    script:
    """
    minimap2 -ax map-ont ${ref} ${reads} \
        | samtools sort -o aligned.bam

    samtools index aligned.bam
    """
}
