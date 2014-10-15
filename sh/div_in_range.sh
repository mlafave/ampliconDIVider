#!/usr/bin/env bash

FREQDIV=$1
BAMNUMBER=$2
RANGES=$3
OUTPUT=$4

function check
{
  if
  	[ ! -f $1 ]
  then
  	echo >&2 "$1 not detected by div_in_range.sh"
  	exit 1
  fi
}

check $FREQDIV
check $RANGES

TARGET=`head -1 ${FREQDIV} | cut -f3`
			
LEFT=`grep $TARGET $RANGES | cut -f2 `
			
RIGHT=`grep $TARGET $RANGES | cut -f3`
			
cat ${FREQDIV} \
	| /home/lafavemc/Crispr/Targeted_reseq/ampliconDIVider/perl/sam_all_div.pl \
	| awk -F_ '{print $0"\t"$2"\t"$2+($3-1)}' \
	| awk -v LEFT="$LEFT" -v RIGHT="$RIGHT" '($3 >= LEFT && $3 <= RIGHT) || ($2 >= LEFT && $2 <= RIGHT)' \
	| cut -f1 \
	| sort -u \
	| awk -v TARGET="$TARGET" -v i="${BAMNUMBER}" '{ out=out$1"::"; if(/^D/){dflag=1};if(/^I/){iflag=1} }END{if(dflag && iflag){t="C"}else if(dflag){t="D"} else if(iflag){t="I"}; if(out){print TARGET"\t"i"\t"t"\t"substr(out,1,length(out)-2)}}' \
	> ${OUTPUT}
	
exit
