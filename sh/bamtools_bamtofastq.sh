#!/usr/bin/env bash

INBAM=$1
OUTFASTQ=$2

source ~/.bashrc

bamtools convert -format fastq -in ${INBAM} | gzip -c > ${OUTFASTQ}

exit
