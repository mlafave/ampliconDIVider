#!/usr/bin/env bash

# Set up functions for file testing & error reporting.
function throw_error
{
  echo ERROR: $1
  exit 1
}

function test_file
{
 if 
   [ -f $1 ]
 then 
   echo "$1 detected."
 else  
   throw_error "$1 was not detected!"
 fi
}

# Source .bashrc to get local aliases, etc. The other bash scripts will all
# need to repeat this step, but this at least checks for the presence of the
# programs at the outset.
source ~/.bashrc


# Verify the presence of required programs
hash samtools 2>/dev/null || throw_error "samtools not found"
hash bamtools 2>/dev/null || throw_error "bamtools not found"
hash cutadapt 2>/dev/null || throw_error "cutadapt not found"
hash novoalign 2>/dev/null || throw_error "novoalign not found"
hash bam2mpg 2>/dev/null || throw_error "bam2mpg not found"
hash mpg2vcf.pl 2>/dev/null || throw_error "mpg2vcf.pl not found"
hash bgzip 2>/dev/null || throw_error "bgzip not found"
hash sam2pairwise 2>/dev/null || throw_error "sam2pairwise not found"

# Get files via CLI
print_usage()
{
  cat <<EOF
Usage: ./ampliconDIVider_driver.sh [options] input.bam
	Options:
	-b	barcode file (required)
	-h	print this help message and exit
	-n	name
	-p	primers of long fragments
	-r	reference FASTA file (required)
	-x	path to alignment index (required)
EOF
}

NAME="target"
while getopts "b:hn:p:r:x:" OPTION
do
	case $OPTION in
    	b)
    		BARCODE_PATH=$OPTARG
    		;;
    	h)
    		print_usage
    		exit 0
    		;;
    	n)
    		NAME=$OPTARG
    		;;
    	p)
    		LONGFRAGPRIMERS_PATH=$OPTARG
    		;;
    	r)
    		REFERENCE=$OPTARG
    		;;
    	x)
    		INDEX=$OPTARG
    		;;
    esac
done
shift $((OPTIND-1))

if [ ! $1 ]; then throw_error "No BAM input."; fi

INBAM=$1

test_file $INBAM

DIR=`dirname $INBAM`
FILE=`basename $INBAM`
BAMPATH="`cd \"$DIR\" 2>/dev/null && pwd -P || echo \"$DIR\"`/$FILE"

BASE=`echo $FILE | sed 's/\(.*\).bam$/\1/'`


# Identify the absolute path to the barcode file, so it can be copied later.

BARCODE_DIR=`dirname $BARCODE_PATH`
BARCODE_REF=`basename $BARCODE_PATH`
BARCODE_PATH="`cd \"$BARCODE_DIR\" 2>/dev/null && pwd -P || echo \"$BARCODE_DIR\"`/$BARCODE_REF"


# If -p was used, identify the absolute path to the long fragment file, so it
# can be copied later.
if [ ${LONGFRAGPRIMERS_PATH} ]
then
	LONGFRAGPRIMERS_DIR=`dirname ${LONGFRAGPRIMERS_PATH}`
	LONGFRAGPRIMERS=`basename ${LONGFRAGPRIMERS_PATH}`
	LONGFRAGPRIMERS_PATH="`cd \"$LONGFRAGPRIMERS_DIR\" 2>/dev/null && pwd -P || echo \"$LONGFRAGPRIMERS_DIR\"`/$LONGFRAGPRIMERS"
fi


# Verify that the name does not have blanks
echo $NAME | grep -q [[:blank:]] && throw_error "'NAME' can't have blanks"


# Make a working directory

WORKDIR=$PWD/Workdir_${NAME}_$JOB_ID

if [ -d $WORKDIR ] ; then throw_error "$WORKDIR already exists!"; fi

mkdir $WORKDIR
cd $WORKDIR

# Adjust for relative paths
INDEX=`echo $INDEX | awk '{ if($1 ~ /^\//){print}else{print "../"$1} }'`

