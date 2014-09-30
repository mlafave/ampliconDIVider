#!/usr/bin/env bash

BCFILE=$1
BADFRAGLIST=$2

source ~/.bashrc

# Creates a blacklist of fragments that have the same element in the same
# orientation on different reads. For example, if M13 showed up on read /1 and
# /2, but in the R orientation both times, that needs to be removed.

# Note that this blacklist is only intended to be used to whittle down the same
# bc file with which it was created. You COULD apply it to both, but it'd be a
# matter of using cat | sort -u to put the two blacklists together.

awk '{print substr($2,1,length($2)-2)}' ${BCFILE} \
	| sort \
	| uniq -d \
	| sort > ${BADFRAGLIST}

exit
