#!/usr/bin/env bash

INFASTQ=$1
PAIRED_LISTPASS_BARCODES=$2
OUTFASTQ=$3

source ~/.bashrc

# Take a FASTQ file and only keep the entries that show up on the list of reads
# that have 1) an acceptable barcode, 2) a paired read, and 3) do not have
# inconsistent barcodes between the reads.

gunzip -c ${INFASTQ} \
	| awk 'BEGIN{i=0}{ i++; if(i == 1){id=$1}; if(i == 2){seq=$1}; if(i == 3){plus=$1}; if(i == 4){print substr(id, 2, length(id)-3)"\t"id"\t"seq"\t"plus"\t"$1; i=0} }' \
	| sort -k1,1 \
	| join -j 1 - ${PAIRED_LISTPASS_BARCODES} \
	| awk -v OFS="\n" '{print $2,$3,$4,$5}' \
	| gzip -c > ${OUTFASTQ}

exit
