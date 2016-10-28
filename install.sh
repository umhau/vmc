#!/bin/bash
# USAGE: bash install.sh [installation folder]
#
# installation folder is presumed to be a direct subdirectory of the 
# user's home directory.  The script will use all the computer's cores
# to perform compilations.

echo
# check that installation folder has been specified
if [ ! -n "$1" ]; then
    echo
    echo "**Error**: you must specify installation folder for CMU programs."
    echo "Folder should be specified relative to the home directory."
    echo "Recommended: 'bash install.sh tools'"
    exit 64
fi

# check number of cores (speeds compilation)
CORES=$(nproc --all 2>&1)


# make sure folder exists
if [ ! -d /home/$USER/$1 ]; then
  mkdir /home/$USER/$1
fi


# CHECK DEPENDENCIES
# note on installation tactics: I prefer to let apt detect prior installation.
# It makes the code much nicer to read.

# check for git (needed for installations)
echo "Installing git..."
sudo apt-get install git -y
echo

# check for swig
echo "Installing swig..."
sudo apt-get install swig -y
echo

# check for perl
echo "Installing perl..."
sudo apt-get install perl -y
echo

# check for python development version: needed for sphinxbase
echo "Installing python-dev..."
sudo apt-get install python-dev -y
echo

# install pyaudio
echo "Installing python3-pyaudio..."
sudo apt-get install python3-pyaudio -y
echo

# check for python3: used in model scripts
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


# check for sphinxbase
echo -n "Checking for sphinxbase...."
if [ ! -d ~/$1/sphinxbase/ ]; then
    echo
    echo "installing..."
    cd ~/$1
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

# check for sphinxtrain
echo -n "Checking for sphinxtrain...."
if [ ! -d ~/$1/sphinxtrain/ ]; then
    echo
    echo -n "installing..."
    cd ~/$1
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


# check for pocketsphinx
echo -n "Checking for pocketsphinx..."
if [ ! -d ~/$1/pocketsphinx/ ]; then
    echo
    echo -n "installing..."
    cd ~/$1
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

echo "VMC dependency installations completed. See README for next steps."
echo




