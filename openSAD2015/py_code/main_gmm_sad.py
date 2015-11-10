#! /usr/bin/python 

import os

"""
annotation_list = '../lists/all_sad_decoded.txt'

fin = open(annotation_list)
segments = ""cat %s | cut -d '/' -f 6 | perl -ne 'if(m/(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(NS)\\t(.*)/){print "$2_$3_$4_NS $2 $3 $4\\n"}' >> %s""

fsegment = open('segments_command','w')
for i in fin:
    line = i.strip()
    line_list = line.split('/')
    file_name = line_list[-1]
    base_name = file_name.split('.')[0]
    
    segment_command = segments%(line,'data/train/segments')
    fsegment.write(segment_command+'\n')
 
fsegment.close()

"""


ftrain = open('../lists/train_src_ids.txt')
train_ids = []
for i in ftrain:
    src_id = int(i.strip())
    train_ids.append(src_id)
ftrain.close()

fdev = open('../lists/dev_src_ids.txt')
dev_ids = []
for i in fdev:
    src_id = int(i.strip())
    dev_ids.append(src_id)
fdev.close()


ffeat  = open('../lists/all_features_NS.txt')
ftrain_feat = open('../lists/train_feature_list_NS.txt','w')
fdev_feat = open('../lists/dev_feature_list_NS.txt','w')
for i in ffeat:
    line = i.strip()
    src_id = int(line.split('/')[-1].split('_')[0])
    if src_id in train_ids:
        ftrain_feat.write(line+'\n')
    else:
        fdev_feat.write(line+'\n')

ftrain_feat.close()
fdev_feat.close()
ffeat.close()
