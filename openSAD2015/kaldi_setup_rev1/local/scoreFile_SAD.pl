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

use vars qw($opt_e $opt_f $opt_g $opt_h $opt_r $opt_s $opt_t $opt_u $opt_v);
getopts ('e:f:g:h:r:s:t:u:v');
# opt_r is the path to the ref file (the input annotation)

# opt_s is the zero-based column of start times for the ref 
# opt_e is the zero-based column of end times for the ref
# opt_g is the zero-based column of interval-type for the ref (S, NS, NT, or uncertain)

# opt_h is the path to the hyp file (the system output)

# opt_t is the zero-based column of start times for the hyp
# opt_f is the zero-based column of end times for the hyp
# opt_u is the zero-based column of interval-type for the hyp (speech or non-speech)

# opt_v is a boolean flag -- it triggers voluminous/verbose output to STDERR

die "Hyp file not defined\n" if not defined($opt_h); 
die "Ref file not defined\n" if not defined($opt_r); 

die "Ref interval-type field not defined\n" if not defined($opt_g);
die "Hyp interval-type field not defined\n" if not defined($opt_u);

die "Ref interval-start field not defined\n" if not defined($opt_s);
die "Hyp interval-start field not defined\n" if not defined($opt_t);

die "Ref interval-end field not defined\n" if not defined($opt_e);
die "Hyp interval-end field not defined\n" if not defined($opt_f);


my $refFilePath = $opt_r;
open REF_FILE, "<$refFilePath" or die "Cannot open ref file $refFilePath\n";
my $hypFilePath = $opt_h;
open HYP_FILE, "<$hypFilePath" or die "Cannot open hyp file $hypFilePath\n";

my @scorableSegs_noCollar = ();     # with no collars around the speech segs
my @scorableSegs_quarterSec = ();   # 1/4 second collars
my @scorableSegs_halfSec = ();      # 1/2 second collars
my @scorableSegs_oneSec = ();       # one second collars
my @scorableSegs_twoSecs = ();      # two seconds collars

my @hypSegs = ();    # always with no collars (collars pertain to the ref)

my $currRefTime = 0.0;  # where we are in the ref file (end prev seg, with no collar)
my $prevIntervalType = "";


#### - - - - - - - - - - - -
# We begin by inhaling the ref file, converting it to our data-structure with no collars.
while (<REF_FILE>) {
    chomp; chomp;
    my @fields = split /\t/;
  
    if ($fields[$opt_s] > $currRefTime) {
        die "Error in ref file at un-annotated time interval from $currRefTime to $fields[$opt_s]\n";
    } elsif (($fields[$opt_g] eq "NS") or ($fields[$opt_g] eq "NT") or ($fields[$opt_g] eq "RX")) {
        if (($prevIntervalType eq "NonSpeech") and ($currRefTime > 0.0)) {    # There is a preceding NonSpeech segment to splice into
            my @prev = pop @scorableSegs_noCollar;
            $fields[$opt_s] = $prev[0][0];   # splice these NonSpeech segments
        }
        push @scorableSegs_noCollar, [$fields[$opt_s], $fields[$opt_e], "NonSpeech"];
        $prevIntervalType = "NonSpeech";
        $currRefTime = $fields[$opt_e];
    } elsif (($fields[$opt_g] eq "S") and ($fields[$opt_s] == $currRefTime)) {
        if (($prevIntervalType eq "Speech") and ($currRefTime > 0.0)) {    # There is a preceding Speech segment to splice into
            my @prev = pop @scorableSegs_noCollar;
            $fields[$opt_s] = $prev[0][0];   # splice these speech segments
        }
        push @scorableSegs_noCollar, [$fields[$opt_s], $fields[$opt_e], "Speech"];
        $prevIntervalType = "Speech";
        $currRefTime = $fields[$opt_e];
    } else {  #overlapping ref segs
       die "Error: overlapping ref segs, with end prev seg at $currRefTime and begin new seg at $fields[$opt_s]\n";
    }
    # If we knew the end time of the file and the file ends with a nonspeech segment,
    # we could here output that nonspeech segment.
}

