#!/usr/bin/env bash

source ~/.bashrc

INBAM=$1
OUTPUT=$2

# Having determined that INBAM contains no legit DIVs, this script
# identifies the most frequent read sequence and prints it with the
# target_barcode ID.

SEQ=`samtools view ${INBAM} \
	| cut -f10 \
	| sort \
	| uniq -c \
	| sort -k1,1nr \
	| head -1 \
	| awk '{print $2}'`

samtools view ${INBAM} \
	| grep -m1 ${SEQ} \
	| awk '{print $3"_"substr($20,6,length($20)-5)"\t"$10"\tno_div\tno_div"}'  >> ${OUTPUT}

exit
