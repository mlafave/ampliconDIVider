#!/usr/bin/env bash


source ~/.bashrc

INBAM=$1
OUTBAM=$2

# Keep only proper pairs from a BAM file (removing unpaired an unaligned reads)

samtools view -f 3 -h ${INBAM} \
	| samtools view -S -b -  > ${OUTBAM}

exit
