#!/usr/bin/env bash

source ~/.bashrc

INPUT=$1
OUTPUT=$2

# Note: if the input is a BAM, replace 'cat' with 'samtools view'

# Translate the CIGAR to have the sequence incorporate deletions with respect to
# the reference, then print the sequence preceeded by a combination of the
# target and barcode.

cat ${INPUT} \
	| ../perl/translate_cigar.pl \
	| awk '{print $3"_"substr($20,6,length($20)-5)"\t"$10}' >> ${OUTPUT}

exit
