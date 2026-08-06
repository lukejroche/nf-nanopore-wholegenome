# nf-nanopore-wholegenome

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A525.04.0-23AA62?style=flat)](https://www.nextflow.io/)

[![Docker](https://img.shields.io/badge/docker-enabled-blue?style=flat&logo=docker)](https://www.docker.com/)

[![nf-core](https://img.shields.io/badge/nf--core-compatible-green?style=flat)](https://nf-co.re/)

[![nf-test](https://github.com/lukejroche/nf-nanopore-wholegenome/actions/workflows/nf-test.yml/badge.svg)](https://github.com/lukejroche/nf-nanopore-wholegenome/actions/workflows/nf-test.yml)

[![nf-core lint](https://github.com/lukejroche/nf-nanopore-wholegenome/actions/workflows/lint.yml/badge.svg)](https://github.com/lukejroche/nf-nanopore-wholegenome/actions/workflows/lint.yml)

*Work in progess*

# Info

Long-read (Oxford Nanopore) multi-omics pipeline QC, SNV
(Clair3), SV (Sniffles2), STR (Straglr), CNV (mosdepth + Spectre) and
methylation (modkit) calling.

test data from https://registry.opendata.aws/ont-open-data/

against reference http://hgdownload.cse.ucsc.edu/goldenPath/hg38/chromosomes/chr22.fa.gz

validation is underway using genome in a bottle https://42basepairs.com/browse/web/giab/release/AshkenazimTrio/HG002_NA24385_son/v5.0q 

## Usage

```bash
nextflow run main.nf \
    --bam 'data/*_sorted.bam' \
    --reference genome.fa \
    --analysis 'qc,snv,sv,cnv,methylation' \
    --outdir results \
    -profile laptop/slurm/aws // aws not wired in yet
```

Sample IDs come from the part of the BAM filename before the first `_`
(`sampleA_sorted.bam` -> `sampleA`)

## Containers

| Tool | Image |
|------|-------|
| Clair3 | hkubal/clair3:2.0.2 |
| Sniffles | quay.io/biocontainers/sniffles:2.6.3--pyhdfd78af_0 |
| Modkit | ontresearch/modkit:0.6.4 |
| Spectre | ghcr.io/lukejroche/spectre:0.2.1 |
| Straglr | ghcr.io/lukejroche/straglr:1.5.6 |

## Todo
- Run variant calls against truth set
- Implement ISO 15189, benchmarking to set specific filtering parameters for specific FDR against truth set for variant called data
- Implement and label criteria needed for clinical relevance scoring - Germline Tiering (ACMG/AMP) or Somatic Tiering (AMP/ASCO/CAP)
- Integrate ensemble VEP, clinvar and gnomAD
- handle multiple chromosomes
- handle multiple samples
- handle AWS
- handle parent data
