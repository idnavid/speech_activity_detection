#! /usr/bin/python 

import sys

def parse_transcripts(infile,fout):
    command_line = """ | cut -d '/' -f 6 | perl -ne 'if(m/(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(.*)/){$startime=sprintf("%09d",$3*1000);$endtime=sprintf("%09d",$4*1000);print "$2_${startime}_${endtime} $2 $3 $4 \@$5\\n"}' >> segments"""
    fout.write("cat "+infile+command_line+'\n')

def wav_to_tab(fullpath):
    str1 = fullpath.replace('nxs113020','lxk121630')
    str2 = str1.replace('/wav/','/sad/')
    str3 = str2.replace('.wav','.tab')
    return str3

if __name__ == '__main__':
    channel = sys.argv[1]
    fin = open('data/train_%s/wav.scp'%(channel))
    fout = open('summarize_transcripts','w')
    for i in fin: 
        line = i.strip().split(' ')[-1]
        parse_transcripts(wav_to_tab(line),fout)
    fout.close()
    fin.close()

