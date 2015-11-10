#! /bin/bash

# Temporary script to calculate false alarm and miss rate for different channels. 
for i in B D E F G H; do
    echo "channel $i"
    cat exp/mono_$i/decode_toydev/log/decode.* | grep -v 'LOG' | grep "_" | grep -v "-" > exp/scores_$i.txt 
    python ../py_code/score_output.py exp/scores_$i.txt data/test_$i/text 
done;

