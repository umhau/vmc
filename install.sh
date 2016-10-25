#!/bin/bash
# USAGE: bash install.sh [installation folder]
#
# installation folder is presumed to be a direct subdirectory of the 
# user's home directory.  The script will use all the computer's cores
# to perform compilations.


# check that installation folder has been specified
if [ ! -n "$1" ]; then
    echo
    echo "**Error**: you must specify installation folder for CMU programs."
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

# check for git (needed for installations)
echo -n "Checking for git..."
(git --version) < /dev/null > /dev/null 2>&1 || {
  echo
  echo -n "installing..."
  sudo apt-get install git
  echo "done."
}
echo

# check for swig
echo -n "Checking for swig..."
(swig -help) < /dev/null > /dev/null 2>&1 || {
  echo
  echo -n "Installing swig..."
  sudo apt-get install swig
  echo "done."
}
echo

# check for python development version: needed for sphinxbase
# There's no good way to check for this, so just install if possible.
echo "Installing python-dev..."
(sudo apt-get install python-dev) < /dev/null > /dev/null 2>&1 || {
  echo
  echo -n "installing..."
  #sudo apt-get install python-dev
  echo "done."
}

# check for python3: used in model scripts
echo -n "Checking for python3..."
(python3 --version) < /dev/null > /dev/null 2>&1 || {
  echo
  echo -n "installing..."
  sudo apt-get install python3
  echo "done."
}
echo

# check for sphinxbase
echo -n "Checking for sphinxbase..."
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
  echo "already here."
fi

# check for sphinxtrain
echo -n "Checking for sphinxtrain..."
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
    echo "done."
else
  echo "already here."
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
  echo "already here."
fi

echo
echo "Dependency installations completed."
