#! /usr/bin/python 
import numpy as np

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
    if x.ndim != 1: raise TypeError("enframe input must be a 1-dimensional array.")
    n_frames = 1 + np.int(np.floor((len(x) - winlen) / float(hoplen)))
    xf = np.zeros((n_frames, winlen))
    for ii in range(n_frames):
        xf[ii] = x[ii * hoplen : ii * hoplen + winlen]
    return xf    



if __name__=='__main__':
    pass
