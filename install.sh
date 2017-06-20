#!/bin/bash
# 
# USAGE =======================================================================
# 
#       bash install.sh -no-deps
# 
# NOTES =======================================================================
# 
#       Copies the vmc packages into /opt/vmc, and puts the vmc script into
#       /usr/local/bin.  Once there, vmc can be called (with its requisite 
#       options) from anywhere with just vmc.sh.
#
#       The script will use all the computer's cores to compile packages.
#
#       A number of tools are installed to a user-specified location.  These 
#       include SphinxTrain and PocketSphinx.  This installation folder is 
#       presumed to be a direct subdirectory of the user's home directory. 
#
#       This may not work forever, as the CMU Sphinx packages are downloaded 
#       from github, where they are under active development.
# 
# SET VARIABLES ===============================================================

# Absolute path to this script & containing folder.  stackoverflow.com/q/242538
script=$(readlink -f "$0"); scriptpath=$(dirname "$script") 

libdir=/opt/vmc/lib
install_dir="/home/$USER/CMU_Sphinx"

# check number of cores (speeds compilation)
CORES=$(nproc --all 2>&1)

# CMU Sphinx install location - my static repo or the official source?
CMUsrc="cmusphinx" # or "umhau"

# CHECK FOR PREVIOUS INSTALLATION =============================================

if [ -d /opt/vmc/ ]; then
    bash "vmc -remove 1>/dev/null"; echo "Removed vmc"
fi

# INSTALL VMC DEPENDENCIES ====================================================
if [ ! "$1" == '-no-deps' ]; then

    echo "Installing dependencies. To continue, press [enter]."; read

    if [ ! -d $install_dir ]; then mkdir $install_dir; fi

    # let apt auto-detect the installation state of the dependencies
    sudo apt-get install git swig perl bison libtool-bin automake autoconf -y
    sudo apt-get install python-dev python3 python3-pyaudio -y

    # check for and install sphinxbase
    echo -n "Checking for SphinxBase...."
    if [ ! -d $install_dir/sphinxbase/ ]; then
        echo "installing..."; cd $install_dir
        git clone "https://github.com/$CMUsrc/sphinxbase.git"
        cd ./sphinxbase
        ./autogen.sh --with-sphinxbase-build
        ./configure 
        make -j $CORES
        make -j $CORES check
        sudo make -j $CORES install
        sudo chown -R $USER: $install_dir # bug: dir had root ownership.
    else
        echo "SphinxBase already installed."
    fi

    # check for and install sphinxtrain
    echo "Checking for sphinxtrain...."
    if [ ! -d $install_dir/sphinxtrain/ ]; then
        echo "installing..."; cd $install_dir
        git clone "https://github.com/$CMUsrc/sphinxtrain.git"
        cd ./sphinxtrain
        ./autogen.sh
        ./configure
        make -j $CORES
        sudo make -j $CORES install
        sudo chown -R $USER: $install_dir # bug: dir had root ownership.
    else
        echo "SphinxTrain already installed."
    fi

    # check for and install pocketsphinx
    echo -n "Checking for pocketsphinx..."
    if [ ! -d $install_dir/pocketsphinx/ ]; then
        echo "installing..."; cd $install_dir
        git clone "https://github.com/$CMUsrc/pocketsphinx.git"
        cd ./pocketsphinx
        ./autogen.sh
        ./configure
        make -j $CORES clean all
        make -j $CORES check
        sudo make -j $CORES install
        sudo chown -R $USER: $install_dir # bug: dir had root ownership.
    else
        echo "PocketSphinx already installed."
    fi

else echo -n "NOT installing dependencies. To continue, press [enter]."; read
fi

# MOVE VMC FILES ==============================================================

# get sudo 
sudo ls 1>/dev/null; echo -en "\nInstalling vmc..."

# create vmc directories
sudo mkdir -p $libdir; sudo mkdir -p $libdir

# move library
sudo cp -r $scriptpath/lib/* $libdir/

sudo tar -xf $scriptpath/lib/cmusphinx-en-us-ptm-5.2.tar.gz -C $libdir
sudo mv  $libdir/cmusphinx-en-us-ptm-5.2 $libdir/en-us

# move vmc into user's path & set as executable
sudo cp $scriptpath/vmc /usr/local/bin/vmc
sudo chmod +x /usr/local/bin/vmc

# move lmc into user's path  & set as executable
sudo cp $scriptpath/lmc /usr/local/bin/lmc
sudo chmod +x /usr/local/bin/lmc

# GET SPHINXTRAIN BINARIES ========================================================================

# copy binary tools into model folder
sudo cp /usr/local/libexec/sphinxtrain/bw $libdir
sudo cp /usr/local/libexec/sphinxtrain/map_adapt $libdir
sudo cp /usr/local/libexec/sphinxtrain/mk_s2sendump $libdir
sudo cp /usr/local/libexec/sphinxtrain/mllr_solve $libdir

echo "done."

