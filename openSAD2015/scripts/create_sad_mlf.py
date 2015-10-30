#!/usr/bin/env python

import os
import sys
import pdb
import struct
import commands
import numpy as np

def create_sad_mlf(tabList, mlf):
    with open(tabList) as fo_tabList:
        all_tab_fns = fo_tabList.read().splitlines()
    with open(mlf, 'w') as fo_mlf:
        fo_mlf.write('#!MLF!#\n')
        counter = 1      
        for tab_fn in all_tab_fns:
            print counter
            counter += 1
            wavid = os.path.splitext(os.path.basename(tab_fn))[0]
            fo_mlf.write('"%s"\n' % wavid)
            lab_sequence = extract_lab_sequence(tab_fn)
            fo_mlf.write('\n'.join(lab_sequence) + '\n')
            fo_mlf.write('.\n')
        


def extract_lab_sequence(tab_fn):

    fs = 16000
    frame_dur = int(0.025 * fs)
    frame_hop = int(0.010 * fs)

    # read the size of the corresponding feature file
    featdir = '/scratch2/share/mxm121931/openSAD_feats/train'
    feat_fn = os.path.join(featdir, os.path.splitext(os.path.basename(tab_fn))[0]+'.mfc')
    with open(feat_fn) as fo_feat:
        header = fo_feat.read(12)
        n_frames, frame_period_100ns, bytesize, parmkind = struct.unpack('>iihh', header)

    # read the corresponding flac file length
    flac_fn = tab_fn.replace('sad', 'audio').replace('.tab', '.flac')
    temp = commands.getoutput('soxi %s | egrep -o "[0-9]+\s+samples"' % flac_fn)
    n_samples = int(temp.replace('samples', ''))

    lab2row = {'S':0, 'NS':1, 'NT':2, 'RX': 3}
    row2lab = dict((y,x) for x,y in lab2row.iteritems())
    sad_idx_matrix = np.zeros((len(lab2row), n_samples))

    # read annotations
    with open(tab_fn) as fo_tab:
         all_tab_lines = fo_tab.read().splitlines()
    
    # create sad index matrix
    all_rows = []
    for line in all_tab_lines:
        _, wavid, t1, t2, lab, _, _, _ = line.split()
        n1 = int(float(t1) * fs)
        n2 = int(float(t2) * fs)
        row = lab2row[lab]
        all_rows.append(row)
        sad_idx_matrix[row, n1:n2] = 1


    all_labs = []
    n1 = 0
    
    while (n1 + frame_dur <= n_samples):
        temp = sad_idx_matrix[:, n1 : n1 + frame_dur]
        all_labs.append(row2lab[np.argmax(np.sum(temp, axis = -1))])
        n1 += frame_hop
    if len(all_labs) < n_frames:
        all_labs += [all_labs[-1],] * (n_frames - all_labs) #extend
    elif len(all_labs) > n_frames:
        all_labs = all_labs[:n_frames] #cut
    assert len(all_labs) == n_frames

    return all_labs


        

if __name__ == '__main__':
    create_sad_mlf(*sys.argv[1:])
