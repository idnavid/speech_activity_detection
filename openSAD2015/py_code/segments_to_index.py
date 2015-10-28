#! /usr/bin/python 

import sys
# script to convert segment to frame index. 

def seg2idx(fn,ofn):
    TARGETRATE = 0.010
    WINDOWSIZE = 0.025
    
    fid = open(fn)
    fout = open(ofn,'w')
    for i in fid:
        line = i.strip()
        if ('\tNS\t' in line):
            line_list = line.split('\t')
            start_seg = float(line_list[2])
            end_seg = float(line_list[3])
            start_idx = int(start_seg/TARGETRATE)
            end_idx   = int(end_seg/TARGETRATE)+1
            for k in range(start_idx,end_idx+1):
                fout.write(str(k)+'\n')
    fout.close()
            


if __name__=='__main__':
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    seg2idx(input_file, output_file)