## If the ref begins with a nonSpeech seg, deal with that.
if ($scorableSegs_noCollar[0][2] eq "NonSpeech") {
    my $start = $scorableSegs_noCollar[0][0];
    my $end = $scorableSegs_noCollar[0][1];
    my $dur = $end - $start;

    if ($start != 0.0) {
        die "Unexpected ref start time > 0.0: (start $scorableSegs_noCollar[0][0] : end $scorableSegs_noCollar[0][1] : type $scorableSegs_noCollar[0][2])\n"; 
    }

    ## In the case of collars, start the collars at zero if the resulting preceding NonSpeech segment will not
    ## last for at least 0.1 seconds
    if ($dur >= 0.35) {
        if ($dur > 0.25) {
            push @scorableSegs_quarterSec, [$start, $end - 0.25, "NonSpeech"];
        }
        push @scorableSegs_quarterSec, [$end - 0.25, $end, "Collar"];    # collar preceding a speech region

        if ($dur >= 0.6) {
            if ($dur > 0.5) {
                push @scorableSegs_halfSec, [$start, $end - 0.5, "NonSpeech"];
            }
            push @scorableSegs_halfSec, [$end - 0.5, $end, "Collar"];    # collar preceding a speech region

            if ($dur >= 1.1) {
                if ($dur > 1.0) {
                    push @scorableSegs_oneSec, [$start, $end - 1.0, "NonSpeech"];
                }
                push @scorableSegs_oneSec, [$end - 1.0, $end, "Collar"];    # collar preceding a speech region

                if ($dur >= 2.1) {
                    if ($dur > 2.0) {
                        push @scorableSegs_twoSecs, [$start, $end - 2.0, "NonSpeech"];
                    }
                    push @scorableSegs_twoSecs, [$end - 2.0, $end, "Collar"];    # collar preceding a speech region
                } else {
                    push @scorableSegs_twoSecs, [$start, $end, "Collar"];        # collar preceding a speech region
                }
            } else {
                push @scorableSegs_oneSec, [$start, $end, "Collar"];        # collar preceding a speech region
                push @scorableSegs_twoSecs, [$start, $end, "Collar"];       # collar preceding a speech region
            }
        } else {
            push @scorableSegs_halfSec, [$start, $end, "Collar"];       # collar preceding a speech region
            push @scorableSegs_oneSec, [$start, $end, "Collar"];        # collar preceding a speech region
            push @scorableSegs_twoSecs, [$start, $end, "Collar"];       # collar preceding a speech region
        }
    } else {
        push @scorableSegs_quarterSec, [$start, $end, "Collar"];    # collar preceding a speech region
        push @scorableSegs_halfSec, [$start, $end, "Collar"];       # collar preceding a speech region
        push @scorableSegs_oneSec, [$start, $end, "Collar"];        # collar preceding a speech region
        push @scorableSegs_twoSecs, [$start, $end, "Collar"];       # collar preceding a speech region
    }
} else {
    ## the ref starts with a speech seg, which gets output unchanged for all collar sizes
    my $end = $scorableSegs_noCollar[0][1];

    push @scorableSegs_twoSecs, [0.0, $end, "Speech"];
    push @scorableSegs_oneSec, [0.0, $end, "Speech"];
    push @scorableSegs_halfSec, [0.0, $end, "Speech"];
    push @scorableSegs_quarterSec, [0.0, $end, "Speech"];
}

