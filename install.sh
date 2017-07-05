#!/bin/bash
# 
# USAGE =======================================================================
# 
#       bash install.sh 
#       bash install.sh -inc-deps (just the program files, used in development)
#       bash install.sh -refresh (removes program files & CMU Sphinx)
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

option="$1"

# Absolute path to this script & containing folder.  stackoverflow.com/q/242538
script=$(readlink -f "$0")
scriptpath=$(dirname "$script") 

# CMU Sphinx install location - my static repo or the official source?
CMUsrc="cmusphinx" # or "umhau"

install_dir="/home/$USER/CMU_Sphinx"

# FUNCTIONS ===================================================================

look_for_and_remove_old_installation() {

    if [ -d /opt/vmc ]; then

        sudo rm -rf /opt/vmc
        sudo rm -f /usr/local/bin/vmc
        sudo rm -f /usr/local/bin/lmc

    fi

}

install_dependencies() {

    local CORES=$(nproc --all 2>&1)

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
    echo -n "Checking for sphinxtrain...."
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

    # # check for and install pocketsphinx
    # echo -n "Checking for pocketsphinx..."
    # if [ ! -d $install_dir/pocketsphinx/ ]; then
    #     echo "installing..."; cd $install_dir
    #     git clone "https://github.com/$CMUsrc/pocketsphinx.git"
    #     cd ./pocketsphinx
    #     ./autogen.sh
    #     ./configure
    #     make -j $CORES clean all
    #     make -j $CORES check
    #     sudo make -j $CORES install
    #     sudo chown -R $USER: $install_dir # bug: dir had root ownership.
    # else
    #     echo "PocketSphinx already installed."
    # fi

}

create_vmc_directories() {

    sudo mkdir -p /opt/vmc
    sudo mkdir -p /opt/vmc/lib


}

install_program_files() {

    # move library
    sudo cp -r $scriptpath/lib/* /opt/vmc/lib/

    sudo tar -xf $scriptpath/lib/cmusphinx-en-us-ptm-5.2.tar.gz -C /opt/vmc/lib/
    sudo mv /opt/vmc/lib/cmusphinx-en-us-ptm-5.2 /opt/vmc/lib/en-us

    # move vmc into user's path & set as executable
    sudo cp $scriptpath/vmc /usr/local/bin/vmc
    sudo chmod +x /usr/local/bin/vmc

    # move lmc into user's path  & set as executable
    sudo cp $scriptpath/lmc /usr/local/bin/lmc
    sudo chmod +x /usr/local/bin/lmc

}

copy_CMU_Sphinx_binaries() {

    sudo cp /usr/local/libexec/sphinxtrain/bw /opt/vmc/lib
    sudo cp /usr/local/libexec/sphinxtrain/map_adapt /opt/vmc/lib
    sudo cp /usr/local/libexec/sphinxtrain/mk_s2sendump /opt/vmc/lib
    sudo cp /usr/local/libexec/sphinxtrain/mllr_solve /opt/vmc/lib

}

remove_CMU_Sphinx() {

    # this is all the stuff I'm aware of. CMU Sphinx docs are opaque on this.

    sudo rm -f /usr/local/lib/libpocketsphinx*
    sudo rm -f /usr/local/lib/libsphinx*
    sudo rm -fr /usr/local/lib/sphinxtrain

    sudo rm -fr /usr/local/libexec/sphinxtrain

    sudo rm -fr $install_dir

}


# MAIN ========================================================================

main() {

    sudo ls 1>/dev/null; echo "installing voice model creator"

    look_for_and_remove_old_installation

    if [ "$option" == "-inc-deps" ]; then install_dependencies;
    elif [ "$option" == "-refresh" ]; then remove_CMU_Sphinx; install_dependencies;
    else echo "not installing dependencies"; fi

    create_vmc_directories

    install_program_files

    copy_CMU_Sphinx_binaries

    bash $scriptpath/lib/move_ps_files.sh -out_of_lib

    echo -e "\nVMC installation complete"

}

main
