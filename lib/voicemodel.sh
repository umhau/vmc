#!/bin/bash
# 
# DESCRIPTION =================================================================
# 
#       Given acoustic feature files and sentence file derivatives, produce 
#       voice model. 
#
#       This script is primarily using a copy of en-us that is being actively 
#       edited as it is adapted to become a custom voice model.  
# 
#       Binaries are located in /opt/vmc/lib.
# 
# USAGE EXAMPLE ===============================================================
# 
#       bash voicemodel.sh \
#            'en-us' \
#            /usr/local/lib/python2.7/dist-packages/pocketsphinx/model/en-us \
#            ~/.psyche/audio 
# 
# VARIABLES ===================================================================

model_name=$1          # If performing adaptation, this must match prior names.
acoustic_model_dir=$2  # acoustic model folder, often the default 'en-us'
audio_file_dir=$3      # contains audio file and sentence file derivatives

libdir=/opt/vmc/lib

# also located at /opt/vmc/lib/cmudict-en-us.dict
dict="/usr/local/lib/python2.7/dist-packages/pocketsphinx/model/cmudict-en-us.dict"

# COMMANDS ====================================================================

# convert binary mdef file to .txt --------------------------------------------
cd $acoustic_model_dir
sudo pocketsphinx_mdef_convert \
    -text $acoustic_model_dir/mdef $acoustic_model_dir/mdef.txt &> /dev/null

# run tools to create voice model ---------------------------------------------
cd $audio_file_dir

sudo sphinx_fe \
    -argfile $acoustic_model_dir/feat.params \
    -samprate 16000 \
    c $audio_file_dir/$model_name.fileids \
    -di . -do . -ei wav -eo mfc -mswav yes \
    &> /dev/null

sudo $libdir/bw \
    -hmmdir $acoustic_model_dir \
    -moddeffn $acoustic_model_dir/mdef.txt  \
    -ts2cbfn .ptm. -feat 1s_c_d_dd -svspec 0-12/13-25/26-38 \
    -cmn current -agc none -dictfn $dict  \
    -ctlfn $audio_file_dir/$model_name.fileids \
    -lsnfn $audio_file_dir/$model_name.transcription \
    -accumdir . \
    &> /dev/null

sudo $libdir/mllr_solve \
    -meanfn $acoustic_model_dir/means  \
    -varfn $acoustic_model_dir/variances \
    -outmllrfn mllr_matrix -accumdir . &> /dev/null

sudo $libdir/map_adapt \
    -moddeffn $acoustic_model_dir/mdef.txt \
    -ts2cbfn .ptm. \
    -meanfn $acoustic_model_dir/means \
    -varfn $acoustic_model_dir/variances \
    -mixwfn $acoustic_model_dir/mixture_weights \
    -tmatfn $acoustic_model_dir/transition_matrices \
    -accumdir . \
    -mapmeanfn $acoustic_model_dir/means \
    -mapvarfn $acoustic_model_dir/variances \
    -mapmixwfn $acoustic_model_dir/mixture_weights \
    -maptmatfn $acoustic_model_dir/transition_matrices\
    &> /dev/null

sudo $libdir/mk_s2sendump \
    -pocketsphinx yes \
    -moddeffn $acoustic_model_dir/mdef.txt \
    -mixwfn $acoustic_model_dir/mixture_weights \
    -sendumpfn $acoustic_model_dir/sendump \
    &> /dev/null
