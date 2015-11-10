#! /usr/bin/python 

import sys
import os

def parse_transcripts(infile,fout,channel):
    command_line = """ | cut -d '/' -f 6 | perl -ne 'if(m/(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(\S+)\\t(.*)/){$startime=sprintf("%09d",$3*1000);$endtime=sprintf("%09d",$4*1000);print "$2_${startime}_${endtime} $2 $3 $4 \@$5\\n"}' >> """
    fout.write("cat "+infile+command_line+"data/%s_%s/segment_summary"%(mode,channel)+'\n')

def wav_to_tab(fullpath):
    str1 = fullpath.replace('nxs113020','lxk121630')
    str2 = str1.replace('/wav/','/sad/')
    str3 = str2.replace('.wav','.tab')
    return str3

if __name__ == '__main__':
    channel = sys.argv[1]
    mode = sys.argv[2].split('_')[1]
    fin = open('data/%s_%s/wav.scp'%(mode,channel))
    fout = open('data/%s_%s/summarize_transcripts.sh'%(mode,channel),'w')
    for i in fin: 
        line = i.strip().split(' ')[-1]
        parse_transcripts(wav_to_tab(line),fout,channel)
    fout.close()
    fin.close()
    os.system('rm data/%s_%s/segment_summary'%(mode,channel))
    os.system('bash data/%s_%s/summarize_transcripts.sh'%(mode,channel))

