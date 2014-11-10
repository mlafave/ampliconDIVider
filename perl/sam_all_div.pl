#!/usr/bin/env perl

use strict;
use warnings;

# This script takes a SAM input, and outputs the each line prepended with an 
# indicator of the type, location, and size of the longest insertion or deletion.



while (<>){
	
	chomp;
	my @line = split;
	
	my @cigar = split /([MIDNSHP=X])/, $line[5];

	# Initialize position as the start of the read (converted to 0-based 
	# coordinates, at least for the time being)
	my $position = $line[3] - 1;
	my $subpos = 0;
	
	my $read = $line[9];
	
	my $cigar_number;
	my $cigar_letter;
	
	my $output_position;
	my $output_size = 0;
	my $output_letter;
	
	while ( $subpos < length($read) ){

		$cigar_number = shift @cigar;
		$cigar_letter = shift @cigar;
		
		if ($cigar_letter eq "S"){
			$subpos += $cigar_number;
			next;
		}
		
		if ( $cigar_letter eq "I" || $cigar_letter eq "D" ){
			
			#if( $cigar_number > $output_size ){
				
				$output_size = $cigar_number;
				$output_letter = $cigar_letter;
				$output_position = $position + 1;
				
				print "${output_letter}_${output_position}_${output_size}\n"
				
			#}
		
		}
		
		if ($cigar_letter eq "I"){
			$subpos += $cigar_number;
		} elsif ( $cigar_letter eq "D" ){
			$position += $cigar_number;	
		} else {
			$position += $cigar_number;	
			$subpos += $cigar_number;
		}
		
		
		
	}
	
	# Put position back to SAM 1-based version
	#${output_position}++;
	
	# Note that tabs from the input will be changed to spaces
	#print "${output_letter}_${output_position}_${output_size}\t@line\n" if $output_letter;
	
}

 

exit;