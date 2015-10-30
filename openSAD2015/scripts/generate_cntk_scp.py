#!/usr/bin/env python
import os
import re
import sys
import struct

def generate_cntk_scp(inDir, scp_fn):

    if os.path.exists(scp_fn):
        os.remove(scp_fn)    
    with open(scp_fn, 'w') as fo_scp:
        for root, dirs, files in os.walk(inDir):
            for f in files:
                if f.endswith('.mfc') or f.endswith('.fbk'):
                    feat_fn = os.path.join(root, f)
                    uttid = os.path.splitext(os.path.basename(feat_fn))[0] 
                    with open(feat_fn, 'rb') as fo_feat:
                        bytes = fo_feat.read(4)
                    Nframes, = struct.unpack('>i', bytes)
                    line = '%s=%s[0,%d]\n' % (uttid, feat_fn, Nframes-1)
                    fo_scp.write(line)
          
if __name__=='__main__':
    generate_cntk_scp(*sys.argv[1:])
