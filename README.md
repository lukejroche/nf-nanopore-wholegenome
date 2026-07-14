# ont-multiomics-nf

Long-read (Oxford Nanopore) multi-omics pipeline QC, SNV
(Clair3), SV (Sniffles2), STR (Straglr), CNV (mosdepth + Spectre) and
methylation (modkit) calling.

## Usage

```bash
nextflow run main.nf \
    --bam 'data/*_sorted.bam' \
    --reference genome.fa \
    --analysis 'qc,snv,sv,cnv,methylation' \
    --outdir results \
    -profile docker
```

Sample IDs come from the part of the BAM filename before the first `_`
(`sampleA_sorted.bam` -> `sampleA`)
