ampliconDIVider
============

ampliconDIVider contains the scripts used to identify deletion and insertion variants (DIVs) in DNA amplicons, as presented in "High-Throughput Gene Targeting and Phenotyping in Zebrafish Using CRISPR/Cas9" by Varshney et al. (Submitted). It tests each sample for DIVs, and if at least one is detected, the most frequent DIV-containing sequence is presented as a pairwise alignment. 


Requirements
------------

ampliconDIVider is designed to run on Linux. It can also run on OS X, but please be aware that it wasn't primarily intended to do so.

The following programs must be in a directory in your $PATH, with the version at least as recent as those listed here:
* Perl v.5.8.8
* cutadapt v.1.3
* novoalign v.3.02.07
* bam2mpg and mpg2vcf.pl (available from http://research.nhgri.nih.gov/software/bam2mpg/. It may be necessary to set $PERL5LIB to the lib/ directory within the bam2mpg/ directory.) 
* sam2pairwise v.1.0.0 (available from http://www.github.com/mlafave/sam2pairwise)
* samtools v.0.1.19-44428cd
* bamtools v.2.3.0
* bgzip

ampliconDIVider_driver.sh uses relative paths to call sub-scripts, so the program should be run from in the ampliconDIVider/ directory.

In addition, the input BAM file should contain paired-end reads. The BAM files used in the paper are available from the NCBI Sequence Read Archive (http://www.ncbi.nlm.nih.gov/sra), under BioProject accession PRJNA262180. The rest of the input files are included in the `Varshney_et_al_input` directory.


Usage
-------

	ampliconDIVider_driver.sh [options] input.bam

Options:
-b	barcode file (required): This file indicates the relationship between, plate, well, amplicon, founder, progeny ID, and 6 bp barcode. It has the following format:
	
	Plate1	A1	CochT1_chr17_28807187-28807424	1F	1	AAAAAA
	Plate10	A1	DFNA5T2_chr16_23514121-23514392	1F	1	AAAAAA
	Plate11	A1	myo3AT1_chr24_6309161-6309391	1F	1	AAAAAA

The first two columns show the placement of each sample in a plate. The third column indicates both the name of the target amplicon and the position of the amplicon using 1-based values, but without using the colon character. The fourth column contains the ID of the founder in which the CRISPR cut, and the firth column is used to distinguish between the progeny of that founder. The sixth column are the six bases of the barcode, written from 5' to 3'.

-h	print a help message with this list of options and exit

-l	calculate the read length from the first entry of the BAM file, and calculate the mean & standard deviation of fragment length from the third column of the barcode file specified via -b. This flag is optional; if it isn't used, the values used in Varshney et al. are assigned (defaults: read length = 300, mean fragment length = 309, fragment length standard deviation = 1259)

-n	name: Add a name (without spaces) to be used in the working directory and output files. If this option is not provided, "target" is used as the default.

-p	primers of long fragments: If this option is used, the program will use the corresponding file to identify fragments that have the indicated primers pairs at the start of both paired reads, but which don't neccessarily constitute "proper pairs". Useful for identifying fragments with deletions so large they are fail to be mapped by the aligner. It has the following format:
	
	cecr1a_T1F/T2R_25:17051437-17051898	GTTTCAGTGGATTGGCTGGT	GCAGTGCTCTGATCTCCACA
	man2a1_T2F/T1R_5:58517329-58543258	AGCTCCTACTGTGTTTGACTGC	TGCATGCAGTTTCATGTTGA
	man2b1_T2F/T1R_11:32098232-32100164	CTCAAGAAAATGCAGGTTTGC	ATCCAGCATGCAGGTGTTC
	
The first column is the amplicon ID. This can be written the same way as the third column in `-b`, but it doesn't need to be (for example, colons are allowed). The second and third columns are the sequences of the primers used for the "long" version of the amplicon, written 5' to 3'.

-r	reference FASTA file (required): A FASTA file containing the sequence of the amplicons of interest. This should be the same file used to create the index for the aligner. If some of the target amplicons are nested within others, it's better to not include the larger of the two. For example, if you have amplicons from position 100 to 200, 600 to 700, and 100 to 700, then the one from 100 to 700 should not be included in this file or the aligner index, or it may cause alignment difficulites for the shorter amplicons. The hypothetical 100 to 700 sample can instead be monitored by using the `-p` option.

-x	path to alignment index (required): Either an absolute or relative path to the aligner index file. The index itself can be created by using novoindex and the FASTA file used for option `-f`:

	novoindex set1_amplicons.nix ~/path/to/ampliconDIVider/Varshney_et_al_input/set1_amplicons.fa


Output
-------

The default final output is `${BASE}.divs.gz`, where BASE is the basename of the BAM input. This file is located in the `Output_${NAME}_${JOB_ID}` directory, where NAME is the value from -n, and JOB_ID is present if the job were submitted via `qsub`. Each sample (where a sample is defined as a unique combination of target name, founder ID, progeny ID, and barcode) is represented. If the bam2mpg/mpg2vcf variant caller identified a DIV in a sample, ampliconDIVider finds the most frequently represented DIV-contaning sequence. A read matching this sequence is then printed as a pairwise alignment, with the read on the top and the reference on the bottom. If no DIV was detected by the variant caller, this is reported in a way that maintains the four-line periodicity of the output.
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

If the `-p` option was used, the output directory will also contain a file called `${BASE}.fulltrim.passbc.detectedlongfrag.${SHORTPRIMER}.top10.gz`. The file has three columns: the number of times that entry appeared for a given amplicon, the ID of the amplicon from the first column of the `-p` file, and a sequence that matches the sequences from the second and third column of the `-p` file. Although the reads will be written 5’ to 3’, they are not necessarily all from the “forward” strand. Only the 10 most frequent sequences for each target are displayed.

In addition, most of the intermediate files are kept in the `Workdir_${NAME}_${JOB_ID}` directory. These can be useful for viewing the reads within a given sample, or checking the evidence for a variant call. Each unique combination of target region and barcode is assigned an integer (stored internally as `${i}`), which appears in the name of each file:

* `region_barcode.${i}.bam`: All reads that aligned to the specified target with the specified barcode. All reads in these files should be properly paired.
* `region_barcode.${i}.mpg.gz`: The Most Probable Genotype scores for the sample. These scores are used to infer which variants are called.
* `region_barcode.${i}.snv.vcf.bgz`: The single nucleotide variants, in variant call format.
* `region_barcode.${i}.div.vcf.bgz`: The deletion and insertion variants, in variant call format.
* `region_barcode.${i}.freqdiv`: If the sample had any variants called in `region_barcode.${i}.div.vcf.bgz`, this file contains the most frequently-occurring DIV-containing read, in headerless SAM format.

Note that the variant caller, bam2mpg, is not deterministic for samples with a high read count, so multiple runs of the same input may result in slightly different results.


Testing ampliconDIVider
-----------------------

To test the program, first create a novoalign index to `Varshney_et_al_input/set1_amplicons.fa`, as described above. Then, run the following command from within the ampliconDIVider/ directory:

	./ampliconDIVider_driver.sh -b Varshney_et_al_input/set1_barcodes -n example -p Varshney_et_al_input/set1_long_fragments -r Varshney_et_al_input/set1_amplicons.fa -x ~/path/to/set1_amplicons.nix example.bam
	
The output should be the same as the files in the Example_output/ directory.


License
-------

ampliconDIVider is licensed under the MIT license. In addition, as a work created at the National Institutes of Health, it carries the following notice:
 
This software/database is either a United States Government Work or was made under contract for the United States Government. In either case the public may use the software/database on a worldwide and royalty-free basis for any purpose and may reproduce and prepare derivative works without limitation. Although all reasonable efforts have been taken to ensure the accuracy and reliability of the software/database and associated data, the National Human Genome Research Institute (NHGRI), National Institutes of Health (NIH) and the U.S. Government do not and cannot warrant the performance or results that may be obtained by using this software/database or data. NHGRI, NIH and the U.S. Government disclaim all warranties as to performance, merchantability or fitness for any particular purpose.


Citation
--------

If you use ampliconDIVider in your work, please use the following reference to cite it:

Varshney GK, Pei W, LaFave MC, Idol J, Xu L, Gallardo V, Carrington B, Bishop K, Jones M, Li M, Harper U, Chen W, Sood R, Ledin J, and Burgess SM. High-Throughput Gene Targeting and Phenotyping in Zebrafish Using CRISPR/Cas9. (Submitted)


Contact
-------

Matthew C. LaFave, Ph.D.
Developmental Genomics Section, Translational and Functional Genomics Branch
NHGRI, NIH

Email: matthew.lafave [at sign] nih.gov

