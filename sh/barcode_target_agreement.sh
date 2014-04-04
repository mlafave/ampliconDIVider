#!/usr/bin/env bash

source ~/.bashrc

BARCODE_REF=$1
INBAM=$2
HEADER=$3
OUTBAM=$4


cut -f3,6 ${BARCODE_REF} | tr "\t" "_" | sort > ${BARCODE_REF}.region_barcodes


samtools view ${INBAM} \
	| awk '{print $0"\t"$3"_"substr($20,6,length($20)-5)}' \
	| sort -k21,21 \
	| join -1 21 -2 1 - ${BARCODE_REF}.region_barcodes \
	| tr " " "\t" \
	| cut -f2- \
	| cat ${HEADER} - \
	| samtools view -S -b -  > ${OUTBAM}

rm ${BARCODE_REF}.region_barcodes

exit
