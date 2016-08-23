#! /bin/bash

. path.sh
. cmd.sh

num_jobs=300
ubmdim=512

run_mfcc(){
    mfccdir=/erasable/nxs113020/mfcc
    if [ -d mfccdir ]; then
        mkdir -p $mfccdir
    fi
    
    for x in tst; do
        steps/make_mfcc.sh --nj $num_jobs --cmd "$train_cmd" \
         data/$x exp/make_mfcc/$x $mfccdir
        steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
    done
}
run_mfcc

run_unsupervised_sad(){
    for x in tst; do
       local/compute_vad_decision.sh $num_jobs "$train_cmd" \
         data/$x
    done
}
#run_unsupervised_sad

train_diag_gmms(){
    num_jobs_gmm=100
    data_dir=data/dev_2
    #ubmdim=64
    
    # train speech model
    local/train_diag_ubm.sh --nj $num_jobs_gmm --cmd "$train_cmd" $data_dir ${ubmdim} \
      exp/diag_spch_gmm_${ubmdim}

    # train nonspeech model
    mv $data_dir/vad.scp $data_dir/vad.scp.tmp
    cp $data_dir/vad.n.scp $data_dir/vad.scp
    local/train_diag_ubm.sh --nj $num_jobs_gmm --cmd "$train_cmd" $data_dir ${ubmdim} \
      exp/diag_nspch_gmm_${ubmdim}
    mv $data_dir/vad.scp.tmp $data_dir/vad.scp
}
#train_diag_gmms


run_supervised_sad() {

    for x in toy_tst;do
        add-deltas scp:data/$x/feats.scp ark,t:- | gmm-global-get-frame-likes \
          exp/diag_spch_gmm_${ubmdim}/final.dubm ark:- ark:exp/diag_spch_gmm_${ubmdim}/spch.llk.tmp
         
        add-deltas scp:data/$x/feats.scp ark,t:- | gmm-global-get-frame-likes \
          exp/diag_nspch_gmm_${ubmdim}/final.dubm ark:- ark:exp/diag_nspch_gmm_${ubmdim}/nspch.llk.tmp
        
        src/bin/compareLogLikelihoods ark:exp/diag_spch_gmm_${ubmdim}/spch.llk.tmp \
          ark:exp/diag_nspch_gmm_${ubmdim}/nspch.llk.tmp ark,t:exp/diag_spch_gmm_${ubmdim}/sad_scores.ark
    done
}
#run_supervised_sad
