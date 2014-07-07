#!/usr/bin/env bash

SHORTPRIMER=$1
LONGFRAGPRIMER=$2
OUTPUT=$3

source ~/.bashrc

# Shorten the primers from the primer list to the length of the shortest among
# them, and rearrange to prepare for a join.

awk -v n="${SHORTPRIMER}" '{print substr($2,1,n)"\t"$1"\n"substr($3,1,n)"\t"$1}' ${LONGFRAGPRIMER} \
	| sort -k1,1 > ${OUTPUT}
		
exit
