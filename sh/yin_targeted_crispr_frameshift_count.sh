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

function full_path ()
{
	DIR=`dirname $1`
	FILE=`basename $1`
	PATH="`cd \"$DIR\" 2>/dev/null && pwd -P || echo \"$DIR\"`/$FILE"
	echo $PATH
}


source ~/.bashrc

print_usage()
{
  cat <<EOF
Usage: yin_targeted_crispr_frameshift.sh [options] (-b <_bamnumbers> | -c <barcodes>) -n <_names> -r <_ranges>
Note that this script must be run within the 'Workdir' directory produced by 
ampliconDIVider_driver.sh. 
	Options:
	-b	the _bamnumbers file (required if not defining the barcode file)
	-c	the barcode file (required if not defining the _bamnumbers file)
	-h	print this help message and exit
	-n	the _names file (required)
	-r	the _ranges file (required)
EOF
}


# FOUNDERTARGET is the "_names" file, and contains lines like:
# tyr_chr15_42572556-42572836_Founder01
# RANGES is the "_ranges" file, and contains lines like:
# tyr_chr15_42572556-42572836	129	168
# SAMPLEBAMNUMBERS is the "_bamnumbers" file, and contains lines like:
# insra_chr2_37298662-37298953_Founder04	Plate1	D1	insra_chr2_37298662-37298953	Founder04	0	TTCTAG	34

while getopts "b:c:hn:r:" OPTION
do
	case $OPTION in
    	b)
    		SAMPLEBAMNUMBERS=`full_path $OPTARG`
    		;;
    	c)
    		BARCODE_PATH=`full_path $OPTARG`
    		;;
    	h)
    		print_usage
    		exit 0
    		;;
    	n)
    		FOUNDERTARGET=`full_path $OPTARG`
			;;
    	r)
    		RANGES=`full_path $OPTARG`
			;;
    esac
done
shift $((OPTIND-1))

ID=`date +"%s"`


# If the bamnumbers file was not provided, generate it from the barcode file
# and the list of BAM files.

if [ ! ${SAMPLEBAMNUMBERS} ]
then
	
	echo "No bamnumbers file detected; generating automatically..."
	
	test_file $BARCODE_PATH
	
	# As this script must be run in the ampliconDIVider working directory, the
	# relevant BAM files are in the same location at this part of the script.
	
	TOTALBAMS=`ls region_barcode.*.bam | wc -l`
	
	# Create the file that associates the sample with the BAM number
	
	i=0
	
	while [[ $i -lt ${TOTALBAMS} ]]
	do
		i=$(( $i + 1 ))
		samtools view region_barcode.${i}.bam \
			| head -1 \
			| cut -f3,20 \
			| awk -v OFS="\t" -v i="$i" '{print i,$1"_"substr($2,6,6)}'
	done \
	| sort -k2,2 \
	> bamnumber_ids_${ID}
	
	# Use the barcode file to generate the bamnumbers file
	
	BARCODE_FILE=`basename ${BARCODE_PATH}`
	
	awk -v OFS="\t" '{ print $3"_"$6,$3"_"$4,$0 }' ${BARCODE_PATH} \
		| sort -k1,1 \
		| join -1 1 -2 2 - bamnumber_ids_${ID} \
		| tr ' ' "\t" \
		| cut -f2- \
		| sort -k1,1 \
		> ${BARCODE_FILE}_bamnumbers
	
	SAMPLEBAMNUMBERS=`full_path ${BARCODE_FILE}_bamnumbers`
	
	rm bamnumber_ids_${ID}
fi




test_file $SAMPLEBAMNUMBERS
test_file $FOUNDERTARGET
test_file $RANGES


# Identify the name of the element in question

TARGET=`head -1 $FOUNDERTARGET | cut -d_ -f1`


# Make the working directory

mkdir Frameshifts_${TARGET}_${ID}
cd Frameshifts_${TARGET}_${ID}


# Set up the header of the summary file

echo -e "target\tfounder\ttotal_reads\tno_crispr_DIV\tinframe_variant_reads\tframeshift_variant_reads\tmutation_rate\tinframe_rate\tframeshift_rate" > frameshift_summary_${TARGET}


