#!/bin/bash

wavlist=$1
cfg_fn=./config_sad


outdir=./sad_results_`basename ${wavlist%.*}`
outformat="idx"
mkdir $outdir
for wav_fn in `cat $wavlist`; do
  stm_fn=$outdir/`basename ${wav_fn%.*}.stm`
  echo "sad.py $wav_fn $cfg_fn $stm_fn $outformat"
  python sad.py $wav_fn $cfg_fn $stm_fn $outformat
done




