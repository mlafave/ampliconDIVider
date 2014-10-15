#!/usr/bin/env bash

FREQDIV=$1
RANGEDIV=$2
OUTPUT=$3

# Fetches the barcode from the .freqdiv SAM file, and appends it to the target
# ID in the .rangediv file.

function check
{
  if
  	[ ! -f $1 ]
  then
  	echo >&2 "$1 not detected by div_barcode.sh"
  	exit 1
  fi
}

check $FREQDIV
check $RANGEDIV

BARCODE=`awk '{print substr($20,6,length($20)-5)}' ${FREQDIV}`

awk -v barcode="${BARCODE}" -v OFS="\t" '{ print $1"_"barcode,$2,$3,$4 }' ${RANGEDIV} \
	> ${OUTPUT}

exit
