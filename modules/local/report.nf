process REPORT {

    input:
    path qc
    path snv
    path sv
    path cnv
    path meth

    output:
    path "report.txt"

    script:
    """
    echo "MULTI-OMICS REPORT" > report.txt
    echo "==================" >> report.txt

    echo "\nQC:" >> report.txt
    cat ${qc} >> report.txt

    echo "\nSNVs:" >> report.txt
    cat ${snv} >> report.txt

    echo "\nSVs:" >> report.txt
    cat ${sv} >> report.txt

    echo "\nCNVs:" >> report.txt
    cat ${cnv} >> report.txt

    echo "\nMethylation:" >> report.txt
    cat ${meth} >> report.txt
    """
}
