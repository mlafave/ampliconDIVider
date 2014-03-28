#!/usr/bin/env bash

INFASTQ=$1
PAIRED_NAMES=$2

source ~/.bashrc

# Take a FASTQ file and extract the basenames of all reads that have a pair

gunzip -c ${INFASTQ} \
	| awk '(NR)%4==1 {print substr($0, 2, length($0)-3)}' \
	| sort \
	| uniq -d > ${PAIRED_NAMES}

exit
