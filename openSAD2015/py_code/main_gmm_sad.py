#! /usr/bin/python 

import os


annotation_list = '../lists/all_sad_decoded.txt'

fin = open(annotation_list)
segments = """cat %s | cut -d '/' -f 6 | perl -ne 'if(m/(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(S)\\t(.*)/){print "$2_$3_$4 $2 $3 $4\\n"}' >> %s"""

fsegment = open('segments_command','w')
for i in fin:
    line = i.strip()
    line_list = line.split('/')
    file_name = line_list[-1]
    base_name = file_name.split('.')[0]
    
    segment_command = segments%(line,'data/train/segments')
    fsegment.write(segment_command+'\n')
 
fsegment.close()

