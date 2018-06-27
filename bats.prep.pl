#!/usr/perl/bin

# perl PrepBaTS.pl <inputfilename> <outputfilename> <savetage1> #

$inputFile = @ARGV[0];
$outputFile = @ARGV[1];

open(INFILE, $inputFile);
open(OUTFILE, ">".$outputFile);

while ($line = <INFILE>) {
	$line=~s/\[&rate.*?\]//g;
	$line=~s/\[&lnP.*?\]/\[&lnP=1.0\]/g;
	print OUTFILE $line;}
	
close(INFILE);
close(OUTFILE);
