#!/bin/bash
# 
# DESCRIPTION
# 
#       Given a list of sentences, create a statistical language model.  
#
# USAGE: lmt.sh lm-training-file lm-file-name output-location
#
# VARIABLES ===================================================================

sentence_list_file=$1; output_lm_file_name=$2; save_directory=$3; 

fdir=/opt/vmc/functions

# CHECK IF HELP NEEDED ========================================================

if [[ -z $1 ]]; then 
   
    echo
    echo -e "USAGE: \tlmt.sh "
    echo 
    echo -e "\tsentence_list_file\t(input file with sample sentences)"
    echo -e "\toutput_lm_file_name\t(desired base name of output lm file)"
    echo -e "\tsave_directory\t\t(location to save the ouput file into)"
    echo

    exit 1

fi

# COMMANDS ====================================================================

# build language model
bash $fdir/buildLM.sh $sentence_list_file $output_lm_file_name $save_directory


