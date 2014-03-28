#!/usr/bin/env bash

BARCODE_REF=$1
DETECTED_BARCODES=$2
OUTPUT=$3

source ~/.bashrc

cut -f6 ${BARCODE_REF} | sort -u > ${BARCODE_REF}.whitelist

gunzip -c ${DETECTED_BARCODES} \
	| join -j 1 - ${BARCODE_REF}.whitelist \
	| sort -k2,2 \
	| gzip -c > ${OUTPUT}

rm ${BARCODE_REF}.whitelist

exit