for LINE in `cat $FOUNDERTARGET `
do
	
	# For each sample, identify all BAM files that came from the same target
	# and the same fish. The $6 ~ /^G|0/ is shorthand for BAMs from somatic
	# samples, based on the notation I used. In the Chen experiment, each fish
	# represents a single sample, so this step should only grab a single BAM.
	
	FOUNDER=`echo $LINE | cut -d_ -f4`
	
	echo "Assessing ${FOUNDER}..."
	
	awk -v TARGET="${TARGET}" \
		-v FOUNDER="${FOUNDER}" \
		'match($4, "^"TARGET) && $5 == FOUNDER && $6 ~ /^G|0/' $SAMPLEBAMNUMBERS \
		> ${SAMPLEBAMNUMBERS}_${TARGET}_${FOUNDER}

	
	# Record the left and right bound of the range considered close enough to
	# the CRISPR target to be a variant induced by the CRISPR
	
	LEFT=`grep $TARGET $RANGES | cut -f2 `
	
	RIGHT=`grep $TARGET $RANGES | cut -f3`
	
	
	for i in `cat ${SAMPLEBAMNUMBERS}_${TARGET}_${FOUNDER} | cut -f8`
	do
		
		# For each BAM file associated with this fish (again, there should only
		# be one for the Chen experiment), identify the mutations in range of
		# the CRISPR target(s). The last awk statement in the first block sets
		# the stage to split the mutations into frameshifts vs. non-frameshifts.

		samtools view ../region_barcode.${i}.bam \
		| awk '$6 ~ /[DI]/' \
		| ../../perl/sam_all_div_linebreak.pl \
		| awk -F_ '{if($1 == "###"){print}else{print $0"\t"$2"\t"$2+($3-1)}}' \
		| awk -v LEFT="${LEFT}" -v RIGHT="${RIGHT}" '($3 >= LEFT && $3 <= RIGHT) || ($2 >= LEFT && $2 <= RIGHT) {print} $1 == "###" {print}' \
		| cut -f1 \
		| awk '{if($1 == "###"){if(out){print s"\t"out; out=""; delete a; s=0}}else{out=out$1"\t"; if(/^D/){split($0,a,"_"); s -= a[3]};if(/^I/){split($0,a,"_"); s += a[3]} }}END{if(out){print s"\t"out}}' \
		| awk '{ if($1%3){print "y\t"$0}else{print "n\t"$0} }' \
		> in-range-mutant-reads_${TARGET}_${FOUNDER}
	
		cut -f1 in-range-mutant-reads_${TARGET}_${FOUNDER} \
		| sort \
		| uniq -c \
		> fs_sums_${TARGET}_${FOUNDER}
		
		# Identify the number of mutations with and without a frameshift
		
		NOSHIFT=`head -1 fs_sums_${TARGET}_${FOUNDER} | awk '{print $1}'`
	
		YESSHIFT=`tail -1 fs_sums_${TARGET}_${FOUNDER} | awk '{print $1}'`

		# Count the number of total reads in the relevant BAM, and print a
		# summary line indicating total reads, reads without a variant near the
		# CRISPR site, inframe & frameshift variant reads, and calculations of
		# the overall mutation rate, the inframe rate, and the frameshift rate.
		
		samtools view ../region_barcode.${i}.bam \
		| wc -l \
		| awk -v target="$TARGET" \
		-v founder="$FOUNDER" \
		-v noshift="$NOSHIFT" \
		-v yesshift="$YESSHIFT" \
		-v OFS="\t" \
		'{print target,founder,$1,$1-(noshift+yesshift),noshift,yesshift,(noshift+yesshift)/$1,noshift/$1,yesshift/$1}' \
		>> frameshift_summary_${TARGET}
	
		rm fs_sums_${TARGET}_${FOUNDER}
	
	done
	
	rm ${SAMPLEBAMNUMBERS}_${TARGET}_${FOUNDER}
	
done


echo ""
echo "Finished."
exit 0
