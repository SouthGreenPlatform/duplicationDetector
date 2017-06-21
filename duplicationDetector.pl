#! /usr/bin/env perl

###################################################################################################################################
#
# Copyright 2016 IRD-FAST/DASSA
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/> or
# write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# You should have received a copy of the CeCILL-C license with this program.
#If not see <http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.txt>
#
# Intellectual property belongs to IRD and FAST/DASSA
# Version 1 written by Gustave Djedatin and Francois Sabot
####################################################################################################################################

####
#
# This version is working only to detect duplications in autogamous species

####

use strict;
use Getopt::Long;

my ($fileIn,$fileOut,$control,$nbHzExpected,$depth,$MQ0Expected,$help,$missing,$sizeMax,$blocSize,$density,$gff);

my $courriel="gustave.djedatin-at-ird.fr";
my ($nomprog) = $0 =~/([^\/]+)$/;
my $MessAbruti ="\nUsage:
\t$nomprog -i VCFIn -o fileOut [-c control homozygous list -d depth -H nbHzExpected -M MQ0Expected -m missingData -s maximum size between 2 points -b minimal block size -D minimal block density -g gffFile] 


control homozygous list will be ReadGroup separated by commas (ex Ind1,Ind2)

Defaults value are -d 30 -H 8 -M 0 -m 2 -D 25 -b 100 -s 1000 -c undef -g undef;

        contact: $courriel\n\n";


#Standard values
$nbHzExpected = 8;
$depth = 30;
$MQ0Expected = 0;
$missing = 2;
$sizeMax = 1000;           
$blocSize = 100;
$density = 25;
$control="";
$gff = "";

unless (@ARGV) 
        {
        print "\nType --help for more informations\n\n";
        exit;
        }


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
            "D|density=s"=>\$density,
            "g|gff=s"=>\$gff);

if ($help)
	{
	print $MessAbruti,"\n";
	exit;
	}

my $duplicationDetectorHome="/path/to/duplicationDetector";


print "\n--- Hz points recovery ---\n";


my $tmpOut1 = $fileIn;
$tmpOut1 =~ s/\.vcf/-filtered\.vcf/;

my $commandHz = "perl $duplicationDetectorHome/scripts/vcf_filter.pl -i $fileIn -o $tmpOut1 -H $nbHzExpected -d $depth -M $MQ0Expected -m $missing";
$commandHz .= " -c $control" if $control;


system ("$commandHz") and die ("\nCannot launch the VCF filtration using the following command:\n$commandHz\n\n$!\n.Aborting...\n");


print "\n--- Genomic bloc ---\n";


my $tmpOut2 = $fileIn;
$tmpOut2 =~ s/\.vcf/-block\.csv/;

my $commandBloc = "perl $duplicationDetectorHome/scripts/genomic_interval_position.pl -i $tmpOut1 -o $tmpOut2 -s $sizeMax -b $blocSize -d $density";


system ("$commandBloc") and die ("\nCannot launch the genomic interval determination using the following command:\n$commandBloc\n\n$!\n.Aborting...\n");


if ($gff)
{
    print "\n--- Blocks gene content ---\n";
    
    my $commandBed = "intersectBed -wao -a $tmpOut2 -b $gff | grep \"gene\" | grep -v \"ransposo\" > $fileOut";
    
    system ("$commandBed") and warn ("\nErrors occured during the duplicated gene determination the following command:\n$commandBed\n\n$!\n");
}
else
{
    print "\n--- No gff provided, switching the block gene control ---\n";
    system("mv $tmpOut2 $fileOut") and die ("\nCannot create the $fileOut outfile:\n$!\n.Aborting...\n");
}

print "\n--- Finished ---\n";

exit;

