# ont-multiomics-nf

Long-read (Oxford Nanopore) multi-omics pipeline QC, SNV
(Clair3), SV (Sniffles2), STR (Straglr), CNV (mosdepth + Spectre) and
methylation (modkit) calling.

test data from https://registry.opendata.aws/ont-open-data/

against reference http://hgdownload.cse.ucsc.edu/goldenPath/hg38/chromosomes/chr22.fa.gz

for validation used genome in a bottle https://42basepairs.com/browse/web/giab/release/AshkenazimTrio/HG002_NA24385_son/v5.0q 

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

## Todo
To Do
- Run variant calls against truth set
- Try use ISO 15189, benchmarking to set specific filtering parameters for specific FDR against truth set for variant called data
- Work out criteria needed for clinical relevance scoring	Germline Tiering (ACMG/AMP)	Somatic Tiering (AMP/ASCO/CAP)
- Integrate ensemble VEP, clinvar and gnomAD 
- handle multiple chromosomes
- handle multiple samples
- handle AWS
- handle SLURM
- handle parent data
