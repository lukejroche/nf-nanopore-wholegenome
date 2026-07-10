#!/usr/bin/env nextflow

process TEST {

    container "ubuntu:24.04"

    output:
    stdout

    script:
    """
    echo "Hello from Docker!"
    uname -a
    """
}

workflow {
    TEST()
}
