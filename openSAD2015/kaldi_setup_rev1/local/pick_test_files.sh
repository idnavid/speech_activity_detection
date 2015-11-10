#! /bin/bash


wav_files=/scratch2/share/nxs113020/SAD-2015-Challenge-Data/LDC2015E97_NIST_OpenSAD15_Development/data/dev-2/wav/*/*.wav

for channel in B D E F G H; do
    ls $wav_files | grep "_$channel.wav" | head -n 30 > dev_$channel.txt
    if [ "$channel" = "H" ]; then
        ls $wav_files | grep "_$channel.wav" | head -n 16 > dev_$channel.txt
    fi;
done;
