#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { ONT_MULTIOMICS } from './workflows/ont_multiomics'

workflow {

    if (!params.bam) {
        error """
        No valid input supplied.

        Please provide:

            --bam 'path/to/*.bam'

        (--fastq and --pod5 are declared as parameters for a future FASTQ/pod5
         entry point, but that path isn't wired up yet -- see
         modules/local/align.nf and workflows/ont_multiomics.nf)
        """
    }

    ONT_MULTIOMICS()
}
