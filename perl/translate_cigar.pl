#!/usr/bin/env perl

use strict;
use warnings;


while (<>){
	
	chomp;
	my @line = split;
	
	my @cigar = split /([MIDNSHP=X])/, $line[5];
	
	my $pos = 0;
	my $modseq;
	
	while (@cigar){
		
		my $num = shift @cigar;
		my $letter = shift @cigar;
		
		if ($letter eq "M"){
			$modseq .= substr($line[9], $pos, $num);
			$pos += $num;
		}
		elsif($letter eq "D"){
			$modseq .= "-" x $num;
		}
		elsif($letter eq "S"){
			$pos += $num;
		}
		
	}
	
	my $first = join "\t", @line[ 0..8 ];
	my $last = join "\t", @line[ 10..$#line ];
	
	print "$first\t$modseq\t$last\n";
		 
}


exit;