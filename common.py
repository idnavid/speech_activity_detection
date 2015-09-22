#!/usr/bn/env python

import os
import sys
import shutil
import commands
import struct
import math
import numpy as np
import pdb


def split_list(l, n):
    ''' 
    splits a python list l into n parts
    '''
    part_size = int(len(l)/n)
    remainder = len(l) - n * part_size
    sizes = []
    for ii in xrange(n):
        if ii < remainder:
            sizes.append(part_size + 1)
        else:
            sizes.append(part_size)
    split_list = []        
    for ii in xrange(n):          
        split_list.append(l[sum(sizes[:ii]) : sum(sizes[:ii]) + sizes[ii]])
    return split_list

#===============================================================================
def subset_list(inputList, include_kws, exclude_kws):
    outputList = []
    for item in inputList:
        flag = True
        for kw in include_kws:
            if kw not in item:
                flag = False
        for kw in exclude_kws:
           if kw in item:
                flag = False
        if flag:
            outputList.append(item)
        
    return outputList
      
#===============================================================================
def parse_config_file(config_fn):
    '''
    parses a config file consisting of lines of the form param=x
    x can be an integer, a decimal number, or a string.
    lines beginning with '#' are discarded as comments
    only lines containing '=' are considered, and the rest are discarded
    as empty lines or comments
    '''
    config = {}
    fo_config = open(config_fn)
    for line in fo_config:
        if (line[0] != '#') and ('=' in line):
            temp=line.strip().split('=')
            key = temp[0].strip()
            val_str = temp[1].strip()
            # determine whether value is integer, decimal number, or string: 
            if val_str.isdigit():
                val = int(val_str)
            elif ('.' in val_str) and (val_str.replace('.','').isdigit()): 
                val = float(val_str)
            else:
                val = val_str    
            # add config dictionary element
            config[key]=val
    fo_config.close()        
    return config        
            

#=============================================================================== 
def read_scp(scp_fn):
    '''
    reads an input scp or lst file.
    returns a tuple of lists: (col0, col1, col2, ...)
    col_i is a list containing all entries of the i'th column of scp file.
    '''
    all_rows = []
    with open(scp_fn) as fo_scp:
        for line in fo_scp:
            temp=line.strip().split()
            all_rows.append(temp)      
    n_cols = len(all_rows[0])
    all_cols = []
    for ii in xrange(n_cols):
        all_cols.append([row[ii] for row in all_rows])      
    return tuple(all_cols)


#===============================================================================
def write_htk(feats, feat_fn, frame_period, parmkind):
    '''
    receives a 2D numpy array of MFCCs (each column is the MFCC vector of a frame),
    and writes it as a binary file (appending HTK headers).
    feats: numpy matrix of MFCCs
    feat_fn: output filename 
    sample_period: frame period of MFCCs (in seconds).
    parmkind: [decimal equivalent of] a 2-byte code encoding the feature type:
              bits 0-5:  feature kind (000110 for MFCCs, 001011 for PLP)
              bit 6:  _E (has energy)
              bit 7:  _N (absolute energy supressed)
              bit 8:  _D (has delta coefficients)
              bit 9:  _A (has accelaration coefficients)
              bit 10: _C (is comressed)
              bit 11: _Z (has zero-mean feature vectors, i.e. CMN applied)
              bit 12: _K (has CRC checksum)
              bit 13: _O (has 0'th cepstral coefficient)
              bit 14: _V (has VQ data) 
              bit 15: _T (has third differential coefficients)
    '''
    n_frames, n_mfccs = feats.shape
    bytes_per_scalar = 4
    bytesize = n_mfccs * bytes_per_scalar
    header = struct.pack('>iihh', n_frames, math.floor(frame_period/0.0000001),bytesize,parmkind)
    data = ''.join([struct.pack('>f',val) for val in feats.reshape(-1)])
    with open(feat_fn, 'wb') as fo_feat:
        fo_feat.write(header)
        fo_feat.write(data)

#===============================================================================
def read_htk(feat_fn):
    '''
    reads a HTK feature file and returns the data and the header information.
    feat_fn: input filename
    feats: 2D numpy matrix of size n_frames by n_mfccs
    header_info: dictionary containing header information    
    '''
    
    with open(feat_fn, 'rb') as fo_feat:
        header = fo_feat.read(12)
        data = fo_feat.read()
    n_frames, frame_period_100ns, bytesize, parmkind = struct.unpack('>iihh', header)
    bytes_per_scalar = 4
    n_mfccs = bytesize / bytes_per_scalar
    frame_period = frame_period_100ns * 0.0000001
    header_info = {'n_frames' : n_frames, 'frame_period' : frame_period,
                   'bytesize' : bytesize, 'parm_kind' : parmkind, 'n_mfccs' : n_mfccs}
    temp = struct.unpack('>' + 'f'*(n_frames * n_mfccs), data)
    feats = np.asarray(temp).reshape((n_frames, n_mfccs))                        
    return feats, header_info 

