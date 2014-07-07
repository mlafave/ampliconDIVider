#!/usr/bin/env bash

LONGFRAGTAB=$1
MINLONGPRIMERS=$2
OUTPUT=$3

source ~/.bashrc

# Add the fragment ID to the reads, count how often each read appeared, and
# report the top ten reads for each fragment.

sort -k1,1 ${LONGFRAGTAB} \
	| join -j1 ${MINLONGPRIMERS} - \
	| tr " " "\t" \
	| sort -k2,2 -k3,3 \
	| cut -f2,4 \
	| sort \
	| uniq -c \
	| sort -k2,2 -k1,1nr \
	| awk 'arr[$2]++ < 10' \
	| awk -v OFS="\t" '{print $1,$2,$3}' \
	| gzip -c > ${OUTPUT}

exit
