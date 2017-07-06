#!/bin/bash

script=$(readlink -f "$0")
scriptpath=$(dirname "$script") 

model_location="/tmp/test_model"
audio_recordings_location="/tmp/test_audio_recordings"
dict_file="/tmp/test_dict_file.txt"

printf "hello\nworld\ntest phrases\nlast one now\n" > "$dict_file"


vmc model_name \
-create $model_location \
-newrecordings $audio_recordings_location $dict_file 1

