#!/usr/bin/python3
#
#dependencies: python3-pyaudio

from subprocess import Popen
from subprocess import call
import string
import re
import _thread
import time
import pyaudio
import wave
#import string
import os
import errno
import contextlib
import sys
import shutil
#import os.path
from shutil import copyfile
import tarfile


# tool to check if programs are installed
def is_tool(name):
    try:
        devnull = open(os.devnull)
        Popen([name], stdout=devnull, stderr=devnull).communicate()
    except OSError as e:
        if e.errno == os.errno.ENOENT:
            return False
    return True


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

# detect any keypress
def input_thread(L):
    input()
    L.append(None)

def record(WAVE_OUTPUT_FILENAME):

    chunk = 1024
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 16000

    with ignore_stderr():
        # initialize audio stream - and keep it quiet
        p = pyaudio.PyAudio()
        stream = p.open(format = FORMAT,
                channels = CHANNELS,
                rate = RATE,
                input = True,
                frames_per_buffer = chunk)

    # create interrupt thread
    L = []
    _thread.start_new_thread(input_thread, (L,))
    
    frames = []
    while True:
        # record data during loop
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
    wf = wave.open(WAVE_OUTPUT_FILENAME, 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(p.get_sample_size(FORMAT))
    wf.setframerate(RATE)
    wf.writeframes(data)
    wf.close()


def vmc(model_name, sentence_file, voice_training_iterations=1):
    """
    [model_name] a clear identifier for the specific recognition model. 
    [sentence_file] the pathname for the input file containing the sentences to
    train on. [voice_training_iterations] integer representing the ratio of 
    voice data collected to total sentences. 0 = no voice data collected (use 
    what you have), 1 = a single recording of each sentence, 2=two recordings 
    of each sentence, &c.
    
    """
    # get 'sentences' with all the sample lines. 
    sentences_text = ""
    sentences_list = []
    with open(sentence_file) as f:
        for line in f:
            sentences_text = sentences_text+' '+line
            sentences_list.append(line)

    # record more voice samples?
    if voice_training_iterations>0:

        sentences_list=sentences_list*voice_training_iterations

        num_recs = len(sentences_list)
        j=0
        try:
            input("Press [enter], read text, & press [enter].")
            for sentence in sentences_list: 
                #recording number
                j=j+1
                afno = str('%04d'%j) # audio file number w/ 4 digits
                # record audio with visual
                print("Recording no. %04d of %04d: \n\n\t%s" % (j, num_recs, sentence), end='\r')

                # recording file should look like this (e.g.): ./bespoke_training_data/audio/arctic_0001.wav
                audio_file_name = "./" + model_name +'/audio/' + model_name+ "_" + afno + ".wav"
                
                record(audio_file_name)
                
                # add formatted data to language model files
            
                #transcription file
                nice_text = sentence.lower().rstrip()#.translate(string.maketrans('', ''), ',.')
                formatted_text = "</s> " +  nice_text +  " </s> (" + model_name + "_" + afno + ")\n"
                formatted_filename = "./" + model_name + "/" +model_name + '.transcription'             
                hs = open(formatted_filename,"a")
                hs.write(formatted_text)
                hs.close() 

                #fileid
                formatted_text = model_name + "_" + afno + "\n"
                formatted_filename = "./" + model_name + "/" +model_name + '.fileids'
                hs = open(formatted_filename,"a")
                hs.write(formatted_text)
                hs.close() 
                        
        except KeyboardInterrupt:
            pass
    

    # create LM file from sentences. 
    var = str("-s " + sentence_file)
    pfile = "./quick_lm.pl"
    pipe = Popen(["perl", pfile, var])
    src = './'+sentence_file + '.arpabo'
    dst = model_name+'/'+model_name+'.lm'

    # wait for perl script to create lm file
    while 1:
        if os.path.isfile(src):
            break

    #create a properly-named copy in directory, then delete original
    copyfile(src, dst)
    os.remove(src)

    # create unique, sorted word list from sentence list
    words = []
    [words.append(word.strip(string.punctuation).upper()) for word in sentences_text.split()]
    uwords = sorted(list(set(words))) # convert to set to 'unique' the list, and back for convenience
    
    # save word list to file
    uwordsfilename = str(model_name+'/'+sentence_file+'.vocab') # correct extension
    uwordsfile = open(uwordsfilename, 'w')
    for word in uwords:
        uwordsfile.write("%s\n" % word)

    # create pronunciation dictionary from word list
    cmudict = []
    with open("cmudict_SPHINX_40.txt") as f:
        for line in f:
            cmudict.append(line)

    pdict = []
    missing_words = []
    for word in uwords:
        wordmatch=False # a counter to help with efficiency
        for line in cmudict:  
            
            regex_string = str(word + '(\(\d\))?\s+')
            #print(regex_string)
            # match: word, optional number in braces, and space.
            if re.match(regex_string, line):
                pdict.append(line)
                wordmatch=True
            
            # if I already made a match and I'm not now, time to break. this allows for 
            # finding alternate pronunciations
            elif wordmatch: 
                break
        
        # check for words the pronunciation dictionary doesn't have & save
        if not wordmatch:
            missing_words.append(word)

    # save missing words list to file
    if missing_words:
        missing_words_filename = str(model_name+'/'+sentence_file+'.missing')
        print("\nWord(s) missing from pronunciation dictionary. See ")
        print(missing_words_filename+" for list.\n")
        mwordsfile = open(missing_words_filename, 'w')
        for word in missing_words:
            mwordsfile.write("%s\n" % word)
                
    # save pronunciation dictionary to file
    pdictfilename = str(model_name+'/'+sentence_file+'.dic')
    pdictfile = open(pdictfilename, 'w')
    for word_entry in pdict:
        pdictfile.write(word_entry)

    # final instructions
    print("Data files created.\n")


# set up input perameters
i = len(sys.argv)

# if using default iterations value
if i==3:
    model_name = str(sys.argv[1])
    sentence_list_filename = str(sys.argv[2])

    vmc(model_name, sentence_list_filename)

# if specifying iterations value
elif  i==4:
    model_name = str(sys.argv[1])
    sentence_list_filename = str(sys.argv[2])
    voice_training_iterations = int(sys.argv[3])
    vmc(model_name, sentence_list_filename,voice_training_iterations)

# error if wrong number of perameters entered
# NOT IF PART OF SHELL SCRIPT?
else:
    raise TypeError("vmc requires at least two perameters!")