#### - - - - - - - - - - - -
## Now we need to populate reference data-structures for the various collar size.
##
## We have already processed scorableSegs_noCollar[0].
## Sweep through the rest of scorableSegs_noCollar, and generate versions for various collar sizes
## Note that collars come out of nonSpeech segs, and we output the Speech segs unchanged.
for (my $xx = 1; $xx < scalar(@scorableSegs_noCollar); $xx += 1) {
    my $start = $scorableSegs_noCollar[$xx][0];
    my $end = $scorableSegs_noCollar[$xx][1];
    my $dur = $end - $start;
    my $segType = $scorableSegs_noCollar[$xx][2];

    if ($segType eq "Speech") {
        push @scorableSegs_twoSecs, [$start, $end, "Speech"];
        push @scorableSegs_oneSec, [$start, $end, "Speech"];
        push @scorableSegs_halfSec, [$start, $end, "Speech"];
        push @scorableSegs_quarterSec, [$start, $end, "Speech"];
    } else {   ## Note: $segType has to be "NonSpeech" and there must be an immediately preceding "Speech" segment
               ##       or beginning of file
        ## In the case of collars, merge the collars if the resulting intervening NonSpeech segment will not
        ## last for at least 0.1 seconds
        if ($dur >= 4.1) {
            push @scorableSegs_twoSecs, [$start, $start+2.0, "Collar"];      # collar following a speech region
            push @scorableSegs_twoSecs, [$start+2.0, $end-2.0, "NonSpeech"];
            push @scorableSegs_twoSecs, [$end-2.0, $end, "Collar"];          # collar preceding a speech region

            push @scorableSegs_oneSec, [$start, $start+1.0, "Collar"];       # collar following a speech region
            push @scorableSegs_oneSec, [$start+1.0, $end-1.0, "NonSpeech"];
            push @scorableSegs_oneSec, [$end-1.0, $end, "Collar"];           # collar preceding a speech region

            push @scorableSegs_halfSec, [$start, $start+0.5, "Collar"];      # collar following a speech region
            push @scorableSegs_halfSec, [$start+0.5, $end-0.5, "NonSpeech"];
            push @scorableSegs_halfSec, [$end-0.5, $end, "Collar"];          # collar preceding a speech region

            push @scorableSegs_quarterSec, [$start, $start+0.25, "Collar"];      # collar following a speech region
            push @scorableSegs_quarterSec, [$start+0.25, $end-0.25, "NonSpeech"];
            push @scorableSegs_quarterSec, [$end-0.25, $end, "Collar"];          # collar preceding a speech region
        } else {
            push @scorableSegs_twoSecs, [$start, $end, "Collar"];            # merged collar

            if ($dur >= 2.1) {
                push @scorableSegs_oneSec, [$start, $start+1.0, "Collar"];      # collar following a speech region
                push @scorableSegs_oneSec, [$start+1.0, $end-1.0, "NonSpeech"];
                push @scorableSegs_oneSec, [$end-1.0, $end, "Collar"];          # collar preceding a speech region

                push @scorableSegs_halfSec, [$start, $start+0.5, "Collar"];      # collar following a speech region
                push @scorableSegs_halfSec, [$start+0.5, $end-0.5, "NonSpeech"];
                push @scorableSegs_halfSec, [$end-0.5, $end, "Collar"];          # collar preceding a speech region

                push @scorableSegs_quarterSec, [$start, $start+0.25, "Collar"];      # collar following a speech region
                push @scorableSegs_quarterSec, [$start+0.25, $end-0.25, "NonSpeech"];
                push @scorableSegs_quarterSec, [$end-0.25, $end, "Collar"];          # collar preceding a speech region
            } else {
                push @scorableSegs_oneSec, [$start, $end, "Collar"];            # merged collar

                if ($dur >= 1.1) {
                    push @scorableSegs_halfSec, [$start, $start+0.5, "Collar"];      # collar following a speech region
                    push @scorableSegs_halfSec, [$start+0.5, $end-0.5, "NonSpeech"];
                    push @scorableSegs_halfSec, [$end-0.5, $end, "Collar"];          # collar preceding a speech region

                    push @scorableSegs_quarterSec, [$start, $start+0.25, "Collar"];      # collar following a speech region
                    push @scorableSegs_quarterSec, [$start+0.25, $end-0.25, "NonSpeech"];
                    push @scorableSegs_quarterSec, [$end-0.25, $end, "Collar"];          # collar preceding a speech region
                } else {
                    push @scorableSegs_halfSec, [$start, $end, "Collar"];            # merged collar

                    if ($dur >= 0.6) {
                        push @scorableSegs_quarterSec, [$start, $start+0.25, "Collar"];       # collar following a speech region
                        push @scorableSegs_quarterSec, [$start+0.25, $end-0.25, "NonSpeech"];
                        push @scorableSegs_quarterSec, [$end-0.25, $end, "Collar"];           # collar preceding a speech region
                    } else {
                        push @scorableSegs_quarterSec, [$start, $end, "Collar"];              # merged collar
                    }
                }
            }
        }
    }
}

