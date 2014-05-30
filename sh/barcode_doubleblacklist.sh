#!/usr/bin/env bash

BCNAME=$1
BADFRAGLIST=$2

source ~/.bashrc

# Examines read names that show up more than once between the L and R barcode
# file in order to produce a list of fragments that contain said reads. This
# list can serve as a blacklist of reads to throw out. 

cat ${BCNAME}.bcL ${BCNAME}.bcR \
	| cut -d' ' -f2 \
	| sort \
	| uniq -d \
	| awk '{print substr($0, 1, length($0)-2)}' \
	| sort -u > ${BADFRAGLIST}

exit
