#!/bin/bash

scpFile=$1
configFile=$2

nj=100
cmd="./queue.pl -q all.q@compute-0-[123456]"

splitdir=~/split_scp
logdir=~/featgen_logs

# split the scp file into nj parts
[ -d $splitdir ] && rm -r $splitdir
python split_txt.py $scpFile $nj $splitdir
scp_basename=`basename $scpFile`
scp_extension=`echo $scp_basename | cut -s -d'.' -f2`
scp_filename=`echo $scp_basename | cut  -d'.' -f1`
split_scp_generic_name=`echo $splitdir/$scp_filename.JOB.$scp_extension | sed 's:\.$::'`


# run feature extraction
$cmd JOB=1:$nj $logdir/featgen.JOB.log \
  HCopy -C $configFile -S $split_scp_generic_name