#### - - - - - - - - - - - -
# Here we have debugging dumps of the reference data-structures.

if ( defined($opt_v) ) {
    print STDERR "\nBEGIN dumping reference data-structures\n\n";
    
    print "NO COLLAR\n";
    for (my $xx = 0; $xx < scalar(@scorableSegs_noCollar); $xx += 1) {
        print STDERR "\tstart $scorableSegs_noCollar[$xx][0] : end $scorableSegs_noCollar[$xx][1] : type $scorableSegs_noCollar[$xx][2]\n";
    }

    print "\nQUARTER COLLAR\n";
    for (my $xx = 0; $xx < scalar(@scorableSegs_quarterSec); $xx += 1) {
        print STDERR "\tstart $scorableSegs_quarterSec[$xx][0] : end $scorableSegs_quarterSec[$xx][1] : type $scorableSegs_quarterSec[$xx][2]\n";
    }

    print "\nHALF COLLAR\n";
    for (my $xx = 0; $xx < scalar(@scorableSegs_halfSec); $xx += 1) {
        print STDERR "\tstart $scorableSegs_halfSec[$xx][0] : end $scorableSegs_halfSec[$xx][1] : type $scorableSegs_halfSec[$xx][2]\n";
    }

    print "\nONE COLLAR\n";
    for (my $xx = 0; $xx < scalar(@scorableSegs_oneSec); $xx += 1) {
        print STDERR "\tstart $scorableSegs_oneSec[$xx][0] : end $scorableSegs_oneSec[$xx][1] : type $scorableSegs_oneSec[$xx][2]\n";
    }

    print "\nTWO COLLAR\n";
    for (my $xx = 0; $xx < scalar(@scorableSegs_twoSecs); $xx += 1) {
        print STDERR "\tstart $scorableSegs_twoSecs[$xx][0] : end $scorableSegs_twoSecs[$xx][1] : type $scorableSegs_twoSecs[$xx][2]\n";
    }

    print STDERR "\nDONE dumping reference data-structures\n\n";
}


#### - - - - - - - - - - - -
# Much like we inhaled the reference file, inhale the system output (i.e., the hyp).
#
# Since we assume the reference actually covers the entire audio input, 
# there has to be some decision about system output (hyp) that starts earlier
# than the reference, or that ends later.  What we actually do here is
# to trim/truncate the system output in those cases.  Similarly, if
# the system output starts later than the ref or ends earlier, we pad out
# the system output with a NonSpeech segment.  Therefore, the system output
# ends up starting at the same time as the ref, and ending at the same time.
#
# I believe this is the correct way to score these.   -- Greg Sanders 

