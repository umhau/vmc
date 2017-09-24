#!/bin/bash

# USAGE =======================================================================
#
#   a number of shared libraries are kept in /usr/local/lib/.  They are 
#   incompatible with the python pocketsphinx package.  This script moves them 
#   between their installed location and the installation directory for the
#   rest of the CMU Sphinx dependencies. 
#
#   bash move_ps_files.sh -into_lib
#   bash move_ps_files.sh -out_of_lib
#
#   This script is run at the beginning and at the end of the VMC program.
#
# VARIABLES ===================================================================

option="$1"
username=$(logname)
lib_backup_dir="/home/$username/CMU_Sphinx/shared_library_backup"

# FUNCTIONS ===================================================================

move_files_out_of_lib() {


    sudo mv /usr/local/lib/libpocketsphinx* $lib_backup_dir
    sudo mv /usr/local/lib/libsphinx* $lib_backup_dir
    sudo mv /usr/local/lib/sphinxtrain $lib_backup_dir

}

copy_files_into_lib() {

    sudo cp $lib_backup_dir/libpocketsphinx* /usr/local/lib
    sudo cp $lib_backup_dir/libsphinx* /usr/local/lib
    sudo cp -r "$lib_backup_dir/sphinxtrain" /usr/local/lib
    sudo chmod +x /usr/local/lib/*

}

delete_files_from_lib() {

    sudo rm -f /usr/local/lib/libpocketsphinx*
    sudo rm -f /usr/local/lib/libsphinx*
    sudo rm -fr /usr/local/lib/sphinxtrain

}

clean_lib_directory() {

    if [ -d "$lib_backup_dir" ]
    then
        delete_files_from_lib
    else
        mkdir -p "$lib_backup_dir"
        move_files_out_of_lib
    fi


}

ensure_files_are_present() {

    if [ ! -d "$lib_backup_dir" ] # if no backup made, assume files are present
    then 
        :
    else
        copy_files_into_lib
    fi

}

main() {

    if   [ $option == "-into_lib" ]; then ensure_files_are_present;
    elif [ $option == "-out_of_lib" ]; then clean_lib_directory; 
    else echo "bad options given"
    fi

}

# COMMANDS ====================================================================

main
