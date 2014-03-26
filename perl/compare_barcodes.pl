#!/usr/bin/env perl

use strict;
use warnings;

unless ( @ARGV == 2 ) {
	die "Usage: compare_barcodes.pl barcodes.bcL barcodes.bcR\n$!";
}


unless ( -e $ARGV[0] ) {
	die "$ARGV[0] doesn't exist: $!";
}

unless ( -e $ARGV[1] ) {
	die "$ARGV[1] doesn't exist: $!";
}

my %bcl_hash;

unless ( open BCL, "<", "$ARGV[0]" ) {
	die "Cannot open file $ARGV[0]: $!";
}

# Read in first barcode file into a hash. Basename of read is the key, barcode
# is the value

while (<BCL>){
	
	chomp;
	my ($barcode, $name) = split;
	$bcl_hash{substr($name, 0, length($name)-2)} = $barcode;
	
}

close BCL;



unless ( open BCR, "<", "$ARGV[1]" ) {
	die "Cannot open file $ARGV[1]: $!";
}

while (<BCR>){
	
	chomp;
	my ($barcode, $name) = split;
	
	$barcode = reverse $barcode;
	$barcode =~ tr/ACGTNacgtn/TGCANtgcan/;
	
	$name = substr($name, 0, length($name)-2);
	
	if (exists $bcl_hash{$name}){
		
		# The current name was seen in the previous file; now compare the 
		# barcodes
		
		if ($bcl_hash{$name} eq $barcode){
			
			# The barcodes match; print
			
			print "${barcode}\t${name}\n";
			
		}
		
		# If the barcodes didn't match, just skip it. Either way, delete this
		# entry from the hash.
		
		delete $bcl_hash{$name};
		
	}else{
		
		# The current name was not seen in the previous barcode file; print it
		
		print "${barcode}\t${name}\n";
		
	}
	
}


close BCR;

# Print the entries that still remain in the hash

while ( my ($key, $value) = each %bcl_hash ){
	print "${value}\t${key}\n";
}


# Remember, not being in one of the barcode files just means the BARCODE wasn't
# detected, not that the read itself is bad.

exit;
