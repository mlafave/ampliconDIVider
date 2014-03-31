#!/usr/bin/env bash

INFASTQ=$1
OUTFASTQ=$2

source ~/.bashrc

# Split the FASTQ into two files, one with read /1 and the other with read /2

gunzip -c ${INFASTQ} \
	| awk -v outfastq="${OUTFASTQ}" 'BEGIN{flag=0}{if(NR%4 == 1){ if($1 ~ /1$/){flag=1}else{flag=2}} ; if(flag == 1){print >> outfastq".1"}else{print >> outfastq".2"}  }'

exit
