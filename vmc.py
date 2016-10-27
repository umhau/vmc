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


import sys

# Print iterations progress
def printProgress (iteration, total, prefix = '', suffix = '', decimals = 1, barLength = 100):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        barLength   - Optional  : character length of bar (Int)
    """
    formatStr       = "{0:." + str(decimals) + "f}"
    percents        = formatStr.format(100 * (iteration / float(total)))
    filledLength    = int(round(barLength * iteration / float(total)))
    bar             = '█' * filledLength + '-' * (barLength - filledLength)
    sys.stdout.write('\r%s |%s| %s%s %s' % (prefix, bar, percents, '%', suffix)),
    if iteration == total:
        sys.stdout.write('\n')
    sys.stdout.flush()


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


# format sentences and add to file
def sentence_format_and_save(sentence, model_name, afno): # afno: audio file number with 4 digits

    #transcription file

    # get rid of punctuation
    exclude = set(string.punctuation)
    sentence = ''.join(ch for ch in sentence if ch not in exclude)

    nice_text = sentence.lower().rstrip()#.translate(string.maketrans('', ''), ',.')
    formatted_text = "</s> " +  nice_text +  " </s> (" + model_name + "_" + afno + ")\n"
    # formatted_text = nice_text+"\n"
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



def sentence_parsing(sentences_text, model_name, sentence_file, pronunciation_dictionary):
    # create unique, sorted word list from sentence list
    words = []
    print("Creating unique, sorted word list...\n")
    [words.append(word.strip(string.punctuation).upper()) for word in sentences_text.split()]
    # set() uniques the list, sorted() puts them a-z.
    uwords = sorted(list(set(words))) 
    
    # save word list to file
    print("Saving word list to file...\n")
    uwordsfilename = str(model_name+'/'+model_name+'.vocab') # correct extension
    uwordsfile = open(uwordsfilename, 'w')
    for word in uwords:
        uwordsfile.write("%s\n" % word)

    # create pronunciation dictionary from word list
    cmudict = []
    print("Opening pronunciation dictionary...\n")
    with open(pronunciation_dictionary) as f:
        for line in f:
            cmudict.append(line)

    pdict = []
    missing_words = []
    l = len(uwords)
    i = 0
    print("Extracting entries corresponding to word list...\n")
    printProgress (i, l, prefix = 'Progress:', suffix = 'Complete', decimals = 2, barLength = 20)

    curr_line = 0

    for word in uwords:
        
        wordmatch=False # a counter to help with efficiency
        for line in cmudict[curr_line:]:        
            
            regex_string = str('^(?P<text>'+str(word.lower()) + '(\(\d\))?)( |\t)(?P<phones>.+)$')

            if re.match(regex_string, line):
                # print("match!")
                ms = re.search(regex_string, line)
                pdict.append(str(ms.group('text')+' '+ms.group('phones')))
                wordmatch=True
            
            # if I already made a match and I'm not now, time to break. this allows for finding 
            # alternate pronunciations
            elif wordmatch: 
                # curr_line +=1
                break
               
            # curr_line +=1
        
        # check for words the pronunciation dictionary doesn't have & save
        if not wordmatch:
            missing_words.append(word)

        i +=1
        printProgress (i, l, prefix = 'Progress:', suffix = 'Complete', decimals = 2, barLength = 20)

    # save missing words list to file
    if missing_words:
        missing_words_filename = str(model_name+'/'+model_name+'.missing')
        print("\nWord(s) missing from pronunciation dictionary. See ")
        print(missing_words_filename+" for list.\n")
        mwordsfile = open(missing_words_filename, 'w')
        for word in missing_words:
            mwordsfile.write("%s\n" % word)
                
    # save pronunciation dictionary to file
    print("Saving pronunciation dictionary to file...")
    pdictfilename = str(model_name+'/'+model_name+'.dic')
    pdictfile = open(pdictfilename, 'w')
    for word_entry in pdict:
        pdictfile.write("%s\n" % word_entry)

    # final instructions
    print("Data files created.\n")





def vmc(
    model_name, 
    sentence_file, 
    voice_training_iterations=1, 
    number_of_audio_files=0, 
    pronunciation_dictionary="cmudict_SPHINX_40.txt"):
    """
    [model_name] a clear identifier for the specific recognition model. 

    [sentence_file] the pathname for the input file containing the sentences to train on. 
    
    [voice_training_iterations] integer representing the ratio of voice data collected to total 
    sentences. 0 = no voice data collected (use what you have), 1 = a single recording of each 
    sentence, 2=two recordings of each sentence, &c.
    
    [number_of_audio_files] for when the user is providing a prebuilt set of audio files with an 
    included sentence file, this tells me how many lines from that sentence file I need (sometimes 
    there's more example sentences than audio files.)

    [pronunciation_dictionary] This is the automatic source used to create the custom pronunciation 
    dictionary provided and used by the voice model.  There seems to be a difference in the 
    whitespace used in several dictionaries, preventing the bw program from executing properly.

    """

    # record more voice samples?
    if voice_training_iterations>0:

        # get 'sentences' with all the sample lines. 
        sentences_text = ""
        sentences_list = []
        with open(sentence_file) as f:
            for line in f:
                sentences_text = sentences_text+' '+line
                sentences_list.append(line)

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
                sentence_format_and_save(sentence, model_name, afno)


        except KeyboardInterrupt:
            pass

        sentence_parsing(sentences_text, model_name, sentence_file, pronunciation_dictionary)

    # if an old audio folder was specified, don't record
    elif voice_training_iterations < 0:

        lineno = 0

        # get 'sentences' from old file with all the sample lines.
        # that means this sentence_file is the old_sentence_list_file from the perameter set
        print("Opening old sentence file...\n")
        with open(sentence_file) as f:

            sentences_text = ''

            for line in f:

                lineno = lineno+1

                afno = str('%04d'%lineno) # audio file number w/ 4 digits

                # create string of sentences 
                sentences_text = sentences_text+' '+line

                # in this case, model_name corresponds to the filenames you want to save into
                sentence_format_and_save(line, model_name, afno)

                if lineno == number_of_audio_files:
                    break
        
        print("Parsing sentences...\n")
        sentence_parsing(sentences_text, model_name, sentence_file, pronunciation_dictionary)

        
    elif voice_training_iterations == 0:
        print("Not dealing with audio today.\n")


    else:
        raise TypeError("Something weird happened to the voice_training_iterations variable.")
        

    
# set up input perameters
i = len(sys.argv)

# print("sys.argv length is %s\n" % str(i))

# print("Perameter inputs:")
# for j in sys.argv:
#     print(j)

# if using default iterations value
if i==3:
    model_name = str(sys.argv[1])
    sentence_list_filename = str(sys.argv[2])

    vmc(model_name, sentence_list_filename)

# if specifying iterations value: this is default now (done within shell script)
elif  i==5:
    model_name = str(sys.argv[1])
    sentence_list_filename = str(sys.argv[2])
    pronunciation_dictionary = str(sys.argv[3])
    voice_training_iterations = int(sys.argv[4])
    vmc(model_name, sentence_list_filename,voice_training_iterations, pronunciation_dictionary)

# check if using old audio file
elif i==8 and int(sys.argv[4]) < 0: # not unless both audio perameters specified _and_ 
                                    # iterations specified
    
    print("Using old audio file...\n")

    model_name = str(sys.argv[1])
    sentence_list_filename = str(sys.argv[2])
    pronunciation_dictionary = str(sys.argv[3])
    voice_training_iterations = int(sys.argv[4])
    old_audio_folder = str(sys.argv[5])
    old_sentence_list_file = str(sys.argv[5])+'/'+str(sys.argv[6])
    number_of_audio_files = int(sys.argv[7])

    vmc(model_name, old_sentence_list_file, voice_training_iterations, number_of_audio_files, pronunciation_dictionary)

# error if wrong number of perameters entered
else:
    raise TypeError("Perameters not set correctly!")




