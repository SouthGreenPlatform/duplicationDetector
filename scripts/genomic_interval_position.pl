

#!/usr/bin/perl


###################################################################################################################################
#
# Copyright 2016-2017 IRD-FAST/DASSA
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
# Version 1 and latter written by Gustave Djedatin and Francois Sabot
####################################################################################################################################


use strict;
use Getopt::Long;
use Data::Dumper;



my ($fileIn,$fileOut,$sizeMax,$blocSize,$density,$help);

my $courriel="gustave.djedatin-at-ird.fr";
my ($nomprog) = $0 =~/([^\/]+)$/;
my $MessAbruti ="\nUsage:
\t$nomprog -i fileIn -o fileOut [-s sizeMax -b blocSize -d density] 


Defaults value are -s 1000 -b 100 -d 25;

        contact: $courriel\n\n";
        

unless (@ARGV) 
        {
        print "\nType --help for more informations\n\n";
        exit;
        }

$sizeMax = 1000;
$blocSize = 100;
$density = 25;


GetOptions("prout|help|?|h" => \$help,        
            "i|in=s"=>\$fileIn,
            "o|out=s"=>\$fileOut,
            "s|control=s"=>\$sizeMax,
            "b|heterozygous=s"=>\$blocSize,
            "d|depth=s"=>\$density);
           
 if ($help)
    {
        print $MessAbruti;
        exit;
    }

open (FIC_VCF,"<",$fileIn) or die ("\nCannot open $fileIn file: $!\nAborting\n"); #the input file will be the first argument of the command line
open (OUT,">",$fileOut)or die ("\nCannot create file: $!\nAborting\n"); #output file, the second argument, ">" means "read only"

my $firstLineOut = "#Chromosome\tStart\tStop\tSize\tNbSNP\tMeanNbHz\n";
print OUT $firstLineOut;

#Reset $start and $stop
my $start= 0;
my $stop = 0;
my $chromosome;
my $SNP=0;
my $nbHz=0;
#Reset the first line
my $i=0;

# Read the file line by line (while)
while (my $ligne = <FIC_VCF>)
        {
        chomp $ligne;
        next if $ligne =~ m/^#/; #Skip lines that start with hash '#'
        my @champs = split("\t", $ligne); #Separated by tabs
        $chromosome = $champs[0];
        #First line
        if ($i == 0)
                {
                $i++;
                $start = $champs[1];
                $stop = $champs[1];
                $SNP++;
                $nbHz += $champs[3];
                next;
                }
        if ($champs[1] < ($stop + $sizeMax))
                {
                $stop = $champs[1];
                $SNP++;
                $nbHz += $champs[3];
                next; #Evoid to do 'else' for the following steeps
                }
        my $size = $stop - $start;
        #print $SNP,"\t";
        #next;
        my $heterozygoty = sprintf("%.2f",$nbHz/$SNP);
        my $outLigne = $chromosome."\t".$start."\t".$stop."\t".$size."\t".$SNP."\t".$heterozygoty."\n"; #output of the previous block
        print OUT $outLigne if (($size > $blocSize) && (($size/$SNP) < $density)); #Do not consider a block if its size is lower than $blocSize, and the total number of bases and density lower than n SNP every n bases
        $start = $champs[1]; #reset for the following block
        $stop = $champs[1];
        $SNP=1;
        $nbHz = $champs[3];
        next;
        }
my $size = $stop - $start;
my $heterozygoty = sprintf("%02d",$nbHz/$SNP);
my $outFinal = $chromosome."\t".$start."\t".$stop."\t".$size."\t".$SNP."\t".$heterozygoty."\n"; #output du bloc final
print OUT $outFinal if (($size > $blocSize) && (($size/$SNP) < $density)); #Do not consider a block if its size is lower than $blocSize, and the total number of bases and density lower than n SNP every n bases


exit;
