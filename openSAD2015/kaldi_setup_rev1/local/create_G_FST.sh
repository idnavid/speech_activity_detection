#! /bin/bash
lang=data/lang
penalty=`perl -e '$prob = 1.0/4; print -log($prob); '` # negated log-prob,
  # which becomes the cost on the FST.
( for x in `echo NS NT RX S`; do
   echo 0 0 $x $x $penalty   # format is: from-state to-state input-symbol output-symbol cost
 done 
 echo 0 $penalty # format is: state final-cost
) | fstcompile --isymbols=$lang/words.txt --osymbols=$lang/words.txt \
   --keep_isymbols=false --keep_osymbols=false |\
   fstarcsort --sort_type=ilabel > $lang/G.fst