REFERENCE=`echo $REFERENCE | awk '{ if($1 ~ /^\//){print}else{print "../"$1} }'`



# Verify the index exists
function verify_index
{
 if 
   test ! -e $1
 then 
   cd ..
   rmdir $WORKDIR
   throw_error "Index $1 doesn't exist!"
 elif 
   test ! -s $1
 then 
   cd ..
   rmdir $WORKDIR
   throw_error "Index $1 is empty!"
 else
   echo "Index $1 verified."
 fi
}

# The barcode file should be reasonably small, so make a local copy in the
# working directory. That way, there's no need to worry if the main file is
# altered or moved in the meantime.

cp ${BARCODE_PATH} .

# From here on, refer to that copy as BARCODE_REF, defined by basename, etc.
# above.

test_file $BARCODE_REF

# Same thing for the longfragment primers, if they're defined

if [ ${LONGFRAGPRIMERS} ]
then
	cp ${LONGFRAGPRIMERS_PATH} .
	test_file ${LONGFRAGPRIMERS}
fi



################################################################################

# General outline for identifying CRISPR-induced mutations via high-throughput 
# targeted resequencing


# Convert input BAM to FASTQ

echo "Converting to FASTQ..."

../sh/bamtools_bamtofastq.sh $BAMPATH ${BASE}.fastq.gz

test_file ${BASE}.fastq.gz



# Trim off the barcodes in such a way that the fragment name is recorded &
# associated with the barcode. 
# The fragment will be barcode, then M13, then nothing but genomic (with a
# possible pigtail at the end).
# The easiest way to do this is by trimming the M13 and looking for wildcards.


# Trim off the M13 sequence

echo "Trimming M13 sequence and recording barcode..."

../sh/cutadapt_m13trim.sh ${BASE}.fastq.gz \
	${BASE} \
	${BASE}.m13trim.fastq.gz

test_file ${BASE}.m13trim.fastq.gz
test_file ${BASE}.bcR
test_file ${BASE}.bcL



# Trim off & discard pigtail sequences

echo "Trimming pigtail..."
../sh/cutadapt_pigtailtrim.sh ${BASE}.m13trim.fastq.gz \
	${BASE}.fulltrim.fastq.gz

test_file ${BASE}.fulltrim.fastq.gz



# Identify the fragments with reads in which M13 showed up more than once

echo "Finding bad reads with inverted M13..."

../sh/barcode_doubleblacklist.sh \
	${BASE} \
	${BASE}.intraM13blacklist

test_file ${BASE}.intraM13blacklist



# Remove the fragments for which M13 showed up more than once in at least one
# read

echo "Removing fragments with bad inverted-M13 reads."
echo "Operating on bcL..."

../sh/barcode_remove_blacklisted.sh \
	${BASE}.bcL \
	${BASE}.intraM13blacklist \
	${BASE}.bcL.nointraM13invert

test_file ${BASE}.bcL.nointraM13invert

echo "Operating on bcR..."

../sh/barcode_remove_blacklisted.sh \
	${BASE}.bcR \
	${BASE}.intraM13blacklist \
	${BASE}.bcR.nointraM13invert

test_file ${BASE}.bcR.nointraM13invert



# The remainder of the script does not require the original bcL and bcR, nor the
# blacklist.



# Identify the fragments for which M13 showed up in the same orientation on both
# reads (which is bad)

echo "Finding bad fragments with inverted-M13."
echo "Operating on bcL..."

../sh/barcode_interread_blacklist.sh \
	${BASE}.bcL.nointraM13invert \
	${BASE}.bcL.interM13blacklist

test_file ${BASE}.bcL.interM13blacklist

echo "Operating on bcR..."

../sh/barcode_interread_blacklist.sh \
	${BASE}.bcR.nointraM13invert \
	${BASE}.bcR.interM13blacklist

test_file ${BASE}.bcR.interM13blacklist

echo "Removing fragments with bad inverted-M13 fragments."
echo "Operating on bcL..."

