#!/usr/bin/env bash

INFASTQ=$1
BCNAME=$2
OUTFASTQ=$3

source ~/.bashrc

# First trim the right, then the left (and use -q 3). N's are used to capture
# the barcode as wildcards.

# -O 13 is a conservative placeholder

gunzip -c ${INFASTQ} |\
	 cutadapt -a ACTGGCCGTCGTTTTACANNNNNN \
	 -O 13 \
	 -e 0 \
	 -m 11 \
	 --wildcard-file ${BCNAME}.bcR - |\
	 cutadapt -g NNNNNNTGTAAAACGACGGCCAGT \
	 -O 13 \
	 -e 0 \
	 -m 11 \
	 -q 3 \
	 --wildcard-file ${BCNAME}.bcL - |\
	 gzip -c > ${OUTFASTQ}

exit
