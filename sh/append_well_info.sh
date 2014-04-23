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
	| join -j1 - ${BARCODE_REF}.idsort \
	| awk -v OFS="\t" '{print $3,$4,$5,$6,$7,$8,$2}' \
	| sort -k1,1 -k2,2 \
	| gzip -c > ${OUTPUT}

rm ${BARCODE_REF}.idsort

exit
