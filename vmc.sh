#!/bin/bash
#
# USAGE: bash vmc.sh voice-model sentence-list.txt 2 [old-audio-folder old-sentence-list-file]
# 
# EXAMPLES: 
#   old audio:                      bash vmc.sh voice-model2 ex-corpus.txt -1 audio arctic_data.txt
#   ignore audio:                   bash vmc.sh voice-model2 ex-corpus.txt 0
#   record audio, one repetition:   bash vmc.sh voice-model2 ex-corpus.txt 1
#   record audio, two repetitions:  bash vmc.sh voice-model2 ex-corpus.txt 2
# 
#   NOTE: sentence-list.txt is only used in the case of recording new audio, but must be preserved
#         in the command string for coherence sake.  I know, it's hacky. I'm a noob and I'm not 
#         spending another 10 hours rebuilding the code into something nicer.  
#
#
# source: https://nixingaround.blogspot.com/2016/08/improving-accuracy-of-cmu-sphinx-for_3.html


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ [set & check variables] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# basic variables
model_name=$1
sentence_list_filename=$2
voice_training_iterations=$3


# make sure this variable is consistently used
pronunciation_dictionary="cmudict-en-us.dict"


# set path to include sphinx library location 
# https://jrmeyer.github.io/installation/2016/01/09/Installing-CMU-Sphinx-on-Ubuntu.html
export LD_LIBRARY_PATH=/usr/local/lib


# check that variables have been specified
if [ ! -n $voice_training_iterations ]; then
    echo
    echo "**Error**: input variables incorrect."
    echo "Please see README for usage instructions."
    exit 64
fi


# check for old audio-related perameters
# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash

# check if incorrectly specified
if ( ! [ -z ${4+x} ] && [ -z ${5+x} ] ) 
then
    echo "You must provide two perameters to reuse audio files."
    exit 64
fi
    

# rename perameter if both present
if [ $4 ]; 
then

    old_audio_folder=$4 # perameter should be the relative path to the audio folder

    old_sentence_list_file=$5

    sentence_list_filename=./$model_name/$5

    number_of_audio_files=$( ls $old_audio_folder/*.wav | wc -l )

fi


# check for new model folder
echo
echo -n "Checking for $model_name..."
if [ ! -d ./$model_name/audio ]; then
    echo -n "creating new folder..."
    mkdir -p "$(pwd)/$model_name/audio/"
    echo "done."
else
  echo "WARNING: model already exists."
  # exit 65
fi



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ [import old audio folder] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

if [ $4 ]; then

    echo 
    echo -n "Looking for audio folder..."
    
    # create two strings, space-delimited, in the formats:   
    for entry in "$old_audio_folder"/*.wav
    do

        # ./[old-audio-folder]/[old-model-name]_XXXX.wav
        olddirentry=$entry

        # _XXXX.wav -- see: http://tldp.org/LDP/abs/html/string-manipulation.html
        suffix=${entry: -9}

        # copy and rename files to audio directory
        cp -r $olddirentry ./$model_name/audio/$model_name$suffix
        
    done

    # copy plain sentence file
    cp $old_audio_folder/$old_sentence_list_file ./$model_name/$old_sentence_list_file

    echo "done."

fi


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ [create acoustic voice model] ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# run python script: produces dictionary, LM & voice samples - if adding preexisting audio, indicate.

    a=$model_name                       # defines file and folder names
    b=$sentence_list_filename           # points to the initial list of sentences
    c=$pronunciation_dictionary         # used for producing custom pronunciation dictionary
    d=$voice_training_iterations        # indicates action on voice data - record, import, nothing
    e=$old_audio_folder                 # if importing audio, gives its location
    f=$old_sentence_list_file           # if importing audio, points to sentence list
    g=$number_of_audio_files            # number of sentences to extract from list

python3 vmc.py $a $b $c $d $e $f $g


# run perl script to create language model, move into model folder
perl quick_lm.pl -s $sentence_list_filename
src=$sentence_list_filename.arpabo
dst=$model_name/$model_name.lm
mv $src $dst

# get full-size acoustic model
echo
echo -n "Extracting acoustic model..."
tar -xf ./cmusphinx-en-us-ptm-5.2.tar.gz -C ./$model_name
mv  ./$model_name/cmusphinx-en-us-ptm-5.2 ./$model_name/en-us
echo "done."

# convert lm to binary (bin) format (command was too complex for python to handle)
echo "Converting lm from text to binary..."
echo
dst=$model_name/$model_name.lm
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
echo
echo "Executing sphinx_fe..."
echo
sphinx_fe \
 -argfile ../en-us/feat.params \
 -samprate 16000 \
 -c ../$model_name.fileids \
 -di . \
 -do . \
 -ei wav \
 -eo mfc \
 -mswav yes

echo
echo "Executing bw..."
echo
../bw \
 -hmmdir ../en-us \
 -moddeffn ../en-us/mdef.txt  \
 -ts2cbfn .ptm. \
 -feat 1s_c_d_dd \
 -svspec 0-12/13-25/26-38 \
 -cmn current \
 -agc none \
 -dictfn ../../$pronunciation_dictionary  \
 -ctlfn ../$model_name.fileids \
 -lsnfn ../$model_name.transcription \
 -accumdir .

echo 
echo "Executing mllr_solve..."
echo
../mllr_solve \
 -meanfn ../en-us/means  \
 -varfn ../en-us/variances \
 -outmllrfn mllr_matrix \
 -accumdir .

# move your files to a new directory (not sure if necessary?)
#cp -a ../en-us ../en-us-adapt

echo "Executing map_adapt..."
../map_adapt \
 -moddeffn ../en-us/mdef.txt \
 -ts2cbfn .ptm. \
 -meanfn ../en-us/means \
 -varfn ../en-us/variances \
 -mixwfn ../en-us/mixture_weights \
 -tmatfn ../en-us/transition_matrices \
 -accumdir . \
 -mapmeanfn ../en-us/means \
 -mapvarfn ../en-us/variances \
 -mapmixwfn ../en-us/mixture_weights \
 -maptmatfn ../en-us/transition_matrices

echo "Executing mk_s2sendump..."
../mk_s2sendump \
 -pocketsphinx yes \
 -moddeffn ../en-us/mdef.txt \
 -mixwfn ../en-us/mixture_weights \
 -sendumpfn ../en-us/sendump



