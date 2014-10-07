#!/usr/bin/env bash

BCFILE=$1
BADFRAGLIST=$2
BCOUT=$3

source ~/.bashrc

# This script uses a "blacklist", such as that from barcode_doubleblacklist.sh
# to thin out the files reporting the association of barcodes and fragment
# names. Specifically, it removes both reads from any fragment that was found to
# have inverted M13 primers in a single read.
# In addition, this script removes all entries that lack anything in the barcode
# column.

awk '$2 {print $0"\t"substr($2, 1, length($2)-2)}' ${BCFILE} \
	| sort -k3,3 \
	| join -v 1 -1 3 -2 1 - ${BADFRAGLIST} \
	> ${BCOUT}_temp
	
	
	# If the third column is the first column plus a '/', the join rearranged
	# the columns, and you should take columns 2 and 3. If it isn't, the columns
	# have not been rearranged, and you should take columns 1 and 2.
	
	if [ `head -1 ${BCOUT}_temp | awk '{print substr($3,1,length($3)-1)}'` == `head -1 ${BCOUT}_temp | cut -d' ' -f1`/ ]
	then
		cut -d' ' -f2-3 ${BCOUT}_temp > ${BCOUT}
	else
		cut -d' ' -f1-2 ${BCOUT}_temp > ${BCOUT}
	fi
	
	rm ${BCOUT}_temp	

exit
