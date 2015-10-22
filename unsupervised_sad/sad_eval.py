#!/usr/local/env python

from misc_routines import read_stm
import numpy as np
import sys, pdb

def sad_eval(hyp_stm_fn, ref_stm_fn, fs):
        
    ref_stm_dic = read_stm(ref_stm_fn)
    hyp_stm_dic = read_stm(hyp_stm_fn)

    # discover common file names to be compared
    ref_fnames = sorted(ref_stm_dic.keys())
    hyp_fnames = sorted(hyp_stm_dic.keys())
    common_fnames = sorted(list(set(ref_fnames) & set(hyp_fnames)))
    if (common_fnames != hyp_fnames) or (common_fnames != ref_fnames):
        print 'WARNING! Number of files in ref and hyp STMS do not match !'
        print 'Performing error analysis only on common filenames...' 
        
    # count true/false decisions for each common filename       
    n_true_positive = 0
    n_true_negative = 0
    n_false_positive = 0
    n_false_negative = 0
    for fname in common_fnames:        
        ref_stm = ref_stm_dic[fname]
        hyp_stm = hyp_stm_dic[fname]    
        siglen = max(int(ref_stm[-1][1] * fs), int(hyp_stm[-1][1] * fs))
        ref = np.zeros(siglen)
        for t1, t2, uttid in ref_stm:
            n1 = int(t1 * fs)
            n2 = int(t2 * fs)
            ref[n1:n2] = 1        
        hyp = np.zeros(siglen)
        for t1, t2, uttid in hyp_stm:
            n1 = int(t1 * fs)
            n2 = int(t2 * fs)
            hyp[n1:n2] = 1
    
        n_true_positive += sum((ref == 1) & (hyp == 1))
        n_true_negative += sum((ref == 0) & (hyp == 0))
        n_false_positive += sum((ref == 0) & (hyp == 1))
        n_false_negative += sum((ref == 1) & (hyp == 0))
   
    pdb.set_trace()
    # error analysis        
    precision = float(n_true_positive) / (n_true_positive + n_false_positive)
    recall = float(n_true_positive) / (n_true_positive + n_false_negative)
    F1 = 2 * precision * recall / (precision + recall)
    
    ref_speech_time = float(sum(ref == 1)) / fs
    true_hyp_speech_time = float(n_true_positive) / fs
    false_hyp_speech_time = float(n_false_positive) / fs
    
    print 'F1 score is %s' % F1
    print 'out of %s seconds of reference speech, %s seconds were correctly recognized as speech' \
           % (ref_speech_time, true_hyp_speech_time)
    print 'total %s seconds of false speech insertion' % false_hyp_speech_time
    
     
if __name__ == '__main__':
    hyp_stm_fn = sys.argv[1]
    ref_stm_fn = sys.argv[2]
    fs = int(sys.argv[3])
    sad_eval(hyp_stm_fn, ref_stm_fn, fs)
    
        
    
