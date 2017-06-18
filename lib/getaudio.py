#!/usr/bin/python3
# 
# DESCRIPTION
# 
#       getaudio is used to sequentially prompt the user for dictations of 
#       displayed sentences.
#
# DEPENDENCIES: python3-pyaudio, python3
#
# USAGE
# 
#       python3 getaudio.py /path/to/simple-list-of-sentences.txt \
#                           /audio/recording/folder \
#                           recording-repetitions \
#                           model-name \
#                           num_of_preexisting_audio_recordings
#
# LIBRARY IMPORTS -------------------------------------------------------------

import sys, os, _thread, pyaudio, wave, contextlib

# VARIABLE DEFINITIONS --------------------------------------------------------

chunk = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000

sentence_file = sys.argv[1]                # e.g. ~/sentencelist.txt
audio_recording_folder = sys.argv[2].rstrip(os.sep) # e.g. ~/.psyche/audio
reps = int(sys.argv[3])                    # e.g. 5
model_name = sys.argv[4]                   # e.g. 'en-us'

try:
    recording_count = int(sys.argv[5]) # how many audio files already exist
except IndexError:
    recording_count = 0

# FUNCTION DEFINITIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ignore sdterr messages: as from pyaudio
@contextlib.contextmanager
def ignore_stderr():
    devnull = os.open(os.devnull, os.O_WRONLY)
    old_stderr = os.dup(2)
    sys.stderr.flush()
    os.dup2(devnull, 2)
    os.close(devnull)
    try:
        yield
    finally:
        os.dup2(old_stderr, 2)
        os.close(old_stderr)

def record_until_keypress(audio_filepath):

    # detect keypress [enter]
    def input_thread(L):
        input()
        L.append(None)

    # initialize audio stream - and keep it quiet
    with ignore_stderr():
        p = pyaudio.PyAudio()
        stream = p.open(format = FORMAT,
                channels = CHANNELS,
                rate = RATE,
                input = True,
                frames_per_buffer = chunk)

    # create interrupt thread
    L = []
    _thread.start_new_thread(input_thread, (L,))
    
    # record data during loop
    frames = []
    while True:
        data = stream.read(chunk)
        frames.append(data)
        if L: 
            stream.stop_stream()
            break
    
    # exit cleanly after break
    stream.close()
    p.terminate()
    
    # write data to WAVE file
    data = b''.join(frames)
    wf = wave.open(audio_filepath, 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(p.get_sample_size(FORMAT))
    wf.setframerate(RATE)
    wf.writeframes(data)
    wf.close()


# LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if not os.path.exists(audio_recording_folder):
    raise NotADirectoryError("Audio recording save folder does not exist.")

# create list of sentences for prompt
sentence_list = []
with open(sentence_file) as f:
    for line in f:
        sentence_list.append(line)

num_recs = len(sentence_list)*reps+recording_count

# collect audio files
try:

    input("Press [enter], read text, & press [enter].")

    for sentence in sentence_list*reps: 
        #recording number
        recording_count+=1

        # record audio with visual
        print("Recording no. %04d of %04d: \n\n\t%s" % (recording_count, num_recs, sentence), end='\r')

        # recording file should look like this (e.g.): ./bespoke_training_data/audio/arctic_0001.wav        
        record_until_keypress(str(audio_recording_folder + os.sep + model_name + "_%04d.wav" % recording_count))

except KeyboardInterrupt:
    pass


