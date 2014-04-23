#!/usr/bin/env bash

source ~/.bashrc

INBAM=$1
OUTPUT=$2

# Identify the most common sequence that contains a deletion

SEQ=`samtools view ${INBAM} \
	| awk '$6 ~ /D/ {print $10}' \
	| sort \
	| uniq -c \
	| sort -k1,1nr \
	| head -1 \
	| awk '{print $2}'`

# Extract the first instance of said sequence from the BAM

samtools view ${INBAM} \
	| grep -m1 ${SEQ} > ${OUTPUT}

exit
