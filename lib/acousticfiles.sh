#!/bin/bash
# 
# DESCRIPTION -----------------------------------------------------------------
# 
#       Produce acoustic feature files from user-supplied voice recordings. 
#       These are stored with the associated audio files, and named similarly 
#       with an .mfc extension.
#
#       Do not include trailing forward slashes in the folder paths.
# 
# USAGE | EXAMPLE -------------------------------------------------------------
#   bash acousticfiles.sh /path/to/audio/folder \
#                         /path/to/acoustic/model \
#                         /path/to/model.fileids
#
# VARIABLE DEFINITIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

audio_folder_path="$1"          # e.g. ~/.psyche/audio/training
acoustic_model_location="$2"    # e.g. /usr/bin/local/python/pocketsphinx/en-us
fileids_location="$3"           # e.g. ~/.psyche/audio/training/model.fileids

# FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# generate some acoustic feature files
echo "Generating acoustic feature files..."
cd $audio_folder_path  # sphinx_fe likes to have a consistent working directory
sphinx_fe -argfile \
          "$acoustic_model_location/feat.params" \
          -samprate 16000 \
          -c $fileids_location \
          -di . \
          -do . \
          -ei wav \
          -eo mfc \
          -mswav yes \
          &> /dev/null



