process ANN_SNV {
    input: path(input_vcf)
    output: path("annotated.vcf")
    script:
    """
    vep -i ${input_vcf} -o annotated.vcf --vcf --cache \\
        --plugin gnomADc --plugin REVEL --plugin SpliceAI \\
        --custom clinvar.vcf.gz,ClinVar,vcf,exact
    """
}