my $currHypTime = 0.0;
$prevIntervalType = "";
while (<HYP_FILE>) {
    chomp; chomp;
    my @fields = split /\t/;
  
    if (($fields[$opt_t] > $currHypTime) or ($fields[$opt_t] < $currHypTime)) {
        die "Error in hyp file at un-annotated time interval from $currRefTime to $fields[$opt_t]\n";
    } elsif (($fields[$opt_u] eq "non-speech") or ($fields[$opt_u] eq "nonspeech")) {   # Actually, sys output should have a hyphen 
        if (($prevIntervalType eq "NonSpeech") and ($currHypTime > 0.0)) {    # There is a preceding NonSpeech segment to splice into
            my @prev = pop @hypSegs;
            $fields[$opt_t] = $prev[0][0];   # splice these NonSpeech segments
        }
        push @hypSegs, [$fields[$opt_t], $fields[$opt_f], "NonSpeech"];
        $currHypTime = $fields[$opt_f];
        $prevIntervalType = "NonSpeech";
    } elsif ($fields[$opt_u] eq "speech") {
        if (($prevIntervalType eq "Speech") and ($currHypTime > 0.0)) {    # There is a preceding Speech segment to splice into
            my @prev = pop @hypSegs;
            $fields[$opt_t] = $prev[0][0];   # splice these Speech segments
        }
        push @hypSegs, [$fields[$opt_t], $fields[$opt_f], "Speech"];
        $currHypTime = $fields[$opt_f];
        $prevIntervalType = "Speech";
    } else {  #overlapping hyp segs
       die "Error: overlapping hyp segs, with end prev seg at $currHypTime and begin new seg at $fields[$opt_t] with type $fields[$opt_u]\n";
    }
    # If we knew the end time of the file and the file ends with a nonspeech segment,
    # we could here output that nonspeech segment.
}

## If the hyp begins with a nonSpeech seg, deal with that.
if ($hypSegs[0][2] eq "NonSpeech") {
    my $start = $hypSegs[0][0];
    my $end = $hypSegs[0][1];
    my $dur = $end - $start;

    if ($start != 0.0) {
        die "Unexpected start time > s $hypSegs[0][0] : e $hypSegs[0][1] : t $hypSegs[0][2]<\n"; 
    }
}

my $refStartTime = $scorableSegs_noCollar[0][0];                           # the hyp will be made to start at this time
my $refEndTime = $scorableSegs_noCollar[scalar(@scorableSegs_noCollar) - 1][1];  # hyp will be made to end at this time

if ($hypSegs[0][0] < $refStartTime) {
    while ($hypSegs[0][1] <= $refStartTime) {
        shift @hypSegs;
    }
}
# Now, the initial hyp seg should either start at refStartTime or else enclose refStartTime

if ($hypSegs[0][0] > $refStartTime) {
    if ($hypSegs[0][2] eq "NonSpeech") {
        $hypSegs[0][0] = $refStartTime;    # adjust hyp start time to match ref
    } else {   # $hypSegs[0][2] is "Speech" 
        my $existingHypStartTime = $hypSegs[0][0];
        unshift @hypSegs, [$refStartTime, $existingHypStartTime, "NonSpeech"];  # prepend appropriate NonSpeech seg
    }
}
# Now, the initial hyp seg should begin at refStartTime

if ($hypSegs[scalar(@hypSegs) - 1][1] > $refEndTime) {
    while ($hypSegs[scalar(@hypSegs) - 1][0] >= $refEndTime) {
        pop @hypSegs;
    }
}
# Now, the final hyp seg should either end at refEndTime or else enclose it

if ($hypSegs[scalar(@hypSegs) - 1][1] < $refEndTime) {
    if ($hypSegs[scalar(@hypSegs) - 1][2] eq "NonSpeech") {
        $hypSegs[scalar(@hypSegs) - 1][0] = $refEndTime;    # adjust hyp end time to match ref
    } else {   # $hypSegs[scalar(@hypSegs) - 1][2] is "Speech"
        my $existingHypEndTime = $hypSegs[scalar(@hypSegs) - 1][1];
        push @hypSegs, [$existingHypEndTime, $refEndTime, "NonSpeech"];   # append appropriate NonSpeech seg
    }
}
# Now, the final hyp seg should end at refEndTime

## Dump the hyp
if ( defined($opt_v) ) {
    print "\nHYP SEGS:\n";
    for (my $xx = 0; $xx < scalar(@hypSegs); $xx += 1) {
        print STDERR "\tstart $hypSegs[$xx][0] : end $hypSegs[$xx][1] : type $hypSegs[$xx][2]\n";
    }
    print STDERR "end of HYP SEGS\n\n";
}


### Print identifying info as header for the output
print "\nHyp file:  $opt_h\nRef file:  $opt_r\n";


