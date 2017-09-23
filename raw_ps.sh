


# speed up language model loading:
# https://sourceforge.net/p/cmusphinx/discussion/sphinx4/thread/45c90207/

filenamedir=$save_directory/$lm_filename.lm
bash /opt/vmc/lib/move_ps_files.sh -into_lib
LD_LIBRARY_PATH=/usr/local/lib; export LD_LIBRARY_PATH

pocketsphinx_continuous \
    -inmic yes \
    -lm /opt/psyche/modules/system/testlm.lm.bin \
    -dict /opt/psyche/lib/cmudict-en-us.dict

bash /opt/vmc/lib/move_ps_files.sh -out_of_lib