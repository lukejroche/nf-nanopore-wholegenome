process MOSDEPTH {

    container "spectre:0.2.1"
    label "${params.machine}"
    publishDir "${params.outdir}/mosdepth", mode: 'copy',
        saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple path("${sample_id}.regions.bed.gz"),
          path("${sample_id}.regions.bed.gz.csi"),
          path("${sample_id}.mosdepth.summary.txt")

    script:
    """
    mosdepth -t ${task.cpus} -x -b 1000 -Q 20 ${sample_id} ${bam}
    """
}
