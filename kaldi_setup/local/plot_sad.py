#! /usr/bin/python 

import sys
sys.path.append('/scratch/nxs113020/speech_activity_detection/unsupervised_sad')

import audio_tools

if __name__=='__main__':
    """ system arguements:
        1: wav filename
        2: sad filename
        3: sampling rate(optional)
        4: frame length(optional)
        5: frame shift(optional)
        """
    wav_fn = sys.argv[1]
    vad_fn = sys.argv[2]
    try:
        fs = sys.argv[3]
    except:
        fs = 16000
    try: 
        winlen = sys.argv[4]
    except:
        winlen = (fs*0.025)
    try: 
        hoplen = sys.argv[5]
    except:
        hoplen = (fs*0.01)
    mode = 'ark'
    audio_tools.plot_vad(wav_fn, vad_fn, winlen, hoplen, mode)

