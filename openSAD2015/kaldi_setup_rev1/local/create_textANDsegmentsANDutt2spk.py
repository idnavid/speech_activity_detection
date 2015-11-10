#! /usr/bin/python 

import sys

def frame_labels(inline,start_time,end_time,label):
    TARGETRATE = .025
    FRAMERATE = .010
    interval_length = end_time - start_time
    n_frames = int((interval_length-TARGETRATE)/FRAMERATE)
    if (n_frames>9):
        return label
    return False

def line_to_text(inline,fout,fseg,futt2spk):
    line_list = inline.split(' ')
    segid = line_list[0]
    start_time = float(line_list[2])
    end_time = float(line_list[3])
    label = line_list[-1].split('@')[-1].strip()
    segtext = frame_labels(inline,start_time,end_time,label)
    if segtext:
        fout.write(segid+' '+segtext+'\n')
        fseg.write(inline.split('@')[0].strip()+'\n')
        futt2spk.write(line_list[0]+' '+line_list[1]+'\n')

if __name__=='__main__':
    channel = sys.argv[1]
    mode = sys.argv[2].split('_')[1]
    fin = open('data/%s_%s/segment_summary'%(mode,channel))
    fout = open('data/%s_%s/text'%(mode,channel),'w')
    fseg = open('data/%s_%s/segments'%(mode,channel),'w')
    futt2spk = open('data/%s_%s/utt2spk'%(mode,channel),'w')
    for i in fin:
        line_to_text(i.strip(),fout,fseg,futt2spk)
    fout.close()
    fin.close()
    fseg.close()

