#!/usr/bin/env perl

use strict;
use warnings;

#Give that file to perl, loop through. At each line, if you haven't seen the
#pair, store it. If you have seen the pair, compare the two. The actual
#comparison: It's a bit redundant and sloppy, but could have a hash in which all
#primers are keys, and their pairs are values. So you check if, say, the primer
#of the first read (acting as a key) has a value equal to the primer of the
#second. MOST of the time, it won't, so ignore those. If it DOES match, then
#print both lines, or at least the basename they share.
#
#Go back to the tab-delimited file and remove the lines that were printed by the
#perl script. (is that really necessary? They'll be removed for not being proper 
#pairs later, anyway)

if ( @ARGV != 2 ) {
	die "Usage: primer_longfrag_find.pl 2col primer_tabfq\n$!";
}

if ( ! -e $ARGV[0] ) {
	die "$ARGV[0] doesn't exist: $!";
}

if ( ! -e $ARGV[1] ) {
	die "$ARGV[1] doesn't exist: $!";
}



if ( ! open PRIMERS, "<", "$ARGV[0]" ) {
	die "Cannot open file $ARGV[0]: $!";
}


# Fill a hash with the primer sequence. Each serves as a key AND a value.

my %primer_hash;

while (<PRIMERS>){
	
	my @primer = split;
	$primer_hash{$primer[0]} = $primer[1];
	$primer_hash{$primer[1]} = $primer[0];
	
}

close PRIMERS;


# Loop through the input file

if ( ! open TABFQ, "<", "$ARGV[1]" ) {
	die "Cannot open file $ARGV[1]: $!";
}

my %read_hash;

while (<TABFQ>){
	
	my @line = split;
	
	# Check the basename (second column).
	
	my $basename = substr($line[1],0,length($line[1])-1);
	
	if ( exists $read_hash{$basename}){
		
		# If it HAS been seen before, check if the primer of the one you're 
		# currently looking at has a hash pair that matches the other primer.
		
		my @pair_line = @{ $read_hash{$basename} };
		my $pair_primer = $pair_line[0];
		
		if ( $pair_primer eq $primer_hash{$line[0]} ){
			
			# If the primers DO correspond, print both lines to an output file. 
			# Don't modify the format within this script.
			
			print "@{pair_line}\n@{line}\n";
			
		} else {
			
			# If the two primers don't correspond, just ignore them. The one entry can 
			# be deleted from the hash to save memory.
			
			delete $read_hash{$basename};
			next;
			
		}
		
		
	} else {
		
		# If it hasn't been seen before, store it in the hash.
		
		my $ref = \@line;
		
		$read_hash{$basename} = $ref;
		
	}
		
}


close TABFQ;



exit;
