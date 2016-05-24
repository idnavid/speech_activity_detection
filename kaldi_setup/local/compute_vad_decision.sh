#!/bin/bash 

# Copyright    2013  Daniel Povey
# Apache 2.0
# To be run from .. (one directory up from here)
# see ../run.sh for example

# Compute energy based VAD output 
# We do this in just one job; it's fast.
#

nj=50
cmd=run.pl
if [ -f path.sh ]; then . ./path.sh; fi
if [ -f cmd.sh ]; then . ./cmd.sh; fi
. utils/parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "Usage: $0 [options] <data-dir> <log-dir> <path-to-vad-dir>";
   echo "e.g.: $0 data/train exp/make_vad mfcc"
   echo " Options:"
   echo "  --vad-config <config-file>                       # config passed to compute-vad-energy"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

data=$PWD/$1

# use "name" as part of name of the archive.
name=`basename $data`


for f in $data/feats.scp; do
  if [ ! -f $f ]; then
    echo "compute_vad_decision.sh: no such file $f"
    exit 1;
  fi
done

utils/split_data.sh $data $nj || exit 1;
sdata=$data/split$nj;

$cmd JOB=1:$nj log/vad.JOB \
  local/run_combosad.sh $sdata/JOB/wav.scp ark,scp:$sdata/JOB/vad_${name}.JOB.ark,$sdata/JOB/vad_${name}.JOB.scp \
  || exit 1;

for ((n=1; n<=nj; n++)); do
  cat $sdata/$n/vad_${name}.$n.scp || exit 1;
done > $data/vad.scp

cat $data/vad.scp | sort -u > $data/vad.scp.tmp
mv $data/vad.scp.tmp $data/vad.scp

for ((n=1; n<=nj; n++)); do
  cat $sdata/$n/vad_${name}.$n.scp.n || exit 1;
done > $data/vad.n.scp

cat $data/vad.n.scp | sort -u > $data/vad.n.scp.tmp
mv $data/vad.n.scp.tmp $data/vad.n.scp

nc=`cat $data/vad.scp | wc -l` 
nu=`cat $data/feats.scp | wc -l` 
if [ $nc -ne $nu ]; then
  echo "**Warning it seems not all of the speakers got VAD output ($nc != $nu);"
  echo "**validate_data_dir.sh will fail; you might want to use fix_data_dir.sh"
  [ $nc -eq 0 ] && exit 1;
fi


echo "Created VAD output for $name"
