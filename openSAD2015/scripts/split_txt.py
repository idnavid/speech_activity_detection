#!/usr/bin/env python
import sys
import os
import shutil

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


def split_txt(txt_in_fn, nj, outDir):
    '''
    splits a text file into nj equal parts.
    '''
    nj = int(nj)
    fn_base, fn_ext = os.path.splitext(txt_in_fn)
    # create output directory
    if os.path.isdir(outDir):
        shutil.rmtree(outDir)
    os.mkdir(outDir)
    # read all lines into a list and split the list
    with open(txt_in_fn) as fo_txt:
        all_lines=fo_txt.readlines()
    split_lines = split_list(all_lines, nj)
    # write each sublist to a separate text file
    for ii in xrange(nj):
        txt_part_fn = os.path.basename(fn_base) + '.' + str(ii+1) + fn_ext
        if txt_part_fn[-1] == '.': txt_part_fn = txt_part_fn[:-1]        
        txt_part_fn = os.path.join(outDir, txt_part_fn)  
        with open(txt_part_fn, 'w') as fo_txt_part:
            fo_txt_part.write(''.join(split_lines[ii]))
                

if __name__ == '__main__':
    split_txt(*sys.argv[1:])
