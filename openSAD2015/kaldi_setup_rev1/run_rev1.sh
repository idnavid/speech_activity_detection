#!/bin/bash
# This script is written using the kaldi tutorial and attempts to perform ASR 
# the most required files. The assumption is that we have nothing in our disposal
# aside from the most basic files, which are:
# 
# The following for data preparation:
# text
# wav.scp
# utt2spk
# 
# And the following for preparing the language model:
# extra_questions.txt  
# lexicon.txt 
# nonsilence_phones.txt  
# optional_silence.txt  
# silence_phones.txt
# 
# Everything else is generated in this script. 
# 
# Navid Shokouhi
. cmd.sh 
. path.sh 
LC_ALL=C

###############################################################################
## data preparation:


# Step 1: generate spk2utt from utt2spk
utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt


# Step 2: generate feat.scp file as well as features. 
# This file is like wav.scp, except that it points to features. 
# Aside from feats.scp in data/train, this command also generates features
# in what I have called mfcc_dir bellow. 

mfcc_dir=/erasable/nxs113020/mfcc
steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/train exp/make_mfcc/train $mfcc_dir

#Note: you might see a lot of files in mfcc_dir, precisely nj files. My prediction 
#      is that the data is split and each of these is one chunk of it. 



# Step 3: The last file in the directory data/train is "cmvn.scp". 
# This also creates two other files in mfcc_dir. One is cmvn.ark and the other
# cmvn.scp. It's not hard to imagine what each of these contains. 

steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfcc_dir


# Step 4: unexplained steps
utils/fix_data_dir.sh data/train

# Step 5: Prepare evaluation data
utils/utt2spk_to_spk2utt.pl data/eval2000_mfcc/utt2spk > data/eval2000_mfcc/spk2utt
mfcc_dir=/erasable/nxs113020/mfcc/eval
steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/eval2000_mfcc exp/make_mfcc/eval $mfcc_dir

steps/compute_cmvn_stats.sh data/eval2000 exp/make_mfcc/eval2000 $mfcc_dir || exit 1;

utils/fix_data_dir.sh data/eval2000_mfcc # remove segments that had problems, e.g. too short.



## End of data preparation
###############################################################################
## language preparation:

# All the files mentioned for the language preparation step should be put in the 
# directory: data/local/dict



# Step 1: Prepare data/lang: the prepare_lang.sh script prepares the 
# directory data/lang and all the files it contains that are used to create
# the language model. It takes as input data/local/dict which we have prepared 
# using the files mentioned in the beginning for language preparation. 

local/swbd1_prepare_dict.sh
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

# Step 2: prepare language model. 
# So far, this is the only step that I haven't figured out how to simplify. It 
# seems like it's different for different databases. It shouldn't be, but we don't 
# need to worry about it. Since Lakshmish will be dealing with this part. 

local/swbd1_train_lms.sh data/train/text data/local/dict/lexicon.txt data/local/lm

# Create necessary files like G.fst
local/swbd_p1_format_data.sh

## End of language preparation
###############################################################################
## monophone training:

steps/train_mono.sh  --nj 8 --cmd "$train_cmd" data/train data/lang exp/mono
utils/mkgraph.sh --mono data/lang_test exp/mono exp/mono/graph

## End of monophone training
###############################################################################
## triphone training:

steps/align_si.sh --boost-silence 1.25 --nj 8 --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali
numLeavesTri1=2500
numGaussTri1=15000
steps/train_deltas.sh --cmd "$train_cmd" $numLeavesTri1 $numGaussTri1 data/train data/lang exp/mono_ali exp/tri1


###############################################################################
## decoding: 

# Prepare evaluation data
mfcc_dir=/erasable/nxs113020/mfcc/eval
steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/eval2000_mfcc exp/make_mfcc/eval $mfcc_dir

# For now, I borrowed data/lang_test from /scratch2/share/axs056200/swb_kaldi/data/lang_test
utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph

steps/decode.sh --nj 8 --cmd "run.pl" --config conf/decode.config exp/tri1/graph data/eval2000_mfcc exp/tri1/decode_eval2000


## End of triphone training
###############################################################################
## triphone training: LDA + MLLT
steps/align_si.sh --boost-silence 1.25 --nj 8 --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali

steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 20000 data/train data/lang exp/tri1_ali exp/tri2


utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph
steps/decode.sh --nj 8 --cmd "run.pl" --config conf/decode.config exp/tri2/graph data/eval2000_mfcc exp/tri2/decode_eval2000

## End of triphone training w/ LDA + MLLT
###############################################################################
## triphone training: SAT 

steps/align_fmllr.sh --nj 8 --cmd "$train_cmd" data/train data/lang exp/tri2 exp/tri2_ali

