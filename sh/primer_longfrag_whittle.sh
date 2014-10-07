#!/usr/bin/env bash

CUTOFF=$1
LONGFRAGBC=$2
INFASTQ=$3
OUTTAB=$4

source ~/.bashrc


awk -v n="${CUTOFF}" '{print substr($2,1,n)"\t"substr($3,1,n)}' ${LONGFRAGBC} \
	> ${LONGFRAGBC}.2col

# Make a single column of long-fragment barcodes, and sort them to prep for a
# join
awk '{print $1"\n"$2}' ${LONGFRAGBC}.2col \
	| sort -k1,1 > ${LONGFRAGBC}.1col

gunzip -c ${INFASTQ} \
	| awk -v n="${CUTOFF}" 'BEGIN{i=1}{if(i < 2){id=$1}; if(i == 2){seq=$1; primer=substr($1,1,n)}; if(i == 3){plus=$1}; if(i == 4){print primer"\t"id"\t"seq"\t"plus"\t"$1; i=0}; i++}' \
	| sort -k1,1 \
	| join -j 1 - ${LONGFRAGBC}.1col > ${OUTTAB}

rm ${LONGFRAGBC}.1col

exit