#===============================================================================
def write_stm(stm_fn, segs, min_dur=0.0):
    '''
    Receives a list of tuples containing segment information and writes 
    a corresponding STM file.
    current version assumes single channel (all channel labels are 1).
    It also assumes no speaker information (speaker name is the same as 
    utterance id for all utterances).
    '''
    with open(stm_fn, 'w') as fo_stm:
        for (t1, t2, uttid) in segs:
            fname = uttid.split('-')[0]
            if t2 - t1 > min_dur:
                line = ' '.join([fname, '1', fname, str(t1), str(t2), 'transcript!'])
                fo_stm.write(line+'\n')
    

#===============================================================================
def read_stm(stm_fn, min_duration = 0.0):
    with open(stm_fn) as fo_stm:
        all_stm_lines = fo_stm.read().splitlines()
    all_segments = {}
    for line in all_stm_lines:
        tmp = line.split()
        fname, chan, spkr, t1, t2 = tmp[:5]
        transcript = ' '.join(tmp[5:])
        t1_text = '{:07}'.format(float(t1)).replace('.','')
        t2_text = '{:07}'.format(float(t2)).replace('.','')
        t1 = float(t1)
        t2 = float(t2)
        uttid = '-'.join([fname, chan, t1_text, t2_text])
        if t2 - t1 > min_duration:
            if fname in all_segments:
                all_segments[fname].append((t1, t2, uttid))
            else:
                all_segments[fname] = [(t1, t2, uttid),]    
    return all_segments

#=============================================================================== 
def read_segments_file(segments_fn, min_duration = 0.0):
    '''
    reads a kaldi-style segments file.
    outputs a dictionary of the form:
    wavfile_name : (a list of tuples).
    each tuple in the list is of the form:
    (utt_Tstart, utt_Tend, uttid)
    Rejects segments shorter than min_duration
    '''
    
    with open(segments_fn) as fo_segments:
        all_lines = fo_segments.readlines()
        
    segments_info_dic = {}    
    for line in all_lines:
        uttid, wavname, Tstart, Tend = line.split()
        Tstart = float(Tstart)
        Tend = float(Tend)
        if Tend - Tstart > min_duration:
            if wavname in segments_info_dic:
                segments_info_dic[wavname].append((Tstart, Tend, uttid))
            else:
                segments_info_dic[wavname] = [(Tstart, Tend, uttid),]   
    return segments_info_dic
              

#=============================================================================== 
def extract_segments(wav, segments_info, fs): 
    '''
    wav: (1D numpy array or list) input signal
    segments info: list of tuples containing boundary information for utterances
                   each tuple is of the form: (Tstart, Tend, uttid)
    fs: sampling rate of wav
    returns a list of numpy arrays (each element is an utterance)              
    '''
    all_Nstarts = [int(tmp[0] * fs) for tmp in segments_info]
    all_Nends = [int(tmp[1] * fs) for tmp in segments_info]
    all_segs = [wav[N1:N2] for N1,N2 in zip(all_Nstarts, all_Nends)]
    return all_segs 

#===============================================================================
def write_mlf(labels_dic, mlf_fn):
    with open(mlf_fn, 'w') as fo_mlf:
        fo_mlf.write('#!MLF!#\n')
        for feat_fn, labels in labels_dic.iteritems():
            fo_mlf.write('"%s"\n' % feat_fn)
            labels = [str(ii) for ii in labels]
            fo_mlf.write('\n'.join(labels) + '\n.\n')

#===============================================================================
def read_mlf(mlf_fn):
    labels_dic = {}
    with open(mlf_fn) as fo_mlf:
        all_lines = fo_mlf.readlines()
    for line in all_lines:
        line = line.strip()
        if line == '#!MLF!#':
            last_line = '#!MLF!#'
            continue
        if line == '.':
            last_line = '.'
            continue
        if last_line == '.' or last_line == '#!MLF!#':
            feat_fn = line.strip('"')
        else:
            if feat_fn in labels_dic:
                labels_dic[feat_fn].append(line)
            else:
                labels_dic[feat_fn] = [line,]
        last_line = line
    return labels_dic

        
        