steps/train_sat.sh  --cmd "$train_cmd" 2500 20000 data/train data/lang exp/tri2_ali exp/tri3

utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph

steps/decode_fmllr.sh --nj 8 --cmd "$decode_cmd" --config conf/decode.config exp/tri3/graph data/eval2000_mfcc exp/tri3/decode_eval2000

## End of triphone training w/ LDA + MLLT
###############################################################################
## triphone training: larger SAT (sgmm)

steps/align_fmllr.sh --nj 8 --cmd "$train_cmd" data/train data/lang exp/tri3 exp/tri3_ali

local/run_sgmm_rev1.sh

# build larger SAT
steps/train_sat.sh --cmd "$train_cmd" 3500 100000 data/train data/lang exp/tri3_ali exp/tri5

utils/mkgraph.sh data/lang_test exp/tri5 exp/tri5/graph

steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj 8 exp/tri5/graph data/eval2000_mfcc exp/tri5/decode_eval2000

## End of triphone training larger SAT (sgmm)
###############################################################################
## MMI from latest models

steps/align_fmllr.sh --nj 8 --cmd "$train_cmd" data/train data/lang exp/tri5 exp/tri5_ali

steps/make_denlats.sh --nj 8 --cmd "$decode_cmd" --transform-dir exp/tri5_ali --config conf/decode.config --sub-split 50 data/train data/lang exp/tri5 exp/tri5_denlats

steps/train_mmi.sh --cmd "$decode_cmd" --boost 0.1 data/train data/lang exp/tri5_{ali,denlats} exp/tri5a_mmi_b0.1

steps/decode.sh --nj 8 --cmd "$decode_cmd" --config conf/decode.config --transform-dir exp/tri5/decode_eval2000 exp/tri5/graph data/eval2000_mfcc exp/tri5a_mmi_b0.1/decode_eval2000


steps/train_diag_ubm.sh --silence-weight 0.5 --nj 8 --cmd "$train_cmd" 700 data/train data/lang exp/tri5_ali exp/tri5_dubm


steps/train_mmi_fmmi.sh --learning-rate 0.005  --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri5_ali exp/tri5_dubm exp/tri5_denlats exp/tri5a_fmmi_b0.1


for iter in 4 5 6 7 8; do
  steps/decode_fmmi.sh --nj 8 --cmd "$run.pl" --iter $iter --config conf/decode.config --transform-dir exp/tri5/decode_eval2000 exp/tri5/graph data/eval2000_mfcc exp/tri5a_fmmi_b0.1/decode_eval2000_it$iter
done


#  Indirect differential (?: I don't know what this is)
steps/train_mmi_fmmi_indirect.sh --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri5_ali exp/tri5_dubm exp/tri5_denlats exp/tri5a_fmmi_b0.1_indirect


for iter in 4 5 6 7 8; do
  steps/decode_fmmi.sh --nj 8 --cmd "run.pl" --iter $iter --config conf/decode.config --transform-dir exp/tri5/decode_eval2000 exp/tri5/graph data/eval2000_mfcc exp/tri5a_fmmi_b0.1_indirect/decode_eval2000_it$iter
done



## End of MMI
###############################################################################
## DNN training:
# DNN hybrid system training parameters

dnn_mem_reqs="mem_free=1.0G,ram_free=0.2G"
dnn_extra_opts="--num-epochs 20 --num-epochs-extra 10 --add-layers-period 1"
. utils/parse_options.sh
#steps/nnet2/train_tanh_fast.sh --mix-up 8000 --initial-learning-rate 0.01 --final-learning-rate 0.001 --num-jobs-nnet 16 --num-hidden-layers 4 --hidden-layer-dim 1024 --cmd "$train_cmd" data/train data/lang exp/tri5 exp/nnet5a

# Wasn't able to run p-norm
steps/nnet2/train_pnorm_fast.sh --mix-up 8000 --initial-learning-rate 0.01 --final-learning-rate 0.001 --num-jobs-nnet 16 --num-hidden-layers 4 --cmd "$train_cmd" data/train data/lang exp/tri5 exp/nnet5b


steps/nnet2/decode.sh --cmd "run.pl" --nj 8 --config conf/decode_dnn.config --transform-dir exp/tri5/decode_eval2000 exp/tri5/graph data/eval2000_mfcc exp/nnet5a/decode_eval2000

## End of DNN
###############################################################################
## post-DNN ? 

steps/nnet2/decode.sh --cmd "run.pl" --nj 8 --config conf/decode_dnn.config --transform-dir exp/tri5/decode_eval2000 exp/tri5/graph data/eval2000_mfcc exp/nnet5a_ali/decode_eval2000
