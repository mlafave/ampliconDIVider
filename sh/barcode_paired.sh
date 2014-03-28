#!/usr/bin/env bash

LISTPASS_BARCODES=$1
PAIRED_NAMES=$2
PAIRED_LISTPASS_BARCODES=$3

source ~/.bashrc

# Take the list of barcodes that did not have an inconsistent pair & which
# showed up on the whitelist, and only keep those that ALSO show up on the list
# of FASTQ reads that still have a pair.

gunzip -c ${LISTPASS_BARCODES} \
	| sort -k2,2 \
	| join -1 2 -2 1 - ${PAIRED_NAMES} \
	| sort -k1,1 > ${PAIRED_LISTPASS_BARCODES}

exit
