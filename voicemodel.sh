#!/bin/bash
# 
# DESCRIPTION
# 
#       Given acoustic feature files and sentence file derivatives, produce voice model. 
# 
# USAGE
# 
#       bash voicemodel.sh model-name model-dir acoustic-files-dir sentence-file-derivatives-dir
# 
# EXAMPLE
# 
#       bash voicemodel.sh new_model ~/tools/new_model ~/tools/new_model/audio ~/tools/new_model
#
# DEPENDENCIES
# 
#       CMU Sphinx
# 
# NOTES
# 
#       This script is primarily using a copy of en-us that is being actively edited as it is 
#       adapted to become a custom voice model.  
# 
#       Binaries are located in /opt/vmc/tools.
# 
# VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

model_name=$1
model_dir=$2        # location of adapted voice model files: copy of en-us, audio files, etc.
af_dir=$3           # directory containing audio files and audio feature files
sf_dir=$4           # directory containing sentence file derivatives

tools_dir=/opt/vmc/tools

pronunciation_dictionary=$tools_dir/cmudict-en-us.dict

# COMMANDS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# convert binary mdef file to .txt
cd $model_dir
pocketsphinx_mdef_convert -text $model_dir/en-us/mdef $model_dir/en-us/mdef.txt &> /dev/null

# run tools to create voice model
cd $af_dir

# sphinx_fe
sphinx_fe \
 -argfile $model_dir/en-us/feat.params \
 -samprate 16000 \
 -c $sf_dir/$model_name.fileids \
 -di . \
 -do . \
 -ei wav \
 -eo mfc \
 -mswav yes \
 &> /dev/null

$tools_dir/bw \
 -hmmdir $model_dir/en-us \
 -moddeffn $model_dir/en-us/mdef.txt  \
 -ts2cbfn .ptm. \
 -feat 1s_c_d_dd \
 -svspec 0-12/13-25/26-38 \
 -cmn current \
 -agc none \
 -dictfn $pronunciation_dictionary  \
 -ctlfn $sf_dir/$model_name.fileids \
 -lsnfn $sf_dir/$model_name.transcription \
 -accumdir . \
 &> /dev/null

$tools_dir/mllr_solve \
 -meanfn $model_dir/en-us/means  \
 -varfn $model_dir/en-us/variances \
 -outmllrfn mllr_matrix \
 -accumdir . \
 &> /dev/null

$tools_dir/map_adapt \
 -moddeffn $model_dir/en-us/mdef.txt \
 -ts2cbfn .ptm. \
 -meanfn $model_dir/en-us/means \
 -varfn $model_dir/en-us/variances \
 -mixwfn $model_dir/en-us/mixture_weights \
 -tmatfn $model_dir/en-us/transition_matrices \
 -accumdir . \
 -mapmeanfn $model_dir/en-us/means \
 -mapvarfn $model_dir/en-us/variances \
 -mapmixwfn $model_dir/en-us/mixture_weights \
 -maptmatfn $model_dir/en-us/transition_matrices\
 &> /dev/null

$tools_dir/mk_s2sendump \
 -pocketsphinx yes \
 -moddeffn $model_dir/en-us/mdef.txt \
 -mixwfn $model_dir/en-us/mixture_weights \
 -sendumpfn $model_dir/en-us/sendump \
 &> /dev/null