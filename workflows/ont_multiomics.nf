/*
 * ============================================================================
 *  ONT multi-omics workflow
 *  align/sort -> QC / SNV / SV / STR / CNV / methylation
 * ============================================================================
 */

include { SORT_INDEX } from '../modules/local/sort_index'
include { QC         } from '../modules/local/qc'
include { SNV        } from '../modules/local/snv'
include { SV         } from '../modules/local/sv'
include { STR        } from '../modules/local/str'
include { MOSDEPTH   } from '../modules/local/mosdepth'
include { CNV        } from '../modules/local/cnv'
include { MODKIT     } from '../modules/local/modkit'



/*
 * --analysis 'qc,snv,sv' -> ['qc','snv','sv']
 * Case-insensitive, whitespace-tolerant.
 *
 */

def parseAnalyses() {
    (params.analysis ?: '')
        .split(',')
        .collect { it.trim().toLowerCase() }
        .findAll { it }
}

def runAnalysis(String name) {
    parseAnalyses().contains(name)
}

workflow ONT_MULTIOMICS {

    main:

    def requestedAnalyses = parseAnalyses()
    def needsReference     = ['snv', 'sv', 'str', 'cnv', 'methylation']
    def missingRef          = requestedAnalyses.findAll { it in needsReference }
    if (!params.reference && missingRef) {
        error "A --reference genome is required for: ${missingRef}"
    }

    /*
     * (sample_id, bam) tuples from the input BAM(s).
     * sample_id = the part of the filename before the first "_", e.g.
     * "sampleA_aligned.bam" -> "sampleA". Name your inputs accordingly.
     */
    bam_ch = Channel
        .fromPath(params.bam, checkIfExists: true)
        .map { bam ->
            def sample_id = bam.baseName.split('_')[0]
            tuple(sample_id, bam)
        }

    // Sort + index, unless the BAMs are already sorted & indexed
    if (params.skip_sort) {
        sorted_bam = bam_ch.map { sample_id, bam ->
            tuple(sample_id, bam, file("${bam}.bai"))
        }
    } else {
        sorted_bam = SORT_INDEX(bam_ch)
    }
    ref_ch = Channel.value(file(params.reference))

    // Downstream analyses, opt-in via --analysis
    if (runAnalysis('qc'))
        QC(sorted_bam)

    if (runAnalysis('snv'))
        SNV(sorted_bam, ref_ch)

    if (runAnalysis('sv'))
        SV(sorted_bam, params.reference)

    if (runAnalysis('str'))
        STR(sorted_bam, params.reference)

    if (runAnalysis('cnv')) {
        MOSDEPTH(sorted_bam)
        CNV(sorted_bam, params.reference, MOSDEPTH.out)
    }

    if (runAnalysis('methylation'))
        MODKIT(sorted_bam, params.reference)

    // Future: benchmark/annotate steps were sketched in the original
}
