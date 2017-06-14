#!/bin/bash
# 
# DESCRIPTION
# 
#       Produce binary language model from plain sentence list.  Invokes CMU-created perl script
#       located in /opt/vmc/tools.  Saves file in given directory.
# 
# USAGE
# 
#       bash buildLM.sh sentence-list model-name save-directory
#
# DEPENDENCIES
# 
#       CMU Sphinx
# 
# VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sentence_list_path=$1

model_name=$2

save_directory=$3

tools_dir=/opt/vmc/tools

# COMMANDS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# run perl script to create language model
perl $tools_dir/quick_lm.pl -s $sentence_list_path #&> /dev/null

sentence_list=`basename $sentence_list_path`

sentence_list_dir=`dirname $sentence_list_path`

# rename output
src=$sentence_list_path.arpabo
dst=$save_directory/$model_name.lm
mv $src $dst

# convert lm to binary (bin) format (command was too complex for python to handle)
filename=$save_directory/$model_name.lm
sphinx_lm_convert -i $filename -o $filename.bin &> /dev/null

