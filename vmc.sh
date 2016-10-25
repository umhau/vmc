#!/bin/bash
# USAGE: sudo bash vmc.sh voice-model sentence-list.txt 2
#
# source: https://nixingaround.blogspot.com/2016/08/improving-accuracy-of-cmu-sphinx-for_3.html

# variables
model_name=$1
sentence_list_filename=$2
voice_training_iterations=$3

# set path to include sphinx library location 
# source: https://jrmeyer.github.io/installation/2016/01/09/Installing-CMU-Sphinx-on-Ubuntu.html
export LD_LIBRARY_PATH=/usr/local/lib

# check that variables have been specified
if [ ! -n $voice_training_iterations ]; then
    echo
    echo "**Error**: you must specify three input variables."
    echo "Please see README for usage instructions."
    exit 64
fi

# check for model folder
echo
echo -n "Checking for $model_name..."
if [ ! -d ./$model_name/audio ]; then
    echo
    echo -n "creating new folder..."
    mkdir -p "$(pwd)/$model_name/audio/"
    echo "done."
else
  echo "WARNING: already exists, will be OVERWRITTEN."
  echo
fi

# run python script: produces dictionary, LM & voice samples
python3 vmc.py "$model_name" "$sentence_list_filename" "$voice_training_iterations"

# get full-size acoustic model
echo "Extracting acoustic model..."
tar -xvzf ./cmusphinx-en-us-ptm-5.2.tar.gz -C ./$model_name
mv ./$model_name/cmusphinx-en-us-ptm-5.2 ./$model_name/en-us

# convert lm to binary (bin) format (command was too complex for python to handle)
echo "Converting lm from text to binary..."
echo
dst=$model_name/$model_name.lm
echo $dst
sphinx_lm_convert -i $dst -o $dst.bin

# generate some acoustic feature files
echo
echo "Generating acoustic feature files..."
echo
cd ./$model_name/audio
sphinx_fe -argfile ../en-us/feat.params -samprate 16000 -c ../$model_name.fileids -di . -do . -ei wav -eo mfc -mswav yes
cd ../..

# convert binary mdef file to .txt
echo
echo "Converting mdef file from binary to text..."
echo
cd ./$model_name/
pocketsphinx_mdef_convert -text ./en-us/mdef ./en-us/mdef.txt
cd ..

# get binary tools from sphinx installations
echo
echo -n "Copying tools from sphinxtrain installation..."
cd ./$model_name/
cp /usr/local/libexec/sphinxtrain/bw .
cp /usr/local/libexec/sphinxtrain/map_adapt .
cp /usr/local/libexec/sphinxtrain/mk_s2sendump .
cp /usr/local/libexec/sphinxtrain/mllr_solve .
cd ..
echo "done."

# run tools to create voice model
cd ./$model_name/audio

# sphinx_fe
echo "Executing sphinx_fe..."
sphinx_fe \
 -argfile ../en-us/feat.params \
 -samprate 16000 \
 -c ../$model_name.fileids \
 -di . \
 -do . \
 -ei wav \
 -eo mfc \
 -mswav yes

echo "Executing bw..."
../bw \
 -hmmdir ../en-us \
 -moddeffn ../en-us/mdef.txt  \
 -ts2cbfn .ptm. \
 -feat 1s_c_d_dd \
 -svspec 0-12/13-25/26-38 \
 -cmn current \
 -agc none \
 -dictfn ../4865.dic  \
 -ctlfn ../$model_name.fileids \
 -lsnfn ../$model_name.transcription \
 -accumdir .

# echo "Executing mllr_solve..."
# ../mllr_solve \
#  -meanfn ../en-us/means  \
#  -varfn ../en-us/variances \
#  -outmllrfn mllr_matrix \
#  -accumdir .

# echo "Executing map_adapt..."
# ../map_adapt \
#  -moddeffn ../en-us/mdef.txt \
#  -ts2cbfn .ptm. \
#  -meanfn ../en-us/means \
#  -varfn ../en-us/variances \
#  -mixwfn ../en-us/mixture_weights \
#  -tmatfn ../en-us/transition_matrices \
#  -accumdir . \
#  -mapmeanfn ../en-us-adapt/means \
#  -mapvarfn ../en-us-adapt/variances \
#  -mapmixwfn ../en-us-adapt/mixture_weights \
#  -maptmatfn ../en-us-adapt/transition_matrices

# echo "Executing mk_s2sendump..."
# ../mk_s2sendump \
#  -pocketsphinx yes \
#  -moddeffn ../en-us-adapt/mdef.txt \
#  -mixwfn ../en-us-adapt/mixture_weights \
#  -sendumpfn ../en-us-adapt/sendump

      




