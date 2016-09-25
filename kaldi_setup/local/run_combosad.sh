. ~/.bashrc
sad_dir=/scratch/nxs113020/speech_activity_detection/kaldi_setup/
unsupervised_sad_dir=/scratch/nxs113020/speech_activity_detection/unsupervised_sad/
sph2pipe_dir=/scratch2/share/nxs113020/kaldi-trunk/tools/sph2pipe_v2.5/
python $sad_dir/local/run_combosad.py $1 $2 $unsupervised_sad_dir $sph2pipe_dir 
