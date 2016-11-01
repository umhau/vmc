#!/bin/bash
# 
# USAGE 
# 
#       bash installdependencies.sh [installation folder path]
# 
# EXAMPLE
#
#       bash installdependencies.sh ~/tools
# 
# NOTES
# 
#       A number of tools are installed to a user-specified location.  These include SphinxTrain 
#       and PocketSphinx.  This installation folder is presumed to be a direct subdirectory of the
#       user's home directory.
# 
#       The script will use all the computer's cores to compile packages.
# 
#       This may not work forever, as the CMU Sphinx packages are downloaded from github, where 
#       they are under active development.
# 

# VARIABLES =======================================================================================

installation_directory=$1

# PREPARATION =====================================================================================

echo

# check that installation folder has been specified
if [ ! -n "$installation_directory" ]; then
    echo
    echo "**Error**: you must specify installation folder for CMU programs."
    echo "Folder should be specified relative to the home directory."
    echo "Recommended: 'bash install.sh tools'"
    exit 64
fi

# check number of cores (speeds compilation)
CORES=$(nproc --all 2>&1)


# make sure folder exists
if [ ! -d $installation_directory ]; then
  mkdir $installation_directory
fi

# INSTALL CMU SPHINX DEPENDENCIES =================================================================

# NOTE: I prefer to let apt detect prior installation. it makes the code much nicer to read.

# needed for installations
echo "Installing git..."
sudo apt-get install git -y
echo

echo "Installing swig..."
sudo apt-get install swig -y
echo

# used to build LM
echo "Installing perl..."
sudo apt-get install perl -y
echo

# python development version: needed for sphinxbase
echo "Installing python-dev..."
sudo apt-get install python-dev -y
echo

# used for audio recordings
echo "Installing python3-pyaudio..."
sudo apt-get install python3-pyaudio -y
echo

# used in some scripts
echo "Installing python3..."
sudo apt-get install python3 -y
echo

echo "Installing libtool..."
sudo apt-get install libtool-bin -y
echo

echo "Installing automake..."
sudo apt-get install automake -y
echo

echo "Installing autoconf..."
sudo apt-get install autoconf -y
echo

# INSTALL CMU SPHINX PACKAGES =====================================================================

# check for and install sphinxbase
echo -n "Checking for sphinxbase...."
if [ ! -d $installation_directory/sphinxbase/ ]; then
    echo
    echo "installing..."
    cd $installation_directory
    git clone https://github.com/cmusphinx/sphinxbase.git
    cd ./sphinxbase
    ./autogen.sh
    ./configure
    make -j $CORES
    make -j $CORES check
    sudo make -j $CORES install
else
  echo "Done."
  echo "SphinxBase already installed."
  echo
fi

# check for and install sphinxtrain
echo -n "Checking for sphinxtrain...."
if [ ! -d $installation_directory/sphinxtrain/ ]; then
    echo
    echo -n "installing..."
    cd $installation_directory
    git clone https://github.com/cmusphinx/sphinxtrain.git
    cd ./sphinxtrain
    ./autogen.sh
    ./configure
    make -j $CORES
    sudo make -j $CORES install
    echo "Done."
else
  echo "Done."
  echo "SphinxTrain already installed."
  echo
fi


# check for and install pocketsphinx
echo -n "Checking for pocketsphinx..."
if [ ! -d $installation_directory/pocketsphinx/ ]; then
    echo
    echo -n "installing..."
    cd $installation_directory
    git clone https://github.com/cmusphinx/pocketsphinx.git
    cd ./pocketsphinx
    ./autogen.sh
    ./configure
    make -j $CORES clean all
    make -j $CORES check
    sudo make -j $CORES install
    echo "done."
else
  echo "Done."
  echo "PocketSphinx already installed."
  echo
fi

echo "vmc dependency installations completed. See README for next steps."
echo