#### - - - - - - - - - - - -
# For each collar size, call subroutine to compute scores
computeAndPrintScores(\@scorableSegs_noCollar, \@hypSegs, "No Collar");
computeAndPrintScores(\@scorableSegs_quarterSec, \@hypSegs, "QuarterSecond Collar");
computeAndPrintScores(\@scorableSegs_halfSec, \@hypSegs, "HalfSecond Collar");
computeAndPrintScores(\@scorableSegs_oneSec, \@hypSegs, "OneSecond Collar");
computeAndPrintScores(\@scorableSegs_twoSecs, \@hypSegs, "TwoSecond Collar");
print "\n";


#### - - - - - - - - - - - -
# Next, compute the sums that are the inputs to the Miss Rate and the False Alarm Rate for this collarSize,
#       and then compute and print the Miss Rate and False Alarm Rate (also DCF as in eval plan).
sub computeAndPrintScores {
    my ($currSetOfRefSegs, $currSetOfHypSegs, $collarSize) = @_;   # The passed arguments

    my $speechTimeSum = 0.0;     # total Speech time
    
    my $truePositiveSum = 0.0;
    my $falseNegativeSum = 0.0;

    my $nonSpeechTimeSum = 0.0;    # total scored NonSpeech time
    
    my $trueNegativeSum = 0.0;
    
    my $falsePositiveSum = 0.0;
    
    ## Note: The ref segs are all contiguous (i.e., they cover the ref time)
    ##       and likewise the hyp segs are all contiguous.
    
    ## Advancing the currScoringTime marks out the time interval
     # . . . that is currently being scored,
     # . . . extending from prevScoringTime through currScoringTime,
     # . . . (which will be scored as defined by currRefState and currHypState)
    my $prevScoringTime = 0.0;
    my $currScoringTime = 0.0;
    my $currRefState = "undefined";
    my $currHypState = "undefined";  
    
    ## We will score up through the last endTime that occurs in ref.
    my $endScoredTime = $$currSetOfRefSegs[scalar(@$currSetOfRefSegs)-1][1];
    
    my $hypIdx = 0;
    my $maxHypIdx = scalar(@$currSetOfHypSegs) - 1;
    
    my $refIdx = 0;
    my $maxRefIdx = scalar(@$currSetOfRefSegs) - 1;
    
    while($currScoringTime < $endScoredTime) {
       # Each time through this loop, there are four seg boundaries to consider:
       # (1) start of ref seg
       # (2) end of ref seg 
       # (3) start of hyp seg
       # (4) end of hyp seg
       # Number 2 is always greater than 1, and likewise 4 greater than 3,
       # . . . but we don't know anything about the existing ordering of 1 vs 3 or 4,
       # . . . nor anything about the existing order of 2 vs 3 or 4.
       # We have already scored all time up through currScoringTime.
       # Because the segs are contiguous, the hyp seg and/or ref seg already begins at currScoringTime.
       # Similarly, the end of the interval to be scored is whichever of the four seg boundaries
       # . . . exceeds currScoringTime by the least.
    
        $prevScoringTime = $currScoringTime;

       # The following if/elsif/else will always advance currScoringTime.
       # It should also set currHypState and currRefState correctly.
        if ($$currSetOfHypSegs[$hypIdx][0] < $$currSetOfRefSegs[$refIdx][0]) {
            # start time of hyp seg is not later than start time of ref seg or end time of ref seg
            $currScoringTime == $$currSetOfRefSegs[$refIdx][0];
            $currRefState = $$currSetOfRefSegs[$refIdx][2];
    
            # The end of the interval to be scored is the end of hyp seg or of ref seg, whichever is less
            if ($$currSetOfHypSegs[$hypIdx][1] <= $$currSetOfRefSegs[$refIdx][1]) {
                $currScoringTime = $$currSetOfHypSegs[$hypIdx][1];
                $hypIdx += 1 if $hypIdx < $maxHypIdx;
            } else {
                $currScoringTime = $$currSetOfRefSegs[$refIdx][1];
                $refIdx += 1 if $refIdx < $maxRefIdx;
            }
        } elsif ($$currSetOfHypSegs[$hypIdx][0] > $$currSetOfRefSegs[$refIdx][0]) {
            # start of ref seg is not later than start of hyp seg or end of hyp seg
            $currScoringTime == $$currSetOfHypSegs[$hypIdx][0];
            $currHypState = $$currSetOfHypSegs[$hypIdx][2];
    
            # The end of the interval to be scored is the end of hyp seg or of ref seg, whichever is less
            if ($$currSetOfHypSegs[$hypIdx][1] <= $$currSetOfRefSegs[$refIdx][1]) {
                $currScoringTime = $$currSetOfHypSegs[$hypIdx][1];
                $hypIdx += 1 if $hypIdx < $maxHypIdx;
            } else {
                $currScoringTime = $$currSetOfRefSegs[$refIdx][1];
                $refIdx += 1 if $refIdx < $maxRefIdx;
            }
        } else {   # $$currSetOfHypSegs[$hypIdx][0] == $$currSetOfRefSegs[$refIdx][0], and both == currScoringTime
            $currRefState = $$currSetOfRefSegs[$refIdx][2];
            $currHypState = $$currSetOfHypSegs[$hypIdx][2];
    
            # The end of the interval to be scored is the end of hyp seg or of ref seg, whichever is less
            if ($$currSetOfHypSegs[$hypIdx][1] <= $$currSetOfRefSegs[$refIdx][1]) {
                $currScoringTime = $$currSetOfHypSegs[$hypIdx][1];
                $hypIdx += 1 if $hypIdx < $maxHypIdx;
            } else {
                $currScoringTime = $$currSetOfRefSegs[$refIdx][1];
                $refIdx += 1 if $refIdx < $maxRefIdx;
            }
        }

        # We are done with this time through the while loop if the ref segment is a collar.
        next if $currRefState eq "Collar";
    
        # If we get here, the ref seg must be Speech or NonSpeech
        my $segDur = $currScoringTime - $prevScoringTime;
        if ($currRefState eq "Speech") {
            $speechTimeSum += $segDur;
            if ($currHypState eq "Speech") {
                $truePositiveSum += $segDur;
            } elsif ($currHypState eq "NonSpeech") {
                $falseNegativeSum += $segDur;
            } else {
                print "***** $currScoringTime $prevScoringTime Error1: currRefState $currRefState and currHypState $currHypState ******* \n";
            } 
        } elsif ($currRefState eq "NonSpeech") {
            $nonSpeechTimeSum += $segDur;
            if ($currHypState eq "NonSpeech") {
                $trueNegativeSum += $segDur;
            } elsif ($currHypState eq "Speech") {
                $falsePositiveSum += $segDur;
            } else {
                print "***** Error2: currRefState $currRefState and currHypState $currHypState ******* \n";
            } 
        } else {
            print "***** Error3: currRefState $currRefState and currHypState $currHypState ******* \n";
        }
    }
    
    
    
    #### - - - - - - - - - - - -
    # Compute and print the official scores for this combination of hyp and ref, for this collarSize
    
    print "\n    Scores with $collarSize\n";
    
    printf "\t      Prob_Miss == %7.5f   (%7.3f / %7.3f)\n",
                         $falseNegativeSum / $speechTimeSum,  $falseNegativeSum,  $speechTimeSum;
    printf "\tProb_FalseAlarm == %7.5f   (%7.3f / %7.3f)\n\n",
                         $falsePositiveSum / $nonSpeechTimeSum,  $falsePositiveSum,  $nonSpeechTimeSum;
    printf "\t            DCF == %7.5f   ((0.75 * %7.5f) + (0.25 * %7.5f))\n",
                     ((0.75*($falseNegativeSum/$speechTimeSum)) + (0.25*($falsePositiveSum/$nonSpeechTimeSum))),
                                   $falseNegativeSum/$speechTimeSum,
                                                $falsePositiveSum/$nonSpeechTimeSum;
     
}

