#!/usr/bin/perl

############################################################################
# Revision history
# v1.0 (September 2, 2015)
#    - Greg Sanders
#
#    Beta-version scoring code for the NIST OpenSAD Evaluation.
#    Developed using Perl v5.16.3
#
############################################################################
# This software was developed at the National Institute of Standards and Technology by
# employees and/or contractors of the Federal Government in the course of their official duties.
# Pursuant to Title 17 Section 105 of the United States Code this software is not subject to 
# copyright protection within the United States and is in the public domain.
#
# NIST assumes no responsibility whatsoever for its use by any party, and makes no guarantees,
# expressed or implied, about its quality, reliability, or any other characteristic.
# We would appreciate acknowledgement if the software is used.  This software can be
# redistributed and/or modified freely provided that any derivative works bear some notice
# that they are derived from it, and any modified versions bear some notice that they
# have been modified.
#
# THIS SOFTWARE IS PROVIDED "AS IS."  With regard to this software, NIST MAKES NO EXPRESS
# OR IMPLIED WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING MERCHANTABILITY,
# OR FITNESS FOR A PARTICULAR PURPOSE.
############################################################################

use strict;
use Getopt::Std;
use XML::LibXML;

use vars qw($opt_d $opt_v);
getopts ('d:v');
die "Error: Test-definition file not specified\n" if not defined($opt_d);
open TEST_DEF, "<$opt_d" or die "Error: Cannot open input file $opt_d\n";
close TEST_DEF;

my $parser = XML::LibXML->new();
my $testDef = $parser->parse_file($opt_d);


   ## As a matter of Perl pain, the following print statement won't work (needs to be a printf)
   # print "Sample == [id: $sample->getAttribute('id')   file: $sample->getAttribute('file')\n";


## The following code assumes we are running this Perl program with
## the current working directory being the location of this program
## and of scoreFile_SAD.pl -- and we further assume that any relative path(s)
## that appear as the value of a file attribute of a SAMPLE element
## are relative to the current working directory.  The audio filename
## extension is hard-coded as .flac (hard assumption). 
for my $sample ($testDef->findnodes('TestSet/TEST/SAMPLE')) {
   my $audioFilenameWithPath = $sample->getAttribute('file');
   $audioFilenameWithPath =~ '^(.*)/([^/]+).flac$';
   my $path = $1;
   my $baseFilenameWithoutPath = $2;

   my $refFile = "";
   my $hypFile = "";
   if ($path ne "") {
       $refFile = $path . "/" . $baseFilenameWithoutPath . "_annot.txt";
       $hypFile = $path . "/" . $baseFilenameWithoutPath . ".txt";
   } else {
       $refFile = $baseFilenameWithoutPath . "_annot.txt";
       $hypFile = $baseFilenameWithoutPath . ".txt";
   }

   system ("scoreFile_SAD.pl -r $refFile -h $hypFile -s 2 -e 3 -g 4 -t 5 -f 6 -u 7");
}

