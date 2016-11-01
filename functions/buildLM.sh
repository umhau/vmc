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

sentence_list=$1

model_name=$2

save_directory=$3

tools_dir=/opt/vmc/tools

# COMMANDS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# run perl script to create language model
perl $tools_dir/quick_lm.pl -s $sentence_list &> /dev/null

# quick_lm creates output in its own directory.  I can fix that later, after I learn perl.
src=$tools_dir/$sentence_list.arpabo
dst=$tools_dir/$model_name.lm
mv $src $dst

# convert lm to binary (bin) format (command was too complex for python to handle)
filename=$tools_dir/$model_name.lm
sphinx_lm_convert -i $dst -o $dst.bin &> /dev/null

# move into working directory
mv $tools_dir/$model_name.lm $save_directory/$model_name.lm

