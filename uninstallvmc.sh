#!/bin/bash
# 
# USAGE
# 
#       bash uninstallvmc.sh
# 

# DELETE EVERYTHING ===============================================================================

sudo rm -r /opt/vmc

sudo rm /usr/local/bin/vmc.sh

echo "vmc removed."