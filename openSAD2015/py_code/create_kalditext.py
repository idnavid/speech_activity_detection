#! /usr/bin/python 


def frame_labels(inline,start_time,end_time,label):
    TARGETRATE = .025
    FRAMERATE = .010
    interval_length = end_time - start_time
    n_frames = int((interval_length-TARGETRATE)/FRAMERATE)
    if (n_frames>9):
        return (label+' ')*n_frames
    return False

def line_to_text(inline,fout):
    line_list = inline.split(' ')
    segid = line_list[0]
    start_time = float(line_list[2])
    end_time = float(line_list[3])
    label = line_list[-1].split('@')[-1].strip()
    segtext = frame_labels(inline,start_time,end_time,label)
    if segtext:
        fout.write(segid+' '+segtext+'\n')
        fseg.write(inline+'\n')

if __name__=='__main__':
    fin = open('segments')
    fout = open('text','w')
    fseg = open('new_segments','w')
    for i in fin:
        line_to_text(i.strip(),fout)
    fout.close()
    fin.close()
    fseg.close()

