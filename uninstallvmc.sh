#!/bin/bash
# 
# USAGE
# 
#       bash uninstallvmc.sh
# 

# DELETE EVERYTHING ===============================================================================

sudo rm -r /opt/vmc

sudo rm /usr/local/bin/vmc.sh

sudo rm /usr/local/bin/lmt.sh

echo "vmc removed."