../sh/barcode_remove_blacklisted.sh \
	${BASE}.bcL.nointraM13invert \
	${BASE}.bcL.interM13blacklist \
	${BASE}.bcL.noM13invert

test_file ${BASE}.bcL.noM13invert

echo "Operating on bcR..."

../sh/barcode_remove_blacklisted.sh \
	${BASE}.bcR.nointraM13invert \
	${BASE}.bcR.interM13blacklist \
	${BASE}.bcR.noM13invert

test_file ${BASE}.bcR.noM13invert



# Remove reads for which the barcodes do not agree

echo "Identifying reads for which the barcodes do not agree, to be removed later..."

../perl/compare_barcodes.pl ${BASE}.bcL.noM13invert ${BASE}.bcR.noM13invert \
	| sort | gzip -c > ${BASE}.bc.agree.gz

test_file ${BASE}.bc.agree.gz

gzip ${BASE}.bcL.noM13invert
gzip ${BASE}.bcR.noM13invert



# Remove reads for which the barcode is not on the list of accepted barcodes

echo "Identifying fragments with incorrect barcodes, to be removed later..."

../sh/barcode_whitelist_compare.sh ${BARCODE_REF} ${BASE}.bc.agree.gz \
	${BASE}.bc.listpass.gz

test_file ${BASE}.bc.listpass.gz



# Remove the reads that don't have a paired read

echo "Extracting basenames of paired reads from trimmed FASTQ..."
../sh/fastq_paired_basenames.sh ${BASE}.fulltrim.fastq.gz \
	${BASE}.fulltrim.pairednames

test_file ${BASE}.fulltrim.pairednames


echo "Identifying correct & non-inconsistent barcodes that belong to paired reads..."
../sh/barcode_paired.sh ${BASE}.bc.listpass.gz \
	${BASE}.fulltrim.pairednames ${BASE}.bc.listpass.paired

test_file ${BASE}.bc.listpass.paired

rm ${BASE}.fulltrim.pairednames


echo "Removing FASTQ reads that don't have a pair, or which don't have acceptable, consistent barcodes..."
../sh/fastq_paired_passbc.sh ${BASE}.fulltrim.fastq.gz \
	${BASE}.bc.listpass.paired ${BASE}.fulltrim.passbc.fastq.gz

test_file ${BASE}.fulltrim.passbc.fastq.gz


echo "Compressing the paired barcode file..."
gzip ${BASE}.bc.listpass.paired

test_file ${BASE}.bc.listpass.paired.gz



# If the primers of the long fragments were specified, extract the reads that
# correspond to the "long" fragments (primers from two different targets). Find
# the fragments that end in said primers to do so.

