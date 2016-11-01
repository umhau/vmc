#!/bin/bash
# 
# USAGE
# 
#       sudo bash installvmc.sh
# 
# NOTES
# 
#       Copies the vmc packages into /opt/vmc, and puts the vmc script into /usr/local/bin.  Once
#       there, vmc can be called (with its requisite options) from anywhere with just vmc.sh.
# 


# SET VARIABLES ===================================================================================

 
script=$(readlink -f "$0") # Absolute path to this script, e.g. /home/user/bin/foo.sh
scriptpath=$(dirname "$script") # Absolute path this script is in, thus /home/user/bin
        # http://stackoverflow.com/questions/242538/unix-shell-script-find-out-which-directory-the-script-file-resides

tdir=/opt/vmc/tools

fdir=/opt/vmc/functions

# MOVE VMC FILES ==================================================================================

echo "Installing vmc..."

# create vmc directories
sudo mkdir -p $tdir
sudo mkdir -p $fdir

# move tools
sudo cp -r $scriptpath/tools/* $tdir/

sudo tar -xf $scriptpath/cmusphinx-en-us-ptm-5.2.tar.gz -C $tdir
sudo mv  $tdir/cmusphinx-en-us-ptm-5.2 $tdir/en-us

# move functions
sudo cp -r $scriptpath/functions/* $fdir/

# move vmc into user's path 
sudo cp $scriptpath/vmc.sh /usr/local/bin/vmc.sh


# GET SPHINXTRAIN BINARIES ========================================================================

# copy binary tools into model folder
cp /usr/local/libexec/sphinxtrain/bw $tdir
cp /usr/local/libexec/sphinxtrain/map_adapt $tdir
cp /usr/local/libexec/sphinxtrain/mk_s2sendump $tdir
cp /usr/local/libexec/sphinxtrain/mllr_solve $tdir

echo "Done."

