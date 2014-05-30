#!/usr/bin/env bash

BCNAME=$1
BADFRAGLIST=$2
BCLOUT=$3
BCROUT=$4

source ~/.bashrc

# This script uses a "blacklist" from barcode_doubleblacklist.sh to thin out the
# files reporting the association of barcodes and fragment names. Specifically,
# it removes both reads from any fragment that was found to have inverted M13
# primers in a single read.
# In addition, this script removes all entries that lack anything in the barcode
# column.

awk '$2 {print $0"\t"substr($2, 1, length($2)-2)}' ${BCNAME}.bcL \
	| sort -k3,3 \
	| join -v 1 -1 3 -2 1 - ${BADFRAGLIST} \
	| cut -d' ' -f2-3 > ${BCLOUT}

awk '$2 {print $0"\t"substr($2, 1, length($2)-2)}' ${BCNAME}.bcR \
	| sort -k3,3 \
	| join -v 1 -1 3 -2 1 - ${BADFRAGLIST} \
	| cut -d' ' -f2-3 > ${BCROUT}

exit
