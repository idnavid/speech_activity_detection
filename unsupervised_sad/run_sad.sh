#!/bin/bash

wavlist=$1
cfg_fn=$PWD/config_sad


outdir=/erasable/nxs113020/sad_results_`basename ${wavlist%.*}`
outformat="idx"
mkdir -p $outdir

if [ -f combosad_jobs.txt ]; then
    rm combosad_jobs.txt
fi
touch combosad_jobs.txt

for wav_fn in `cat $wavlist`; do
  stm_fn=$outdir/`basename ${wav_fn%.*}.stm`
  #echo "sad.py $wav_fn $cfg_fn $stm_fn $outformat"
  echo "python $PWD/sad.py $wav_fn $cfg_fn $stm_fn $outformat" >> combosad_jobs.txt
done




