#!/usr/bin/env bash

source ~/.bashrc

SAMPLE=$1
REFERENCE=$2
INMPG=$3
OUTSNV=$4
OUTDIV=$5

# --sample gives the basename of the sample, which is used in the VCF as a
#   column header.
# --ref is the FASTA genome reference
# --mpg is the MPG file to be processed
# --notabix prevents the creation of index files


mpg2vcf.pl \
	--sample ${SAMPLE} \
	--ref ${REFERENCE} \
	--mpg ${INMPG} \
	--snv_outfile ${OUTSNV} \
	--div_outfile ${OUTDIV} \

if [ -f ${OUTSNV}.tbi ] ; then rm ${OUTSNV}.tbi ; fi
if [ -f ${OUTDIV}.tbi ] ; then rm ${OUTDIV}.tbi ; fi

exit