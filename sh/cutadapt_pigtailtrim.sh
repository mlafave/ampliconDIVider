#!/usr/bin/env bash

INFASTQ=$1
OUTFASTQ=$2

source ~/.bashrc

# First trim the right, then the left. There's no significance to doing it that
# way in this file, other than that's the order used in the M13 file.

# -O 7 is as conservative as I can be without using adapter sequence. It should
# be fine, but may need to be altered if reads are being thrown out
# unnecessarily.

gunzip -c ${INFASTQ} |\
	 cutadapt -a aagacac \
	 -O 7 \
	 -e 0 \
	 -m 11 \
	 - |\
	 cutadapt -g gtgtctt \
	 -O 7 \
	 -e 0 \
	 -m 11 \
	 - |\
	 gzip -c > ${OUTFASTQ}

exit
