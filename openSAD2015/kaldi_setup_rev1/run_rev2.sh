#! /bin/bash

. cmd.sh 
. path.sh 

## Prepare data:

# Train set:
# we assume that all the wav.scp files already exist. 
echo "assuming wav.scp already exists in data/train_* dirs"
for channel in B D E F G H; do
    echo "preparing train data for channel: $channel"
    python local/create_segments_summary.py $channel mode_train
    python local/create_textANDsegmentsANDutt2spk.py $channel mode_train
    utils/utt2spk_to_spk2utt.pl data/train_$channel/utt2spk > data/train_$channel/spk2utt 
done;

# Test set:
for channel in B D E F G H; do
    echo "preparing test data for channel: $channel"
    python local/create_segments_summary.py $channel mode_test
    python local/create_textANDsegmentsANDutt2spk.py $channel mode_test
    utils/utt2spk_to_spk2utt.pl data/test_$channel/utt2spk > data/test_$channel/spk2utt
done;


## Train HMM for each channel:
mfcc_dir=/erasable/nxs113020/mfcc

for channel in B D E F G H; do
    echo "training channel: $channel"
    steps/make_mfcc.sh --nj 200 --cmd "$train_cmd" data/train_$channel exp/make_mfcc/train_$channel $mfcc_dir
    steps/compute_cmvn_stats.sh data/train_$channel exp/make_mfcc/train_$channel $mfcc_dir
    steps/train_mono.sh  --nj 50 --cmd "$train_cmd" data/train_$channel data/lang exp/mono_$channel
    utils/mkgraph.sh --mono data/lang exp/mono_$channel exp/mono_$channel/graph 
done;

## Decode:

# Extract test features:
for channel in B D E F G H; do
    steps/make_mfcc.sh --nj 30 --cmd "$train_cmd" data/test_$channel exp/make_mfcc/test_$channel $mfcc_dir
    steps/compute_cmvn_stats.sh data/test_$channel exp/make_mfcc/test_$channel $mfcc_dir
done;

for channel in B D E F G H; do
    steps/decode.sh --nj 10 --cmd "$train_cmd" exp/mono_$channel/graph data/test_$channel exp/mono_$channel/decode_toydev
done;
