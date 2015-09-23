#!/usr/local/env python

import sys, pdb
import os
import pickle
import numpy as np
from scipy.io import wavfile
import scipy.signal as sg
from sklearn.mixture import GMM
from common import write_stm, write_idx, parse_config_file
import matplotlib.pyplot as plt
from combosad_feats import combosad_feats


def sad(wav_fn, cfg_fn, stm_fn, output_mode):

    fname = os.path.splitext(os.path.basename(wav_fn))[0]
    # read config file
    cfg = parse_config_file(cfg_fn)
    hoplen = int(cfg['hoplen'] * cfg['fs'])
    
    #===========================================================================
    # Feature extraction
    print 'extracting SAD features...'
    fs, wav = wavfile.read(wav_fn)
    wav = np.asarray(wav, dtype='float64') / max(abs(wav))
    wav = preprocess(wav[:,np.newaxis], fs, 25.0).squeeze()
    feats = combosad_feats(wav, cfg)

    #===========================================================================
    # find threshold
    gmm = GMM(n_components = 2)
    gmm.fit(feats)
    m1 = min(gmm.means_)
    m2 = max(gmm.means_)
    weight = 0.5
    thr = weight * m1 + (1 - weight) * m2
    
    #===========================================================================
    # make decisions and write output stm file
    labs = feats > thr
    labs = labs.squeeze()
    labs = smooth_sad_decisions(labs, 1)
    if output_mode == 'stm':
        tmp_segs = lbls_to_segs(labs, hoplen, cfg['fs'])
        segs = []
        for (t1, t2) in tmp_segs:
            t1_str = '{:07}'.format(t1).replace('.','')
            t2_str = '{:07}'.format(t2).replace('.','')
            uttid = '-'.join([fname, t1_str, t2_str])
            segs.append((t1, t2, uttid))
        write_stm(stm_fn, segs)
    if output_mode == 'idx':
        voiced_frames = np.where(labs==1)
        write_idx(stm_fn,voiced_frames[0])
    
    
    
    


def preprocess(sin, sr, snr):
	"""===================================
		add a small dither and remove DC
	======================================"""
	sout = np.zeros((len(sin), 1))
	alpha = 10**(snr/20)
	spow = sin.std()
	npow = spow/alpha
	slen = len(sin)
	np.random.seed(seed=1000)
	dither  = np.random.randn(slen, 1) + np.random.rand(slen, 1)
	sin += npow * dither/dither.std()
	fL = 300.0 / (sr/2)
	fH = 3500.0 / (sr/2)
	B, A = sg.butter(6, [fL, fH], btype = 'bandpass')
	sout = sg.lfilter(B, A, sin, axis = 0)
	return sout   
    
    

    
def smooth_sad_decisions(labs, smooth_len):
    '''
    Refines sad decisions by:
    1- applying a median filter
    2- applying a low-pass filter and repeating the hard-thresholding.
    '''
    b, a = sg.butter(3, 0.05)
    labs = sg.filtfilt(b,a,labs)    
    labs = 1*(labs > 0.5) # The multiplication by 1 is to convert to int
    labs = sg.medfilt(labs, smooth_len)
    
    
    return labs


def lbls_to_segs(x, hoplen, fs = 8000):
    # x :  list of SAD labels (1s and 0s)
    # hoplen: frame shift in samples
    # fs:  sampling frequency 
    # Use first difference
    x_diff = np.diff(x)
    
    # Locations of 1s (one) and -1s (none) in the diff array
    one_locs = np.where(x_diff == 1)[0]
    none_locs = np.where(x_diff == -1)[0]
    
    # find out which one is starts first
    first_one = min(one_locs)
    first_none = min(none_locs)
    if first_one > first_none: # in case segments starts with 1s
        one_locs = np.append([1],one_locs)

    # Generate list of voiced segment tuples
    segs = [] # (start,end)
    cte = hoplen / float(fs) 
    for i in range(len(one_locs)):
        try:
            segs.append((cte*one_locs[i],cte*none_locs[i]))
        except:
            segs.append((cte*one_locs[i],cte*x.size))
        
    return segs
    
    
if __name__ == '__main__':
    wav_fn, cfg_fn, stm_fn, output_mode = sys.argv[1:]
    sad(wav_fn, cfg_fn, stm_fn, output_mode)
