#! /usr/bin/python

import sys
def pretty_float(num):
   return str("%0.3f"%(num))

def out_format(utt_id,start_time,end_time,seg_type):
    return 'tst.xml'+'\t'+'tstDev'+'\t'+'tstData'+'\t'+'SAD'+'\t'+utt_id+'\t'+pretty_float(start_time)+'\t'+pretty_float(end_time)+'\t'+seg_type+'\t'+'0.5\n'

def frame_to_segs(frame_labels,phone_to_word_dict,utt_id,fout):
    TARGETRATE = 0.025
    FRAMERATE  = 0.010
    start_time = 0.
    end_time = TARGETRATE
    for j in range(len(frame_labels)-1):
        if (phone_to_word_dict[frame_labels[j]] == phone_to_word_dict[frame_labels[j+1]]):
            end_time += FRAMERATE
        else:
            end_time += FRAMERATE
            fout.write(out_format(utt_id,start_time,end_time,phone_to_word_dict[frame_labels[j]]))
            start_time = end_time
            end_time = end_time+TARGETRATE
    


if __name__=='__main__':
    input_file = sys.argv[1]
    # Change next line based on your system. 
    phone_to_word_dict={'NS_S':'non-speech','NT_S':'non-speech','RX_S':'non-speech','S_S':'speech'}
    for i in open(input_file):
        line = i.strip()
        line_list = line.split(' ')
        utt_id = line_list[0]
        frame_labels = line_list[1:]
        futt = open('exp/hypotheses/'+utt_id+'.txt','w')
        frame_to_segs(frame_labels,phone_to_word_dict,utt_id,futt)
        futt.close()
        
