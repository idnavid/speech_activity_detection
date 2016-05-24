
import sys
import os
module_path = '/scratch/nxs113020/speech_activity_detection/unsupervised_sad/'
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

wav_scp = sys.argv[1]
out = sys.argv[2]

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
wav_dump = '/erasable/nxs113020/wav_dump/'
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
                sph_converter = '/export/bin/sph2pipe'
            else:
                sph_converter += ' '+j.strip()
        file_path = wav_dump+remove_special_chars(utt_id)
        print sph_converter+file_path+'.wav'
        os.system(sph_converter+file_path+'.wav')
    f_out = open(ark_file,'a')
    f_out.write(utt_id+' ')
    f_out.close()
    combo_sad.sad(file_path+'.wav', module_path+'config_sad', ark_file, 'ark')
    os.system('rm '+file_path+'.wav')
f_in.close()

os.system('. path.sh')
os.system('cp '+ark_file+' '+ark_file+'.txt')
# create nonspeech labels
os.system('cat '+ark_file+'.txt | sed \'s/\ 1/\ 2/g\' | sed \'s/\ 0/\ 1/g\' | sed \'s/\ 2/\ 0/g\' > '+ark_file+'.n.txt')
os.system('copy-vector ark:'+ark_file+'.txt'+' ark,scp:'+ark_file+','+scp_file)
os.system('copy-vector ark:'+ark_file+'.n.txt'+' ark,scp:'+ark_file+'.n,'+scp_file+'.n')
os.system('rm '+ark_file+'.txt')
os.system('rm '+ark_file+'.n.txt')

