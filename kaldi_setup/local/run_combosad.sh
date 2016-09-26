. ~/.bashrc
## For cluster:
#sad_dir=/scratch/nxs113020/speech_activity_detection/kaldi_setup/
#sph2pipe_dir=/scratch2/share/nxs113020/kaldi-trunk/tools/sph2pipe_v2.5/

## For local machine(s)
sad_dir=/home/nxs113020/speech_activity_detection/kaldi_setup/
sph2pipe_dir=/home/nxs113020/kaldi-trunk/tools/sph2pipe_v2.5/

## For both cluster and local machine(s)
unsupervised_sad_dir=$sad_dir/../unsupervised_sad/

python $sad_dir/local/run_combosad.py $1 $2 $unsupervised_sad_dir $sph2pipe_dir 
