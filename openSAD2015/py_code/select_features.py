#! /usr/bin/python 


def selectFeatures(index_list):
    """Creates a paralelized bash command list to run using SGE.
       The commands take .htk files and a list of frames as input and 
       return a new .htk file that only contains those frames."""

    fin = open(index_list)
    fout = open("../lists/featureselection_script.txt",'w')
    selection_command = '/export/bin/FeatureSelect -m SFS -i %s -o %s -x %s'
    for i in fin:
        line = i.strip()
        base_name = line.split('/')[-1].split('.')[0]
        
        feature_file = '/erasable/nxs113020/mfcc_opensad/'+base_name+'.htk'
        out_feature_file = '/erasable/nxs113020/mfcc_opensad/'+base_name+'_S.htk' # for speech
        
        bash_command = selection_command%(feature_file,out_feature_file,line)
        fout.write(bash_command+'\n')
    fin.close()
    fout.close()


if __name__=='__main__':
    selectFeatures("/scratch/nxs113020/speech_activity_detection/openSAD2015/lists/all_idx_decoded.txt")
     
        
        
