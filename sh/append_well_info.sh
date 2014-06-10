#!/usr/bin/env bash

source ~/.bashrc

BARCODE_REF=$1
INPUT=$2
OUTPUT=$3

# This script takes a file that contains target_barcode IDs and sequences, and
# adds in the other information from the barcode file (like plate and well
# position, line and individual number)

awk '{print $3"_"$6"\t"$0}' ${BARCODE_REF} \
	| sort -k1,1 > ${BARCODE_REF}.idsort


sort -k1,1 ${INPUT} \
	| join -t $'\t' -j1 ${BARCODE_REF}.idsort - \
	| sort -k2,2 -k3,3 \
	| awk -F"\t" -v OFS="\t" '{print $2,$3,$4,$5,$6,$7"\n"$8"\n"$9"\n"$10}' \
	| gzip -c > ${OUTPUT}


rm ${BARCODE_REF}.idsort

exit
