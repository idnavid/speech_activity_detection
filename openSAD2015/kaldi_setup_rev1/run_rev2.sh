#! /bin/bash

. cmd.sh 
. path.sh 

## Prepare data:

# Train set:
# we assume that all the wav.scp files already exist. 
echo "assuming wav.scp already exists in data/train_* dirs"
for channel in D; do
    echo "preparing train data for channel: $channel"
    python local/create_segments_summary.py $channel mode_train
    python local/create_textANDsegmentsANDutt2spk.py $channel mode_train
    utils/utt2spk_to_spk2utt.pl data/train_$channel/utt2spk > data/train_$channel/spk2utt 
done;

# Test set:
for channel in D; do
    echo "preparing test data for channel: $channel"
    cat data/test_$channel/wav.scp | cut -d ' ' -f 1 | perl -ne 'if(m/(\S+)/){print "$1 $1\n"}' > data/test_$channel/utt2spk
    cp data/test_$channel/utt2spk data/test_$channel/spk2utt
done;


## Train HMM for each channel:
mfcc_dir=/erasable/nxs113020/mfcc

for channel in D; do
    echo "training channel: $channel"
    steps/make_mfcc.sh --nj 200 --cmd "$train_cmd" data/train_$channel exp/make_mfcc/train_$channel $mfcc_dir
    steps/compute_cmvn_stats.sh data/train_$channel exp/make_mfcc/train_$channel $mfcc_dir
    steps/train_mono.sh  --nj 50 --cmd "$train_cmd" data/train_$channel data/lang exp/mono_$channel
    utils/mkgraph.sh --mono data/lang exp/mono_$channel exp/mono_$channel/graph 
done;

time(10)
## Decode:

# Extract test features:
for channel in B; do
    steps/make_mfcc.sh --nj 15 --cmd "$train_cmd" data/test_$channel exp/make_mfcc/test_$channel $mfcc_dir
    steps/compute_cmvn_stats.sh data/test_$channel exp/make_mfcc/test_$channel $mfcc_dir
done;


for channel in B; do
    steps/decode.sh --nj 10 --cmd "$train_cmd" exp/mono_$channel/graph data/test_$channel exp/mono_$channel/decode_toydev

    # Create hypothetic text sequency using decoding output (log files)
    cat exp/mono_$channel/decode_toydev/log/decode.* | grep "_" | grep -v "LOG" | grep -v "-" | sort > data/test_$channel/text

    # align test data using hypothetical text file:
    # There has to be one alignment job, since the text file wasn't split. 
    steps/align_si.sh --nj 1 --cmd "$train_cmd" data/test_$channel data/lang exp/mono_$channel exp/mono_${channel}_ali

    gunzip exp/mono_${channel}_ali/ali.1.gz
    ali-to-phones --per-frame=true exp/mono_${channel}_ali/final.mdl ark:exp/mono_${channel}_ali/ali.1 ark,t:exp/mono_${channel}_ali/phones.1.tra

    utils/int2sym.pl -f 2- data/lang/phones.txt exp/mono_${channel}_ali/phones.1.tra > exp/mono_${channel}_ali/perframe_phonesequence.txt

    python local/generate_system_outputs.py exp/mono_${channel}_ali/perframe_phonesequence.txt
done


#. utils/parse_options.sh
#dnn_mem_reqs="mem_free=1.0G,ram_free=0.2G"
#dnn_extra_opts="--num-epochs 20 --num-epochs-extra 10 --add-layers-period 1"
#for channel in D; do
#    steps/train_lda_mllt.sh 24 1000 data/train_$channel data/lang exp/mono_${channel}_ali exp/mono_${channel}_ali2
#    steps/nnet2/train_tanh_fast.sh --mix-up 8000 --initial-learning-rate 0.01 --final-learning-rate 0.001 --num-jobs-nnet 16 --num-hidden-layers 4 --hidden-layer-dim 1024 --cmd "$train_cmd" data/train_$channel data/lang exp/mono_${channel}_ali2 exp/nnet_$channel
#done;
