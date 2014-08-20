#!/usr/bin/env bash

source ~/.bashrc

INPUT=$1
OUTPUT=$2

source ~/.bashrc

# Note: if the input is a BAM, replace 'cat' with 'samtools view'

# Translate the CIGAR and MD tag to reproduce the alignment of the read and the
# reference, then print the sequence preceeded by a combination of the target
# and barcode.

cat ${INPUT} \
	| sam2pairwise > ${INPUT}.temp

# Get the barcode, append to the other file
awk '{print substr($20,6,length($20)-5)}' ${INPUT} >> ${INPUT}.temp

# Make the relevant parts one line

awk -v OFS="\t" 'BEGIN{i=0}{ i++; if(i == 1){target=$3}; if(i == 2){read=$0}; if(i == 3){matches=$0}; if(i == 4){reference=$0} ; if(i == 5){print target"_"$0,read,matches,reference; i = 0} }' ${INPUT}.temp >> ${OUTPUT}

rm ${INPUT}.temp

exit
