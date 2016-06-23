#! /usr/bin/env perl

######
#
# EN TETE LICENCE
#
#####

####
#
# This tool will be used to detect duplications in autogamous species

####

use strict;
use Getopt::Long;

my ($fileIn,$fileOut,$control,$nbHzExpected,$depth,$MQ0Expected,$help,$missing,$sizeMax,$blocSize,$density,$gff);

#Standard values
$nbHzExpected = 8;
$depth = 30;
$MQ0Expected = 0;
$missing = 2;
$sizeMax = 1000;           
$blocSize = 100;
$density = 25;

my $duplicationDetectorHome="/home/djedatin/DuplicationDetector";

GetOptions("prout|help|?|h" => \$help,   
            "i|in=s"=>\$fileIn,
            "o|out=s"=>\$fileOut,
            "c|control=s"=>\$control,
            "H|heterozygous=s"=>\$nbHzExpected,
            "d|depth=s"=>\$depth,
            "M|mq0=s"=>\$MQ0Expected,
            "m|missing=s"=>\$missing,
            "s|sizeMax=s"=>\$sizeMax,
            "b|blocSize=s"=>\$blocSize,
            "d|density=s"=>\$density,
	    "g|gff=s"=>\$gff);


print "\n--- Hz points recovery ---\n";


my $tmpOut1 = $fileIn;
$tmpOut1 =~ s/\.vcf/-filtered\.vcf/;

my $commandHz = "perl $duplicationDetectorHome/scripts/filtrer_lignes_vcf_MQ0.pl -i $fileIn -o $tmpOut1 -H $nbHzExpected -d $depth -M $MQ0Expected -m $missing -c $control";


system ("$commandHz") and die ("\nCannot launch the following command:\n$commandHz\n\n$!\n.Aborting...\n");


print "\n--- Genomic bloc ---\n";


my $tmpOut2 = $fileIn;
$tmpOut2 =~ s/\.vcf/-block\.csv/;

my $commandBloc = "perl $duplicationDetectorHome/scripts/bloc_position.pl $tmpOut1 $tmpOut2 $sizeMax $blocSize $density";


system ("$commandBloc") and die ("\nCannot launch the following command:\n$commandBloc\n\n$!\n.Aborting...\n");



print "\n--- blocks gene content ---\n";

my $commandBed = "intersectBed -wao -a $tmpOut2 -b $gff | grep \"gene\" | grep -v \"transposo\" > $fileOut";

system ("$commandBed") and die ("\nCannot launch the following command:\n$commandBed\n\n$!\n.Aborting...\n");

print "\n--- Finished ---\n";

exit;

