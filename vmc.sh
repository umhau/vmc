#!/bin/bash
# 
# DESCRIPTION
# 
#       Given a sentence file and (optionally) prerecorded audio files, produce a voice model in 
#       a specified location.  Indicate whether to record (-record) or import (-import) the 
#       audio files.
# 
# USAGE
# 
#       vmc.sh model-name [ -record OR -import audio/file/directory ] sentence-file output-folder [reps]
#
# DEPENDENCIES
# 
#       CMU Sphinx, Python 3 (& 2.7), Perl, and other misc. packages.
# 
# NOTES
# 
#       The output folder is intended to be the location of the voice model, once completed.
# 
#       The [reps] variable at the end specifies how many times to request a recording of each 
#       entry in the sentence file.  It is optional, as it is placed at the end of the list of 
#       parameters and the script will not fail if it is not specified.
# 
#       Having been installed to /usr/local/bin, this command can be called from anywhere.
# 

# VARIABLES =======================================================================================

export LD_LIBRARY_PATH=/usr/local/lib
        # set path to include sphinx library location 
        # https://jrmeyer.github.io/installation/2016/01/09/Installing-CMU-Sphinx-on-Ubuntu.html

if [ $2 = '-record' ]; then 

    sentence_file=$3
    output_folder=$4

    if [[ -z $5 ]]; then
        iterations=$5
    else
        iterations=1
    fi

elif [ $2 = '-import' ]; then

    audio_file_directory=$3
    sentence_file=$4
    output_folder=$5

else

    echo "USAGE: bash vmc.sh model-name [ -record OR -import audio/file/dir ] sentence-file output-folder [reps]"
    exit 1

fi

model_name=$1

audio_folder=$output_folder/audio

tdir=/opt/vmc/tools 

fdir=/opt/vmc/functions


# COMMANDS ========================================================================================

# OBTAIN REQUISITE FILES --------------------------------------------------------------------------

# get audio files
if [ $1 = '-record' ]; then 

    mkdir -p $audio_folder

    python3 $fdir/getaudio.py $sentence_file $audio_folder $iterations $model_name

elif [ $1 = '-import' ]; then

    mkdir -p $audio_folder

    cp -r $audio_file_directory $audio_folder

fi

# copy default acoustic model
cp -r $tdir/en-us $output_folder

# PRODUCE DERIVATIVE FILES ------------------------------------------------------------------------

# get derivatives of sentence file
python3 $fdir/format_text.py $sentence_file $model_name $output_folder

# get derivatives of audio files
bash $fdir/acousticfiles.sh $audio_folder $output_folder/$model_name.fileids

# CREATE MODELS -----------------------------------------------------------------------------------

# build language model
bash $fdir/buildLM.sh $sentence_file $model_name $output_folder

# build voice model
bash $fdir/voicemodel.sh $model_name $output_folder $audio_folder $output_folder


