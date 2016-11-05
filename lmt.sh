#!/bin/bash
# 
# DESCRIPTION
# 
#       Given a list of sentences, create a statistical language model.  
#
# USAGE
# 
#       lmt.sh lm-training-file lm-file-name output-location
#
# DEPENDENCIES
# 
#       CMU Sphinx, Perl, and other misc. packages.
# 

# VARIABLES =======================================================================================

if [[ -z $1 ]]; then 
   
    echo
    echo -e "USAGE: \tlmt.sh "
    echo 
    echo -e "\tlm-training-file\t(used to name most of the internal files)"
    echo -e "\tsentence-list\t\t(sentences for the user to record)"
    echo -e "\toutput-location\t\t(location to save the LM into)"
    echo

    exit 1

fi

lm_training_file=$1

lm_file_name=$2

output_location=$3

fdir=/opt/vmc/functions

# COMMANDS ========================================================================================

# build language model
bash $fdir/buildLM.sh $lm_training_file $lm_file_name $output_location

echo
echo "Done."
echo
