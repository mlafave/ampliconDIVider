#!/usr/bin/env bash

INFASTQ1=$1
INFASTQ2=$2
INDEX=$3
LENGTH=$4
MEANFRAG=$5
FRAGSD=$6
OUTBAM=$7

source ~/.bashrc

novoalign \
	-d ${INDEX} \
	-f ${INFASTQ1} ${INFASTQ2} \
	-F STDFQ \
	-n ${LENGTH} \
	-p -1 \
	-o SAM \
	-i PE ${MEANFRAG},${FRAGSD} \
	| samtools view -S -b - > ${OUTBAM}

exit
