#!/bin/bash
# 
# DESCRIPTION
# 
#       Given a sentence file and (optionally) prerecorded audio files, produce
#       a voice model in a specified location.  Indicate whether to record 
#       (-record) or import (-import) the audio files.
# 
#       The statistical language model is now produced separately, run 
#           
#           $ lmt.sh
#
#       to see what the parameters are.
#
# USAGE
# 
#       vmc.sh 
#           model-name                  used to name most of the internal files
#           [ -record OR -import audio/file/directory ]
#           vm-training-file            sentences the user should record for 
#                                       training purposes
#           output-folder               this is a complete file path
#           [reps]                      how many times to get a recording of 
#                                       each sentence
#           acoustic-model              Location of acoustic model to start 
#                                       with. (this is a complete file path, 
#                                       not including 'en-us'.) Optional.
# 
# DEPENDENCIES
# 
#       CMU Sphinx, Python 3 (& 2.7), Perl, and other misc. packages.
# 
# NOTES
# 
#       The output folder is intended to be the location of the voice model, 
#       once completed.
# 
#       The [reps] variable at the end specifies how many times to request a 
#       recording of each entry in the sentence file.  It is optional, as it is
#       placed at the end of the list of parameters and the script will not 
#       fail if it is not specified.
# 
#       Having been installed to /usr/local/bin, this command can be called 
#       from anywhere.
#
#       After installation, a keyphrase list should be added in order to use 
#       the voice model for keyword spotting.
# 

# VARIABLES ===================================================================

export LD_LIBRARY_PATH=/usr/local/lib
# set path to include sphinx library location 
# jrmeyer.github.io/installation/2016/01/09/Installing-CMU-Sphinx-on-Ubuntu.html

if [[ $2 = '-record' ]]; then 

    vm_training_file=$3; output_folder=$4

    if [[ -n $5 ]]; then iterations=$5; else iterations=1; fi

elif [[ $2 = '-import' ]]; then

    audio_file_directory=$3; sentence_file=$4; output_folder=$5; iterations=1

else
    
    echo
    echo -e "USAGE: \tvmc.sh "
    echo 
    echo -e "\tmodel-name\t\t(used to name most of the internal files)"
    echo -e "\t[ -record OR -import audio/file/directory ]"
    echo -e "\tvm-training-file\t(sentences for the user to record)"
    echo -e "\toutput-folder\t\t(this is a complete file path)"
    echo -e "\t[reps]\t\t\t(number of voice recordings per sentence)"
    echo

    exit 1

fi

model_name=$1

audio_folder=$output_folder/audio

tdir=/opt/vmc/tools; fdir=/opt/vmc/functions


# COMMANDS ====================================================================

# OBTAIN REQUISITE FILES ------------------------------------------------------

echo
echo "Collecting required files..."

# get audio files and put them where they go
if [[ $2 = '-record' ]]; then 

    mkdir -p $audio_folder

    python3 $fdir/getaudio.py $vm_training_file $audio_folder $iterations $model_name

    echo "Recorded audio files saved into $audio_folder. They can be reused."

elif [[ $2 = '-import' ]]; then

    mkdir -p $audio_folder

    cp -a $audio_file_directory/*.wav $audio_folder/

fi

# copy default acoustic model
if [ -n "$6" ]; then
    echo "Pulling base acoustic model from $6"
    read -p "Press enter to continue, or CTRL-C to exit"
    cp -r $installation_directory/en-us $output_folder
else
    echo "Using default base acoustic model."
    cp -r $tdir/en-us $output_folder
fi

# PRODUCE DERIVATIVE FILES ----------------------------------------------------

echo
echo "Producing sentence file derivatives..."

# get derivatives of sentence file
python3 $fdir/format_text.py $vm_training_file $model_name $output_folder $iterations

echo 
echo "Producing audio file derivatives..."

# get derivatives of audio files
bash $fdir/acousticfiles.sh $audio_folder $output_folder/$model_name.fileids

# CREATE MODELS ---------------------------------------------------------------

echo
echo "Creating voice model..."

# build voice model
bash $fdir/voicemodel.sh $model_name $output_folder $audio_folder $output_folder

echo 
echo "Process complete.  New acoustic voice model saved into $output_folder"
