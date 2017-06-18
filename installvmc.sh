#!/bin/bash
# 
# USAGE =======================================================================
# 
#       bash installvmc.sh
# 
# NOTES =======================================================================
# 
#       Copies the vmc packages into /opt/vmc, and puts the vmc script into
#       /usr/local/bin.  Once there, vmc can be called (with its requisite 
#       options) from anywhere with just vmc.sh.
# 
# SET VARIABLES ===============================================================

# Absolute path to this script & containing folder.  stackoverflow.com/q/242538
script=$(readlink -f "$0"); scriptpath=$(dirname "$script") 

libdir=/opt/vmc/lib

# CHECK FOR PREVIOUS INSTALLATION =============================================

if [ -d /opt/vmc/ ]; then

    bash $scriptpath/uninstallvmc.sh 1>/dev/null; echo -n "Removed vmc"; 
    
    # echo "vmc is already installed.  To remove, run uninstallvmc.sh"; exit 1

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

# move lmt into user's path  & set as executable
sudo cp $scriptpath/lmt /usr/local/bin/lmt
sudo chmod +x /usr/local/bin/lmt

# GET SPHINXTRAIN BINARIES ========================================================================

# copy binary tools into model folder
sudo cp /usr/local/libexec/sphinxtrain/bw $libdir
sudo cp /usr/local/libexec/sphinxtrain/map_adapt $libdir
sudo cp /usr/local/libexec/sphinxtrain/mk_s2sendump $libdir
sudo cp /usr/local/libexec/sphinxtrain/mllr_solve $libdir

echo "done."

