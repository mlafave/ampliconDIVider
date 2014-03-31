#!/usr/bin/env bash


PAIRED_LISTPASS_BARCODES=$1
INBAM=$2
HEADER=$3
OUTBAM=$4

source ~/.bashrc

# Format the barcodes to be added to the BAM file, then use join to add them.
# Assumes that the PAIRED_LISTPASS_BARCODES file is a column of basenames,
# followed by a column of barcodes.
# Further assumes that the first column of the BAM file is just the base name
# of the read, with no @ or /1 /2.

gunzip -c ${PAIRED_LISTPASS_BARCODES} \
	| awk '{print $1" BC:Z:"$2}' \
	| sort -k1,1 > ${PAIRED_LISTPASS_BARCODES}_bctemp

samtools view ${INBAM} \
	| sort -k1,1 \
	| join -j 1 - ${PAIRED_LISTPASS_BARCODES}_bctemp \
	| tr " " "\t" \
	| cat ${HEADER} - \
	| samtools view -S -b -  > ${OUTBAM}

rm ${PAIRED_LISTPASS_BARCODES}_bctemp

exit