if [ ${LONGFRAGPRIMERS} ]
then
	
	# Capture the length of the shortest primer used in long fragments
		
	SHORTPRIMER=`../sh/longfrag_shortest-primer-length.sh ${LONGFRAGPRIMERS}`
	
	
	
	# Identify all reads that begin with a primer that MIGHT be from a long
	# fragment.
	
	../sh/primer_longfrag_whittle.sh \
		${SHORTPRIMER} \
		${LONGFRAGPRIMERS} \
		${BASE}.fulltrim.passbc.fastq.gz \
		${BASE}.fulltrim.passbc.possiblelongfrag.${SHORTPRIMER}.tabfq

	test_file ${BASE}.fulltrim.passbc.possiblelongfrag.${SHORTPRIMER}.tabfq
	test_file ${LONGFRAGPRIMERS}.2col
	
	
	
	# Compare paired reads to find the reads that DID come from a long fragment.
	
	../perl/primer_longfrag_find.pl \
		${LONGFRAGPRIMERS}.2col \
		${BASE}.fulltrim.passbc.possiblelongfrag.${SHORTPRIMER}.tabfq \
		> ${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.tabfq
	
	test_file ${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.tabfq
	
	
	
	# Shorten the primers from the primer list to the length of the shortest
	# among them, and rearrange to prepare for a join.
	
	../sh/longfrag_shorten-primer.sh \
		${SHORTPRIMER} \
		${LONGFRAGPRIMERS} \
		min_${LONGFRAGPRIMERS}_prejoin
		
	test_file min_${LONGFRAGPRIMERS}_prejoin
	
	
	
	# Add the fragment ID to the reads, count how often each read appeared, and
	# report the top ten reads for each fragment.
	
	../sh/longfrag_top10.sh \
		${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.tabfq \
		min_${LONGFRAGPRIMERS}_prejoin \
		${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.top10.gz
				
	test_file ${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.top10.gz

fi



# Split the FASTQ into two files (if using Novoalign with paired reads)

echo "Splitting the FASTQ file..."
../sh/fastq_split.sh ${BASE}.fulltrim.passbc.fastq.gz \
	${BASE}.fulltrim.passbc

test_file ${BASE}.fulltrim.passbc.1
test_file ${BASE}.fulltrim.passbc.2

echo "Renaming split FASTQ files..."
mv ${BASE}.fulltrim.passbc.1 ${BASE}.fulltrim.passbc.1.fastq
mv ${BASE}.fulltrim.passbc.2 ${BASE}.fulltrim.passbc.2.fastq

test_file ${BASE}.fulltrim.passbc.1.fastq
test_file ${BASE}.fulltrim.passbc.2.fastq



# Align the trimmed sequences
# Need to use a gap-aware aligner. Novoalign is used here, but BWA or Bowtie2
# are also options.

echo "Aligning reads..."
../sh/novoalign.sh \
	${BASE}.fulltrim.passbc.1.fastq \
	${BASE}.fulltrim.passbc.2.fastq \
	${INDEX} \
	300 \
	309 \
	1259 \
	${BASE}.aligned.bam

test_file ${BASE}.aligned.bam

gzip ${BASE}.fulltrim.passbc.1.fastq
gzip ${BASE}.fulltrim.passbc.2.fastq


# Store the header of the BAM as a separate SAM file

echo "Extracting BAM header..."
samtools view -H ${BASE}.aligned.bam > ${BASE}.aligned.header.sam

test_file ${BASE}.aligned.header.sam



# Extract only paired reads (discarding unalinged reads in the process)

echo "Extracting proper pairs..."
../sh/samtools_proper_pairs.sh \
	${BASE}.aligned.bam \
	${BASE}.aligned.pp.bam

test_file ${BASE}.aligned.pp.bam



# Put in the barcode information

echo "Adding barcode information..."
../sh/bam_barcode_add.sh ${BASE}.bc.listpass.paired.gz \
	${BASE}.aligned.pp.bam \
	${BASE}.aligned.header.sam \
	${BASE}.aligned.pp.bc.bam

test_file ${BASE}.aligned.pp.bc.bam



# Throw out any alignments in which the sequence hit doesn't agree with what
# the barcode predicted should have been hit

echo "Removing reads for which the barcode is not consistent with the aligned target..."
../sh/barcode_target_agreement.sh \
	${BARCODE_REF} \
	${BASE}.aligned.pp.bc.bam \
	${BASE}.aligned.header.sam \
	${BASE}.aligned.pp.bc.target.bam

test_file ${BASE}.aligned.pp.bc.target.bam



# Split the BAM output into as many BAM files as there are fish (that is, split
# by barcode & position, since some barcodes are used for multiple fish). Split
# into SAMs, but convert them to BAMs.

echo "Splitting BAM by target and barcode..."
../sh/region_barcode_bamsplit.sh \
	${BASE}.aligned.pp.bc.target.bam \
	${BASE}.aligned.header.sam

test_file groupcount

i=0
while 
	[ $i -lt `head groupcount` ]
do
	i=$[ $i + 1 ]
	test_file region_barcode.${i}.bam
done


echo "Starting loop to check each region_barcode combo for deletions..."
# For each BAM...
i=0
while 
	[ $i -lt `head groupcount` ]
do
	i=$[ $i + 1 ]
	# Remove PCR duplicates
	
	# The following has been commented out because it currently looks like using
	# rmdup may actually hinder the detection of DIVs in this context. If this
	# is brought back, remember to add .rmdup to the filenames that follow.
# 	echo "Removing PCR duplicates from region_barcode.${i}.bam..."
# 	../sh/samtools_rmdup.sh \
# 		region_barcode.${i}.bam \
# 		region_barcode.${i}.rmdup.bam
# 	
# 	test_file region_barcode.${i}.rmdup.bam

	# Make variant calls, ending up with VCF
	
	echo "Converting region_barcode.${i}.rmdup.bam from BAM to MPG..."
	../sh/bam2mpg.sh \
		${REFERENCE} \
		region_barcode.${i}.bam \
		region_barcode.${i}.mpg.gz
	
	test_file region_barcode.${i}.mpg.gz
	
	
	
	echo "Converting MPG to SNV and DIV VCFs..."
	../sh/mpg2vcf.sh \
		region_barcode.${i} \
		${REFERENCE} \
		region_barcode.${i}.mpg.gz \
		region_barcode.${i}.snv.vcf.bgz \
		region_barcode.${i}.div.vcf.bgz
	
	test_file region_barcode.${i}.snv.vcf.bgz
	test_file region_barcode.${i}.div.vcf.bgz
		
	# Check if there are any DIVs at all.
	
	if 
		[ `gunzip -c region_barcode.${i}.div.vcf.bgz | wc -l` -gt 8 ]
	then
		
		echo "DIV detected in region_barcode.${i}.div.vcf.bgz."
		
		# If there IS a DIV, go back to region_barcode.${i}.bam. Select every
		# sequence that contains a "D" or "I" in the CIGAR, then use sort and
		# uniq -c to identify the most common sequence. 
		
		echo "Identifying the deletion with the most reads..."
		../sh/most_freq_div.sh \
			region_barcode.${i}.bam \
			region_barcode.${i}.freqdiv
		
		test_file region_barcode.${i}.freqdiv
		
		# Take a line containing this sequence and run it through sam2pairwise.
		# Print the sequence, which now contains the deletion, as well as the
		# target and barcode information.
		
		echo "Visualizing the DIV..."
		../sh/cigar_and_md_to_div.sh \
			region_barcode.${i}.freqdiv \
			${BASE}.id_div
		
		test_file ${BASE}.id_div
		
	else 
		
		echo "No DIV detected in region_barcode.${i}.div.vcf.bgz."
		
		# If there's not a DIV, print some indication that this combination of
		# target and barcode has no DIV.
		
		echo "Identifying the most frequent read..."
		../sh/most_freq_overall.sh region_barcode.${i}.bam ${BASE}.id_div
		
		test_file ${BASE}.id_div
		
	fi
		
done

echo "Loop finished."

# ${BASE}.id_div should now contain information for each region/barcode combo. 
# Add in the rest of the information from the barcode file and compress the
# output.

echo "Appending well and individual information to the deletion data..."
../sh/append_well_info.sh ${BARCODE_REF} ${BASE}.id_div ${BASE}.divs.gz

test_file ${BASE}.divs.gz



echo "Making output directory..."
mkdir $PWD/Output_${NAME}_${JOB_ID}

function move_file
{
 if 
   [ -e Output_${NAME}_${JOB_ID}/$1 ]
 then 
   throw_error "Can't move ${1}; a file with that name already exists in destination!"
 else  
   mv $1 Output_${NAME}_${JOB_ID}/ || throw_error "Didn't move ${1}!"
 fi
}

echo "Moving output file to Output directory..."
move_file ${BASE}.divs.gz
if [ ${LONGFRAGPRIMERS} ]; then move_file ${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.top10.gz; fi



echo "Moving the Output directory..."
if 
  [ -e ../Output_${NAME}_${JOB_ID} ]
then 
  throw_error "Can't move Output_${NAME}_${JOB_ID}; a file with that name already exists in parent directory!"
else  
  mv Output_${NAME}_${JOB_ID}/ .. || throw_error "Didn't move Output_${NAME}_${JOB_ID}!"
fi 



echo ""
echo "$0 finished!"

exit
