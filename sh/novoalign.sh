#!/usr/bin/env bash

INFASTQ1=$1
INFASTQ2=$2
INDEX=$3
MEANFRAG=$4
FRAGSD=$5
OUTBAM=$6

source ~/.bashrc

novoalign \
	-d ${INDEX} \
	-f ${INFASTQ1} ${INFASTQ2} \
	-F STDFQ \
	--Q2Off \
	-p -1 \
	-o SAM \
	-i PE ${MEANFRAG},${FRAGSD} \
	-c 10 \
	| samtools view -S -b - > ${OUTBAM}

exit
