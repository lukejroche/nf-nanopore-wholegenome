process STR {

    container "ghcr.io/lukejroche/straglr:1.5.6"
    label "process_medium"
    publishDir "${params.outdir}/STR_calls", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path ref

    output:
    path "${sample_id}_str*"

    script:
    def regionArg = params.str_regions ? "--regions ${params.str_regions}" : ""

    """
    straglr.py \
        ${bam} \
        ${ref} \
        ${sample_id}_str \
        ${regionArg} \
        --nprocs ${task.cpus} \
        --min_support 3
    
    sed -i '1d' HG002_str.tsv
    """

    
}
