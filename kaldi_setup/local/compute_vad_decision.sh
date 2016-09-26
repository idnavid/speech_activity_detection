#!/bin/bash 


# Compute unsupervised combosad VAD output 
# We do this in just one job; it's fast.
#

nj=$1
cmd=$2
if [ -f path.sh ]; then . ./path.sh; fi
if [ -f cmd.sh ]; then . ./cmd.sh; fi
. utils/parse_options.sh || exit 1;

data=$3
## For cluster:
sad_dir=/scratch/nxs113020/speech_activity_detection/kaldi_setup/
## For local machine(s)
#sad_dir=/home/nxs113020/speech_activity_detection/kaldi_setup/

echo "***** Running unsupervised VAD on $data *****"
echo "      number of jobs: $nj"
echo "      mode $cmd"
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
cmd=$train_cmd
$cmd JOB=1:$nj $data/log/vad.JOB \
  $sad_dir/local/run_combosad.sh $sdata/JOB/wav.scp ark,scp:$sdata/JOB/vad_${name}.JOB.ark,$sdata/JOB/vad_${name}.JOB.scp \
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
