#! /usr/bin/python 

import sys
from collections import Counter

def decide(label_list):
    if 'S' in label_list:
        return 'S'
    else:
        labels = Counter(label_list).keys()
        num_labels = Counter(label_list).values()
        max_idx = num_labels.index(max(num_labels))
        return labels[max_idx]

def utt_to_label(fin):
    utt2label_dict = {}
    for i in fin:
        line_list = i.strip().split(' ')
        uttid = line_list[0]
        labels_list = line_list[1:]
        if (len(labels_list)==1):
            utt2label_dict[uttid] = labels_list[0]
        elif (len(labels_list)>1):
            utt2label_dict[uttid] = decide(labels_list)
    return utt2label_dict


if __name__=='__main__':
    score_output = sys.argv[1]
    ground_truth = sys.argv[2]
    fin = open(score_output)
    hypo_dict = utt_to_label(fin)
    fin.close()
    fin = open(ground_truth)
    true_dict = utt_to_label(fin)
    fin.close()
    fp = 0
    fn = 0
    total = 0
    for i in true_dict.keys():
        if i in hypo_dict:
            total+=1
            if (true_dict[i]=='S' and hypo_dict[i]!='S'):
                fn+=1
            elif (true_dict[i]!='S' and hypo_dict[i]=='S'):
                fp+=1
    print "false positive:", float(fp)/total
    print "false negative:", float(fn)/total
            
