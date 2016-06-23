

#!/usr/bin/perl

# title: Split_genome
# Author: Gustave
# Goal: Split lines into genomic intervals (blocks)
# Retrieve the file name and open the file 
#  First associate with the file, a descriptor
#  used FIC


use strict;
use Getopt::Long;
use Data::Dumper;



my ($fileIn,$fileOut,$sizeMax,$blocSize,$density,$help)=@ARGV;

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
