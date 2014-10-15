#!/usr/bin/env bash

BARCODE_REF=$1
RANGEDIVBC=$2
OUTPUT=$3

# Combines the barcode file with the .rangdivbc file to create a file with the
# following columns:
# plate	well	target	founder	progenyID	barcode	BAMnumber	DIVtype	DIV

cat ${BARCODE_REF} \
	| awk '{print $3"_"$6"\t"$0}' \
	| sort -k1,1 \
	| join -t $'\t' -j1 - ${RANGEDIVBC} \
	| cut -f2- \
	>> ${OUTPUT}

exit
