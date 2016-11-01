#!/bin/bash
# 
# DESCRIPTION
# 
#       Produce acoustic feature files from user-supplied voice recordings. These are stored with 
#       the associated audio files, and named similarly with an .mfc extension.
# 
# USAGE
# 
#       bash acousticfiles.sh /audio/folder/path /path/to/model-name.fileids
# 
# EXAMPLE
# 
#       bash /opt/vmc/functions/acousticfiles.sh ~/audio ~/audio/newmodel.fileids
#
# DEPENDENCIES
# 
#       CMU Sphinx
# 

# VARIABLES DEFINITIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

folderpath=${1%/}

fid_filepath=$2 # filename format: model-name.fileids


# FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# generate some acoustic feature files
echo "Generating acoustic feature files..."
cd $folderpath # sphinx_fe likes to have a consistent working directory
sphinx_fe -argfile /opt/vmc/tools/en-us/feat.params -samprate 16000 -c $fid_filepath -di . -do . -ei wav -eo mfc -mswav yes &> /dev/null




