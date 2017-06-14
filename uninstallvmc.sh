#!/bin/bash
# 
# USAGE: bash uninstallvmc
# 

# DELETE EVERYTHING ===========================================================

sudo rm -rf /opt/vmc

sudo rm -f /usr/local/bin/vmc

sudo rm -f /usr/local/bin/lmt

echo "vmc removed."
