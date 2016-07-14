#!/usr/bin/perl

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

use strict;
use Getopt::Long;
use Data::Dumper;

my ($fileIn,$fileOut,$control,$nbHzExpected,$depth,$MQ0Expected,$help,$missing);

my $courriel="gustave.djedatin-at-ird.fr";
my ($nomprog) = $0 =~/([^\/]+)$/;
my $MessAbruti ="\nUsage:
\t$nomprog -i fileIn -o fileOut [-c control homozygous list -d depth -H nbHzExpected -M MQ0Expected -m missingData] 


control homozygous list will be ReadGroup separated by commas (ex Ind1,Ind2)

Defaults value are -d 30 -H 8 -M 0 -m 2 -c undef;

        contact: $courriel\n\n";
        

unless (@ARGV) 
        {
        print "\nType --help for more informations\n\n";
        exit;
        }

$nbHzExpected = 8;
$depth = 30;
$MQ0Expected = 0;
$missing = 2;

GetOptions("prout|help|?|h" => \$help,        
            "i|in=s"=>\$fileIn,
            "o|out=s"=>\$fileOut,
            "c|control=s"=>\$control,
            "H|heterozygous=s"=>\$nbHzExpected,
            "d|depth=s"=>\$depth,
            "M|mq0=s"=>\$MQ0Expected,
            "m|missing=s"=>\$missing);


if ($help)
	{
	print $MessAbruti,"\n";
	exit;
	}

open(FIC_VCF,"<", $fileIn) or die ("\nCannot open $fileIn file: $!\nAborting\n");# the input file will be the first argument of the command line
open (OUT,">",$fileOut) or die ("\nCannot create file: $!\nAborting\n"); #output file, the second argument, ">" means "read only"

my $firstLineOut = "#Chromosome\tPosition\tMeanDP\tNbHz\tREF\tALT\tMQ0\tINFOS\n";
print OUT $firstLineOut;

#Number of heterozygous points
my $nbHz= 0;
#Number of lines
my $nbLignes=0;

#List of control individuals 
my @controlList= split /,/, $control;
my %controlHash;

# Read the file line by line (while)
while (my $ligne=<FIC_VCF>)
	{
	chomp($ligne); # Remove ("\n") (chomp)
	if ($ligne =~ m/^##/)
		{
		next; # Skip lines that start with hash (if, =~ m// et next)
		}

	if ($ligne =~ m/^#CHROM/)
		{
		my @fields = split /\t/, $ligne;
		my $j = -1;
		foreach my $local (@fields)
			{
			$j++;
			next if $j < 9;
			$controlHash{$j}=1 if $local ~~ @controlList;
			#print $j." " if $local ~~ @controlList;;
			}
		#print Dumper(\%controlHash);
		#print "\n----\n";
		next;
		}

	if (($ligne =~ s#\.\/\.#\.\/\.#g)>$missing)
		{
		#print $ligne,"\n";
		#exit;		
		next; # Skip lines that contain $missing times or more "./.", or more than $ missing individuals not covered 
		}
	$nbLignes++;
	my @resultats_split = split ("\t", $ligne);# split lines into list (split)
	
	# Count the number of heterozygous
		
	# Set a counter to 0

	my $i = 0;
	# Get the chromosomes
	my $chromosome = $resultats_split[0];
	# retrieve positions	
	my $position = $resultats_split[1];

	# retrieve the informations column and split it

	# retrieve the informations column
	my $info = $resultats_split[7];

	# split the informations column
	my @info_split = split (";", $info); # retrieve the info field into a list
	my @colonne = @info_split;
	my %info;
	while (@colonne)
	{
		my $c1 = shift @colonne;
		my ($field, $value) = split/=/, $c1;
		$info{$field} = $value;
	}
	next if $info{"MQ0"} > $MQ0Expected;


	#For each item in the list (item beyong [8])
	my $tailleListe=scalar(@resultats_split)-1;
	my @sublist = @resultats_split[9..$tailleListe];
#print "@sublist","\n";
#exit;

#retrieve the DP
	my $DP;
	my $outControl = 0;
	my $count = 8;
	while (@sublist)
		{
		$count++;
		my $currentInd = shift @sublist;

		# If the pattern 0/1 is present we add 1
		if ($currentInd =~ m/0\/1/)
			{
			#print $currentInd;

			#Control for mandatory homozygous
			if (defined $controlHash{$count})
				{
				$outControl = 1;
				#print $count," ";
				last;
				}

			my @listField = split /:/,$currentInd;#Split GT:AD:DP:PL field of the VCF file
			$i++ if ($listField[2] > $depth);#An individual is taken into account only if its DP is at least equal to the DP value given in argument
			#we can also write $i += 1 ou $i = $i+1
			$DP += $listField[2];
			}
		}
	#Passer car controles indiv Hz
	next if ($outControl == 1);

	#skip individuals without heterozygous 
	next if ($i<$nbHzExpected); # retrieve the third and 4th element of @ARGV list, which correspond to what is written after the script name in the command line 

	#Print by position the number of heterozygotes 
	$nbHz++;
	my $mean = int($DP/$i); # the entire average value of depth with "int" that means entire number
	my $out = $chromosome."\t".$position."\t".$mean."\t".$i."\t".$resultats_split[3]."\t".$resultats_split[4]."\tMQ0=".$info{"MQ0"}."\t".$info."\n";
	print OUT $out;

	}

print "The number of lines of interest is $nbHz with at least $nbHzExpected heterozygous having MQ0 equal at least to $MQ0Expected value and depth of reads equal to $depth on a total of $nbLignes\n";

exit;
