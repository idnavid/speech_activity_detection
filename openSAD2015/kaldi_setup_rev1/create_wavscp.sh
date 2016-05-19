#! /bin/bash

for channel in B D E F G H; do
ls /scratch2/share/nxs113020/SAD-2015-Challenge-Data/LDC2015E96_NIST_OpenSAD15_Training/data/train/wav/*/*/*.wav | grep "_$channel.wav" | perl -ne 'if(m/\S+\/(\S+).wav/){print "$1 $_"}' | sort  > data/train_$channel/wav.scp
done;


for channel in A B C D E F G H XA XH XI XK XMT XN; do
    ls /scratch2/share/nxs113020/SAD-2015-Challenge-Data/LDC2015E98_NIST_OpenSAD15_Eval/data/progress/audio/*/*.wav | grep "_$channel.wav" | perl -ne 'if(m/\S+\/(\S+).wav/){print "$1 $_"}' | sort  > data/train_$channel/wav.scp
done;
