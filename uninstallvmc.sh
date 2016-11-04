#!/bin/bash
# 
# USAGE
# 
#       bash uninstallvmc.sh
# 

# DELETE EVERYTHING ===============================================================================

sudo rm -rf /opt/vmc

sudo rm -f /usr/local/bin/vmc.sh

sudo rm -f /usr/local/bin/lmt.sh

echo "vmc removed."
