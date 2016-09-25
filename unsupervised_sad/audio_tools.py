#! /usr/bin/python 
import numpy as np
from scipy.io import wavfile
import sys
import os
sys.path.append("/scratch/nxs113020/speech_activity_detection/unsupervised_sad")
import sad as sad_tools

def enframe_list(s_list, win, inc):
    """enframe: Break input list into frames of length win. The frames
    are overlapped by the amount of win-inc.
    The name was inspired by the enframe MATLAB function provided in voicebox.
    Inputs: (s_list, win, inc)
        s_list:     input list
        win:        frame length
        inc:        increment of next frame with respect to the start point of the previous frame
    Output:
        frames:     list of lists. The inner lists are the frames
    """
    win1=int(win)
    inc1=int(inc)
    s_temp=s_list[:]#prevent changing the original list
    n_samples=len(s_temp)
    n_frames=n_samples/inc1
    #zeropad in case of mismatch (i.e. ((n_frames*inc1+win1)-n_samples)~=0).
    for z in range(((n_frames*inc1+win1)-n_samples)):
        s_temp.append(0.0)
    frames=[[]]*n_frames
    for i in range(n_frames):
        frames[i]=s_temp[i*inc1:i*inc1+win1]
    return frames


#===============================================================================
def enframe(x, winlen, hoplen):
    '''
    receives a 1D numpy array and divides it into frames.
    outputs a numpy matrix with the frames on the rows.
    '''
    x = np.squeeze(x)
    if x.ndim != 1: 
        raise TypeError("enframe input must be a 1-dimensional array.")
    n_frames = 1 + np.int(np.floor((len(x) - winlen) / float(hoplen)))
    xf = np.zeros((n_frames, winlen))
    for ii in range(n_frames):
        xf[ii] = x[ii * hoplen : ii * hoplen + winlen]
    return xf    


#===============================================================================
def deframe(x_frames, winlen, hoplen):
    '''
    interpolates 1-dimensional framed data into persample values. 
    '''
    n_frames = len(x_frames)
    n_samples = n_frames*hoplen + winlen
    x_samples = np.zeros((n_samples,1))
    for ii in range(n_frames):
        x_samples[ii*hoplen : ii*hoplen + winlen] = x_frames[ii]
    return x_samples

def read_ark_vad(vad_fn):
    vad_dict = {}
    fvad = open(vad_fn)
    for i in fvad:
        vadid = i.split('[')[0].strip()
        vad_scores = i.split('[')[1].split(']')[0].strip()
        vad_scores_list = []
        for j in vad_scores.split(' '):
            if (j!=''):
                vad_scores_list.append(float(j.strip()))
        vad_scores_array = np.array(vad_scores_list)
        vad_scores_array = sad_tools.smooth_sad_decisions(vad_scores_array, 11)
        vad_scores_array[np.where(vad_scores_array>0)] = 1
        vad_scores_array[np.where(vad_scores_array<1)] = 0
        vad_dict[vadid] = vad_scores_array
    return vad_dict
            

#===============================================================================
def sph2wav(wavscp_line,output_wavname = 'tmp.wav'):
    '''
    For when  the input wav.scp file contains a sph2pipe command instead 
    of a direct path to a wav-file. 
    example:
        [uttid] sph2pipe [filename].sph -c 1 -f wav | 
    '''
    command = ''
    for k in wavscp_line.strip().split(' ')[1:]:
        if k == '|':
            k = '> '
        command += k.strip()+' '
    command += output_wavname
    os.system(command)
    return output_wavname
                
#===============================================================================
def plot_vad(wav_fn, vad_fn, winlen, hoplen, mode):
    '''
    Plot VAD labels alongside signal for comparison. This tool helps to run 
    a sanity check on the VAD outputs. This code only works on the index style
    vad labels. 
    '''
    import pylab
    if mode == 'ark':
        """ Read wav.scp and corresponding scores. 
            This script plots all VAD scores for files in wav.scp.
            wav_fn: wav.scp file
            vad_fn: VAD scores for each utterance in ark,t format
            """
        vad_files = read_ark_vad(vad_fn)
        fwav = open(wav_fn)
        wavs = {}
        for i in fwav:
            uttid = i.split(' ')[0]
            uttfile = i.split(' ')[1].strip()
            if 'sph2pipe' in i:
               uttfile = sph2wav(i)
            if (uttfile == 'sox'):
                sox_command = ''
                for j in i.split(' ')[1:]:
                    if (j.strip() == '|'):
                        j = '>'
                    sox_command += j+' '
                print sox_command
                os.system(sox_command+' wav_dump/tmp.wav')
                uttfile = 'wav_dump/tmp.wav'
            wavs[uttid] = uttfile
            vad_samples = deframe(vad_files[uttid],winlen,hoplen)
            fs, s = wavfile.read(wavs[uttid])
            N1 = 300000
            N2 = N1 + 1000000
            s = s[N1:N2]
            pylab.plot(s/float(max(abs(s))))
            pylab.plot(vad_samples[N1:N2]/float(max(abs(vad_samples[N1:N2])))+0.01,'r')
            pylab.show()
        return 0
    
    vad_idx = []    
    f_vad = open(vad_fn)
    for i in f_vad:
        vad_idx.append(int(i.strip()))
    f_vad.close()
    
    vad = np.zeros((max(vad_idx)+1,1))
    for i in vad_idx:
        vad[i] = 1
    
    vad_samples = deframe(vad,winlen,hoplen)
    fs, s = wavfile.read(wav_fn)
    pylab.plot(s/float(max(abs(s))))
    pylab.plot(vad_samples,'r')
    pylab.show()
    return 0



if __name__=='__main__':
    pass

