#!/usr/bin/env bash

# Email address, and options, to whom reports should be sent.
# The -M is for the address, the -m is for when to send email.
# a=abort b=begin e=end s=suspend n=none
#$ -M matthew.lafave@nih.gov
#$ -m abes

# Redirect the STDOUT and STDERR files to the jobs directory
#$ -o $HOME/jobs/$JOB_ID_$JOB_NAME.stdout
#$ -e $HOME/jobs/$JOB_ID_$JOB_NAME.error

# Operate in the current directory
#$ -cwd


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

# Get files via CLI
print_usage()
{
  cat <<EOF
Usage: target_seq_driver.sh [options] input.bam
	Options:
	-b	barcode file (required)
	-h	print this help message and exit
	-n	name	
	-x	path to alignment index (required)
EOF
}

NAME="target"
while getopts "b:hn:x:" OPTION
do
	case $OPTION in
    	b)
    		BARCODE_REF=$OPTARG
    		;;
    	h)
    		print_usage
    		exit 0
    		;;
    	n)
    		NAME=$OPTARG
    		;;
    	x)
    		INDEX=$OPTARG
    		;;
    esac
done
shift $((OPTIND-1))
INBAM=$1

DIR=`dirname $INBAM`
FILE=`basename $INBAM`
BAMPATH="`cd \"$DIR\" 2>/dev/null && pwd -P || echo \"$DIR\"`/$FILE"

BASE=`echo $FILE | sed 's/\(.*\).bam$/\1/'`

### Needs some means of checking to make sure BARCODE_REF, INDEX, and INBAM are
### defined.


# Verify that the name does not have blanks
echo $NAME | grep -q [[:blank:]] && throw_error "'NAME' can't have blanks"


# Make a working directory

WORKDIR=$PWD/Workdir_${NAME}_$JOB_ID

if [ -d $WORKDIR ] ; then throw_error "$WORKDIR already exists!"; fi

mkdir $WORKDIR
cd $WORKDIR

# Adjust for relative paths
INDEX=`echo $INDEX | awk '{ if($1 ~ /^\//){print}else{print "../"$1} }'`

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

### I'll need to see how novoalign deals with index basenames

# The barcode file should be reasonably small, so I'll make a local copy in the
# working directory. That way, there's no need to worry if the main file is
# altered or moved in the meantime.

cp ../${BARCODE_REF} .

test_file $BARCODE_REF

### That won't work if a path is used - may need to fix that later





################################################################################

# General outline for identifying CRISPR-induced mutations via high-throughput 
# targeted resequencing

# Prior to any of this, make an index of the amplified regions.

# Remove PCR duplicates from input BAM file

echo "Removing PCR duplicates..."
../sh/samtools_rmdup.sh $BAMPATH ${BASE}.rmdup.bam

test_file ${BASE}.rmdup.bam



# Convert input BAM to FASTQ or FASTA
# FASTA	might be nice if there are further reads to reduce, but FASTQ is
# going to be better for mapping, especially if I use Novoalign.

echo "Converting to FASTQ..."

../sh/bamtools_bamtofastq.sh ${BASE}.rmdup.bam ${BASE}.rmdup.fastq.gz

test_file ${BASE}.rmdup.fastq.gz



# Trim off & discard pigtail sequences

echo "Trimming pigtail..."
../sh/cutadapt_pigtailtrim.sh ${BASE}.rmdup.fastq.gz \
	${BASE}.rmdup.pigtailtrim.fastq.gz

test_file ${BASE}.rmdup.pigtailtrim.fastq.gz



# Trim off the barcodes in such a way that the fragment name is recorded &
# associated with the barcode. 
# The fragment will be barcode, then M13, then nothing but genomic.
# The easiest way to do this is by trimming the M13 and looking for wildcards.


# Trim off the M13 sequence

echo "Trimming M13 sequence and recording barcode..."

../sh/cutadapt_m13trim.sh ${BASE}.rmdup.pigtailtrim.fastq.gz \
	${BASE} \
	${BASE}.rmdup.fulltrim.fastq.gz

test_file ${BASE}.rmdup.fulltrim.fastq.gz
test_file ${BASE}.bcR
test_file ${BASE}.bcL



# Remove reads for which the barcodes do not agree

echo "Identifying reads for which the barcodes do not agree, to be removed later..."

../perl/compare_barcodes.pl ${BASE}.bcL ${BASE}.bcR \
	| sort | gzip -c > ${BASE}.bc.agree.gz

test_file ${BASE}.bc.agree.gz

# (Better zip up the original bcR and bcL files if you want to keep them -
# otherwise, delete them)

# Remove reads for which the barcode is not on the list of accepted barcodes

echo "Identifying fragments with incorrect barcodes, to be removed later..."

../sh/barcode_whitelist_compare.sh ${BARCODE_REF} ${BASE}.bc.agree.gz \
	${BASE}.bc.listpass.gz

test_file ${BASE}.bc.listpass.gz



# Remove the reads that don't have a paired read

echo "Extracting basenames of paired reads from trimmed FASTQ..."
../sh/fastq_paired_basenames.sh ${BASE}.rmdup.fulltrim.fastq.gz \
	${BASE}.rmdup.fulltrim.pairednames

test_file ${BASE}.rmdup.fulltrim.pairednames


echo "Identifying correct & non-inconsistent barcodes that belong to paired reads..."
../sh/barcode_paired.sh ${BASE}.bc.listpass.gz \
	${BASE}.rmdup.fulltrim.pairednames ${BASE}.bc.listpass.paired

test_file ${BASE}.bc.listpass.paired

rm ${BASE}.rmdup.fulltrim.pairednames


echo "Removing FASTQ reads that don't have a pair, or which don't have acceptable, consistent barcodes..."
../sh/fastq_paired_passbc.sh ${BASE}.rmdup.fulltrim.fastq.gz \
	${BASE}.bc.listpass.paired ${BASE}.rmdup.fulltrim.passbc.fastq.gz

test_file ${BASE}.rmdup.fulltrim.passbc.fastq.gz


echo "Compressing the paired barcode file..."
gzip ${BASE}.bc.listpass.paired

test_file ${BASE}.bc.listpass.paired.gz



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



	
	

exit
