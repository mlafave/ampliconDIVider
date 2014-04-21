#!/usr/bin/env bash

source ~/.bashrc

INBAM=$1
HEADER=$2

samtools view ${INBAM} \
	| awk '{print $0"\t"$3"_"substr($20,6,length($20)-5)}' \
	| sort -k21,21 \
	| awk -v OFS="\t" 'BEGIN{i=0}{ if($21 != prev){close("region_barcode."i".sam"); ++i}; print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20 >> "region_barcode."i".sam" ; prev=$21}END{print i >> "groupcount"}'

i=0
while 
	[ $i -lt `head groupcount` ]
do 
	i=$[ $i + 1 ]
	
	cat ${HEADER} region_barcode.${i}.sam \
		| samtools view -S -b - \
		| samtools sort -m 2000000000 - region_barcode.${i}
	
	rm region_barcode.${i}.sam
	
done


exit
