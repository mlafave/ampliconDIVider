#!/usr/bin/env bash

REFERENCE=$1
INBAM=$2
OUTMPG=$3

source ~/.bashrc

# -qual_filter 20: minimum quality for a base to be considered for a genotype 
# 	 call.
# --bam_filter '-q31': filters to pass to 'samtools view'.  In this case, it's 
# 	 filtering based on mapping quality, limiting the SAM alignments processed by 
# 	 bam2mpg (it'll skip alignments with MAPQ smaller than 31).  Novoalign 
#	 decides what the mapping quality is.  It's a phred score of how likely it 
#	 is to be mapped correctly.  I think Jim said Novoalign's max is 70.
# --pileup_filter '-B -A': options to pass to 'samtools mpileup'. In this case, 
# 	 -B basically helps reduce false snps by turning off probabilistic realignment,
# 	 and -A says to not skip anomalous read pairs in variant calling (I assume that
# 	 means pairs that aren't "propper" are included).
# -ds_coverage 0: Turns off the "dangerous" option of requiring a base to be 
# 	 observed on BOTH strands in order for it to count.  This was turned off 
#	 because of exome sequencing; we COULD have turned it on, but it's fine 
#	 without it.

bam2mpg \
	--qual_filter 20 \
	--bam_filter '-q31' \
	--pileup_filter '-B' \
	--ds_coverage 0 \
	${REFERENCE} \
	${INBAM} \
	| gzip -c > ${OUTMPG}

exit