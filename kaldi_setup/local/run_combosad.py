
import sys
import os
wav_scp = sys.argv[1]
out = sys.argv[2]
module_path = sys.argv[3]
sph2pipe_dir = sys.argv[4]

sys.path.append(module_path)
import sad as combo_sad


def remove_special_chars(in_string):
    out_string = ''
    for i in in_string:
        if i==':':
            i = '_'
        if i=='.':
            i = '_'
        out_string+=i
    return out_string

def sum_strings(list_of_strings):
    s = 0
    print list_of_strings
    for i in list_of_strings:
        s += int(i)
    print s
    return s
 
def revert_labels(in_ark, out_ark, mode):
    """ Takes vad labels of 1s and 0s and turns it to label of 0s and 1s.
        (speech labels to non-speech labels).
        We can't simply replace 1s with 0s and vice-versa. This function
        makes sure both labels maintain high false alarms (assuming the input)
        has high false alarm. 
    """
    if (mode == 's2n'):
        # converting speech to non-speech labels.
        orig = 1
        target = 0
    elif (mode == 'n2s'):
        orig = 0
        target = 1
    N = 10 # window size
    fin = open(in_ark)
    fout = open(out_ark,'w')
    for i in fin:
        uttid = i.split(' ')[0].strip()
        fout.write(uttid+' [ ')
        labels = i.split('[')[-1].split(']')[0].strip().split(' ')
        n = 0
        for j in labels:
            if (n <= N and n > (len(labels) - N)) :
                k = False
            else:
                if (sum_strings(labels[n-N:n+N])==2*N*orig): # all samples must be identical
                    k = True
                else:
                    k = False
            if k:
                fout.write(str(target)+' ')
            elif not(k):
                fout.write(str(orig)+' ')
            n+=1        
        fout.write(' ]\n')
    fin.close()
    fout.close()


out_list = out.split(':')
out_type1 = out_list[0].split(',')[0]
out_type2 = out_list[0].split(',')[1]
out_file1 = out_list[1].split(',')[0]
out_file2 = out_list[1].split(',')[1]

if (out_type1 == 'ark'):
    ark_file = out_file1
    scp_file = out_file2
elif (out_type2 == 'ark'):
    ark_file = out_file2
    scp_file = out_file1
else:
    raise 'Wrong input format!'
    exit()

os.system('rm '+ark_file+' '+scp_file)
f_in = open(wav_scp)
wav_dump = 'wav_dump/'
if not(os.path.isdir(wav_dump)):
    os.system('mkdir '+wav_dump)

for i in f_in:
    line_list = i.strip().split(' ')
    utt_id = line_list[0]
    print line_list
    file_path = line_list[1]
    if 'sph2pipe' in file_path:
        sph_converter = ''
        for j in line_list[1:]:
            if j.strip()=='|':
                j = '> '
            if j.strip()=='sph2pipe':
                sph_converter = sph2pipe_dir.strip()+'/sph2pipe'
            else:
                sph_converter += ' '+j.strip()
        file_path = wav_dump+remove_special_chars(utt_id)
        print sph_converter+file_path+'.wav'
        os.system(sph_converter+file_path+'.wav')
    if 'sox' in line_list:
        wav_converter = ''
        for j in line_list[1:]:
            if j.strip()=='|':
                j = '> '
            wav_converter += ' '+j.strip()
        file_path = wav_dump+remove_special_chars(utt_id)
        print wav_converter+file_path+'.wav'
        os.system(wav_converter+file_path+'.wav')
    f_out = open(ark_file,'a')
    f_out.write(utt_id+' ')
    f_out.close()
    combo_sad.sad(file_path+'.wav', module_path+'config_sad', ark_file, 'ark')
    os.system('rm '+file_path+'.wav')
f_in.close()

os.system('. path.sh')
os.system('cp '+ark_file+' '+ark_file+'.txt')
# create nonspeech labels
#os.system('cat '+ark_file+'.txt | sed \'s/\ 1/\ 2/g\' | sed \'s/\ 0/\ 1/g\' | sed \'s/\ 2/\ 0/g\' > '+ark_file+'.n.txt')
revert_labels(ark_file+'.txt', ark_file+'.n.txt',  's2n')
os.system('copy-vector ark:'+ark_file+'.txt'+' ark,scp:'+ark_file+','+scp_file)
os.system('copy-vector ark:'+ark_file+'.n.txt'+' ark,scp:'+ark_file+'.n,'+scp_file+'.n')
#os.system('rm '+ark_file+'.txt')
#os.system('rm '+ark_file+'.n.txt')

