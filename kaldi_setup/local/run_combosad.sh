. ~/.bashrc
sad_dir=$3
unsupervised_sad_dir=$sad_dir/../unsupervised_sad/
sph2pipe_dir=~/kaldi-trunk/tools/sph2pipe_v2.5/
python $sad_dir/local/run_combosad.py $1 $2 $unsupervised_sad_dir $sph2pipe_dir 
