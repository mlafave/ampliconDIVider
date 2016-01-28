ampliconDIVider
============

ampliconDIVider contains the scripts used to identify deletion and insertion
variants (DIVs) in DNA amplicons, as presented in "High-Throughput Gene
Targeting and Phenotyping in Zebrafish Using CRISPR/Cas9" by Varshney et al.
(http://dx.doi.org/10.1101/gr.186379.114). It tests each sample for DIVs, and if at least one is detected,
the most frequent DIV-containing sequence is presented as a pairwise alignment. 


Requirements
------------

ampliconDIVider is designed to run on Linux. It can also run on OS X, but
please be aware that it wasn't primarily intended to do so.

The following programs must be in a directory in your $PATH, with the version
at least as recent as those listed here:

* Perl v.5.8.8
* cutadapt v.1.3 (https://github.com/marcelm/cutadapt/)
* novoalign v.3.02.07 (http://www.novocraft.com/support/download/)
* bam2mpg and mpg2vcf.pl (available from http://research.nhgri.nih.gov/software/bam2mpg/, or directly from https://github.com/nhansen/bam2mpg. It may be necessary to set $PERL5LIB to the lib/ directory within the bam2mpg/ directory, and export.) 
* sam2pairwise v.1.0.0 (available from http://www.github.com/mlafave/sam2pairwise)
* samtools v.0.1.19-44428cd (http://www.htslib.org/ for more recent versions)
* bamtools v.2.3.0 (https://github.com/pezmaster31/bamtools)
* bgzip

ampliconDIVider_driver.sh uses relative paths to call sub-scripts, so the
program should be run from in the ampliconDIVider/ directory.

In addition, the input BAM file should contain paired-end reads. The BAM files
used in the Varshney et al. paper are available from the NCBI Sequence Read
Archive (http://www.ncbi.nlm.nih.gov/sra), under BioProject accession
PRJNA262180. The rest of the input files are included in the
`Varshney_et_al_input` directory.


Usage
-------

	ampliconDIVider_driver.sh [options] input.bam

Options:

`-b`:  barcode file (required): This file indicates the relationship between,
plate, well, amplicon, founder, progeny ID, and 6 bp barcode. It has the
following format:
	
	plate01	A01	cecr1a_T1_25_17051437-17051625	1M	1	AAAAAA
	plate02	A01	cecr1a_T2_25_17051701-17051898	1M	1	AAAAAA
	plate03	A01	cecr1b_T2_4_5106979-5107305	1M	1	AAAAAA

The first two columns show the placement of each sample in a plate. The third
column indicates both the name of the target amplicon and the position of the
amplicon using 1-based values, but without using the colon character. The
fourth column contains the ID of the founder in which the CRISPR cut, and the
firth column is used to distinguish between the progeny of that founder. The
sixth column are the six bases of the barcode, written from 5' to 3'.

`-f`:  Reference FASTA file (required): A FASTA file containing the sequence of
the amplicons of interest. This should be the same file used to create the
index for the aligner. If some of the target amplicons are nested within
others, it's better to not include the larger of the two. For example, if you
have amplicons from position 100 to 200, 600 to 700, and 100 to 700, then the
one from 100 to 700 should not be included in this file or the aligner index,
or it may cause alignment difficulites for the shorter amplicons. The
hypothetical 100 to 700 sample can instead be monitored by using the `-p`
option.

`-h`:  Print a help message with this list of options and exit

`-l`:  Calculate the read length from the first entry of the BAM file, and
calculate the mean & standard deviation of fragment length from the third
column of the barcode file specified via -b. This flag is optional; if it isn't
used, the values used in Varshney et al. are assigned (defaults: read length =
300, mean fragment length = 309, fragment length standard deviation = 1259)

`-n`:  Name: Add a name (without spaces) to be used in the working directory
and output files. If this option is not provided, "target" is used as the
default.

`-p`:  Primers of long fragments: If this option is used, the program will use
the corresponding file to identify fragments that have the indicated primers
pairs at the start of both paired reads, but which don't neccessarily
constitute "proper pairs". Useful for identifying fragments with deletions so
large they fail to be mapped by the aligner. It has the following format:
	
	cecr1a_T1F/T2R_25:17051437-17051898	GTTTCAGTGGATTGGCTGGT	GCAGTGCTCTGATCTCCACA
	man2a1_T2F/T1R_5:58517329-58543258	AGCTCCTACTGTGTTTGACTGC	TGCATGCAGTTTCATGTTGA
	man2b1_T2F/T1R_11:32098232-32100164	CTCAAGAAAATGCAGGTTTGC	ATCCAGCATGCAGGTGTTC
	
The first column is the amplicon ID. This can be written the same way as the
third column in `-b`, but it doesn't need to be (for example, colons are
allowed). The second and third columns are the sequences of the primers used
for the "long" version of the amplicon, written 5' to 3'.

`-r`:  Ranges file: a file indicating the subset of the read in which DIVs are
of most interest. While all samples that have a DIV at any point will be
reported in the normal `${BASE}.divs.gz` output file, specifying this option
will result in an additional output file called `${BASE}.range.div.table.gz`.
The format of the file specified by `-r` is a tab-delimited file containing the
target ID identical to the third column of the barcode file, followed by the
1-based start and end of the portion of interest in the fragment:
	
	cecr1a_T1_25_17051437-17051625	121	180
	cecr1a_T2_25_17051701-17051898	67	126
	cecr1b_T2_4_5106979-5107305	117	176

`-v`:  Print the version number and quit.

`-x`:  Path to alignment index (required): Either an absolute or relative path
to the aligner index file. The index itself can be created by using novoindex
and the FASTA file used for option `-f`:

	novoindex set1_amplicons.nix ~/path/to/ampliconDIVider/Varshney_et_al_input/set1_amplicons.fa


Output
-------

The default final output is `${BASE}.divs.gz`, where BASE is the basename of
the BAM input. This file is located in the `Output_${NAME}_${JOB_ID}`
directory, where NAME is the value from -n, and JOB_ID is present if the job
were submitted via `qsub`. Each sample (where a sample is defined as a unique
combination of target name, founder ID, progeny ID, and barcode) is
represented. If the bam2mpg/mpg2vcf variant caller identified a DIV in a
sample, ampliconDIVider finds the most frequently represented DIV-contaning
sequence. A read matching this sequence is then printed as a pairwise
alignment, with the read on the top and the reference on the bottom. If no DIV
was detected by the variant caller, this is reported in a way that maintains
the four-line periodicity of the output.
For example, a DIV-containing sample would look like this:

	Plate1  D1      CochT1_chr17_28807187-28807424  1F      4       TTCTAG
	CTGAACACCATGAGCGTAAGAGCTGAGGTAGTTTGTCCTCCCTTGCAGTCCGTGA-----------------------ACCTATGATTCCTCTGGATGAAAGACAAACGTTTCCTTGTTATTGGAGTCTAGCAAGTCTGCAACTGTATCGTTTAAAGTGAAAACTGTACCTGTGAATGGCTGCTCCGCATATGCTGGAAATAGAGGCATAAACTCCAGAACCAAACACTGAGAGGCTC
	|||||||||||||||||||||||||||||||||||||||||||||||||||||||                       ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	CTGAACACCATGAGCGTAAGAGCTGAGGTAGTTTGTCCTCCCTTGCAGTCCGTGAACCTCCACTGGTCCACCAGACAGACCTATGATTCCTCTGGATGAAAGACAAACGTTTCCTTGTTATTGGAGTCTAGCAAGTCTGCAACTGTATCGTTTAAAGTGAAAACTGTACCTGTGAATGGCTGCTCCGCATATGCTGGAAATAGAGGCATAAACTCCAGAACCAAACACTGAGAGGCTC

A sample without a DIV would look like this:

	Plate1  D2      CochT1_chr17_28807187-28807424  3F      4       TTCTTC
	CTGAACACCATGAGCGTAAGAGCTGAGGTAGTTTGTCCTCCCTTGCAGTCCGTGAACCTCCACTGGTCCACCAGACAGACCTATGATTCCTCTGGATGAAAGACAAACGTTTCCTTGTTATTGGAGTCTAGCAAGTCTGCAACTGTATCGTTTAAAGTGAAAACTGTACCTGTGAATGGCTGCTCCGCATATGCTGGAAATAGAGGCATAAACTCCAGAACCAAACACTGAGAGGCTCAAAGATCGGAAGAGCACACGTCTGAACTCCAGTCACAA
	no_div
	no_div

If the `-p` option was used, the output directory will also contain a file
called `${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.top10.gz`. The
file has three columns: the number of times that entry appeared for a given
amplicon, the ID of the amplicon from the first column of the `-p` file, and a
sequence that matches the sequences from the second and third column of the
`-p` file. Although the reads will be written 5’ to 3’, they are not
necessarily all from the “forward” strand. Only the 10 most frequent sequences
for each target are displayed.

If the `-r` option was used, the output directory will contain a file called
`${BASE}.range.div.table.gz`. This file combines the information in the barcode
file with data about DIVs that fell in the range of interest. It has nine
columns: plate, well, amplicon, founder, progeny ID, 6 bp barcode, group number
(the integer internally assigned to represent the combination of barcode and
target), a one-character description of the type of DIV detected (D = deletion;
I = insertion; C = complex, or a combination of a deletion and an insertion
that each fall anywhere within the specified range), and the description of all
DIVs that overlap the specified range. Each DIV is represented by the
one-character tag, the one-based position at which the DIV begins, and the
length of the DIV. If there were multiple DIVs in the range, they are delimited
by `::`.

In addition, most of the intermediate files are kept in the
`Workdir_${NAME}_${JOB_ID}` directory. These can be useful for viewing the
reads within a given sample, or checking the evidence for a variant call. Each
unique combination of target region and barcode is assigned an integer (stored
internally as `${i}`), which appears in the name of each file:

* `region_barcode.${i}.bam`: All reads that aligned to the specified target
with the specified barcode. All reads in these files should be properly paired.
* `region_barcode.${i}.mpg.gz`: The Most Probable Genotype scores for the
sample. These scores are used to infer which variants are called.
* `region_barcode.${i}.snv.vcf.bgz`: The single nucleotide variants, in variant
call format.
* `region_barcode.${i}.div.vcf.bgz`: The deletion and insertion variants, in
variant call format.
* `region_barcode.${i}.freqdiv`: If the sample had any variants called in
`region_barcode.${i}.div.vcf.bgz`, this file contains the most
frequently-occurring DIV-containing read, in headerless SAM format.

Note that the variant caller, bam2mpg, is not deterministic for samples with a
high read count, so multiple runs of the same input may result in slightly
different results.


Testing ampliconDIVider
-----------------------

To test the program, first create a novoalign index to
`Varshney_et_al_input/set1_amplicons.fa`, as described above. Then, run the
following command from within the ampliconDIVider/ directory:

	./ampliconDIVider_driver.sh -l -b Varshney_et_al_input/set1_barcodes -n example -p Varshney_et_al_input/set1_long_fragments -r Varshney_et_al_input/set1_ranges -f Varshney_et_al_input/set1_amplicons.fa -x ~/path/to/set1_amplicons.nix example.bam
	
The output should be the same as the files in the Example_output/ directory.


Somatic samples
---------------

ampliconDIVider is designed to work on heterozygous germline samples
(specifically, sequencing the F1 progeny of mutagenized founders), and to
report the single best-supported variant combination from each sample. However,
it is possible to use the program to assess the mutation rate in the somatic
tissue of the founder itself, e.g. Yin et al. 2015
(http://dx.doi.org/10.1534/genetics.115.176917). To do so, use the
`yin_targeted_crispr_frameshift_count.sh` script located in the
`ampliconDIVider/sh/` directory. Usage is as follows:

	../sh/yin_targeted_crispr_frameshift_count.sh [options] (-b <_bamnumbers> | -c <barcodes>) -n <_names> -r <_ranges>

Options:

`-b`:  The "bamnumbers" file (required if not providing a barcode file): Each
`region_barcode.*.bam` file is assigned an integer, and the bamnumbers file
associates that integer with a unique identifier for the sample in the well.
This option is included for backwards compatability, as the most
straightforward solution is to use the `-c` option and generate this file
automatically. The format of the bamnumbers file is:
	
	insra_chr2_37298662-37298953_Founder01	Plate1	A1	insra_chr2_37298662-37298953	Founder01	0	AAAAAA	1
	insra_chr2_37298662-37298953_Founder02	Plate1	B1	insra_chr2_37298662-37298953	Founder02	0	ATCCTA	10
	insra_chr2_37298662-37298953_Founder03	Plate1	C1	insra_chr2_37298662-37298953	Founder03	0	TAACTC	25

The first column is a unique ID created by combining the fourth and fifth
columns. The second through seventh columns are the same format as the barcode
file described above, with one additional requirement: when analyzing somatic
samples, the sixth column must either be set to 0 (recommended) or begin with a
capital G. The eighth column is the "bam number" itself: the integer that
ampliconDIVider assigned to the BAM file that corresponds to this sample.	

`-c`: The barcode file (required if not defining the _bamnumbers file). This
is the same file you used for the ampliconDIVider `-b` option.
	
`-h`:  Print a help message with this list of options and exit

`-n`:  The `_name` file (required). This file contains the unique identifier
for each sample of a SINGLE target. For example, the provided `yin_bamnumbers`
file has three targets (`insra_chr2_37298662-37298953`,
`insrb_chr22_11114676-11114957`, `tyr_chr15_42572556-42572836`), each of which
have multiple samples. There are therefore three `_names` files that represent
each sample for one of the three names:

	insrb_chr22_11114676-11114957_Founder01
	insrb_chr22_11114676-11114957_Founder02
	insrb_chr22_11114676-11114957_Founder03

A straightforward way to generate these files on the command line is to use awk
to retrieve and edit the relevant lines from the barcode file. In the example
above, the insrb `_name` file can be made by applying 
`awk '$3 ~ /^insrb/ {print $3"_"$4}'` to the barcode file. To make other files,
replace "insrb" with the unique portion of the beginning of the target name for
your target of interest (insra and tyr in the above example).

`-r`:  The _ranges file (required). This is identical to the file used for
the ampliconDIVider `-r` option.

Other notes:
This script relies on a hard-coded paths to locate other relevant scripts and
files. As such, it must be run from within the `Workdir_...` directory created
by ampliconDIVider. It operates on `region_barcode.*.bam` files; if all of these
files have been created (for example, if the script has begun to produce mpg
files), then ampliconDIVider can be safely stopped.


Somatic sample output:

`yin_targeted_crispr_frameshift_count.sh` will create an output directory
within the directory in which it is run. The name of the output directory is
`Frameshifts_${TARGET}_${ID}`, in which `${TARGET}` is the portion of the
target name preceeding the first underscore, and `${ID}` is the Unix time in
seconds (to prevent separate runs of identical targets from overwriting each
other).

Each sample has a file that represents the various combinations of mutations
detected therein, and whether they induced a frameshift mutation. Only variants
within the distance specified in the `_ranges` file are indicated. Note that
each variant may be represented multiple times. The files contain three columns:

	y	-38	D_140_7	D_151_31	
	y	-1	D_152_1	
	n	3	I_149_3	

The first column indicates if the total number of bases changed by the variant
are not divisible by 3, and therefore represent a frameshift. The second column
indicates the total base change, and the third column indicates the variants as
`type_position_length`; D is for deletion, and I is for insertion.

For an overview of the mutation rate and frameshift rate in each sample, there
is also a `frameshift_summary_${TARGET}` file:

	target	founder	total_reads	no_crispr_DIV	inframe_variant_reads	frameshift_variant_reads	mutation_rate	inframe_rate	frameshift_rate
	tyr	Founder01	322	160	36	126	0.503106	0.111801	0.391304
	tyr	Founder02	536	297	58	181	0.445896	0.108209	0.337687
	tyr	Founder03	312	136	48	128	0.564103	0.153846	0.410256

Mutation rate is presented here by counting the number of reads that have a
mutation versus all reads for that sample. It is important to note that this
analysis carries with it the implicit assumption that both paired-end reads are
long enough to cover a given variant. Some of the column names are
self-explanatory, but for those that are not:

* `founder`: The ID of the DNA source material used in the assay, such as the
ID of the individual in which the CRISPR (or other mutagen) created the
mutations. It does not necessarily imply that this individual had any progeny.
* `no_crispr_DIV`: The number of reads that lacked a deletion or insertion
variant within the range defined by the `_ranges` file. 
* `mutation_rate`: The number of deletion- or insertion-containing reads
(within the range defined by the `_ranges` file), divided by the total number
of reads. Though influenced by the number of cell divisions that occurred after
the mutation, this value gives an approximation of 
* `inframe_rate`: The percentage of reads with in-frame variants (based on the
sum of those in the region defined by `_ranges`) versus the total number of
reads.
* `frameshift_rate`: Like the inframe rate, only for frameshift mutations.
`inframe_rate` and `frameshift_rate` should therefore sum to the
`mutation_rate`.

Citation
--------

If you use ampliconDIVider in your work, please use the following reference to cite it:

Varshney GK, Pei W, LaFave MC, Idol J, Xu L, Gallardo V, Carrington B, Bishop K, Jones M, Li M, Harper U, Chen W, Sood R, Ledin J, and Burgess SM. High-Throughput Gene Targeting and Phenotyping in Zebrafish Using CRISPR/Cas9. Genome Res. 2015 Jul;25(7):1030-42


Contact
-------

Matthew C. LaFave, Ph.D.

Email: matt.lafave [at sign] gmail.com

