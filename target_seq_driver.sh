#!/bin/bash

# General outline for identifying CRISPR-induced mutations via high-throughput 
# targeted resequencing

# Prior to any of this, make an index of the amplified regions.

# Remove PCR duplicates from input BAM file



# Create index for input BAM file (probably)



# Convert input BAM to FASTQ or FASTA
# FASTA	might be nice if there are further reads to reduce, but FASTQ is
# going to be better for mapping, especially if I use Novoalign.



# Trim off & discard any adapter sequences



# Trim off the barcodes in such a way that the fragment name is recorded &
# associated with the barcode. 
# The fragment will be barcode, then M13, then nothing but genomic.



# Trim off the M13 sequence



# Align the trimmed sequences
# Need to use a gap-aware aligner.  Try Novoalign the first time out, but BWA
# or Bowtie2 are also options.



# Throw out any alignments in which the sequence hit doesn't agree with what
# the barcode predicted should have been hit



# Split the SAM output into as many SAM files as there are fish (that is, split
# by barcode)



# Convert the SAMs to BAMs



# For each BAM...

	# (MAYBE remove PCR duplicates again? Probably not necessary, but keep in
	# mind)



	# Make variant calls, ending up with VCF
	# For the first time through, this is probably best done with bam2mpg,
	# followed by mpg2vcf.
	
	
	
	# Output an indication of the fish line, the individual ID, and if it's
	# homozygous reference (0/0), het (1/0), or homozygous mutant (1/1).
	


# Concatenate the output of each bam & arrange by fish line



# Output a file of four columns: fish line, number of 1/0, number of 1/1,
# number of 1/1.



	
	


