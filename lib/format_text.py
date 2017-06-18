#!/usr/bin/python3
# 
# DESCRIPTION -----------------------------------------------------------------
# 
#       Creates a number of text files dependent on a sentence file which are 
#       required for building a CMU Sphinx voice model.  Also uses the extended
#       PocketSphinx pronunciation dictionary.
# 
#       Note that the target directory is the directory where the files should 
#       be saved into. This should be similar to the directory the initial 
#       command was given from within.
#
#       The last two options in the usage example are optional. The 'number of 
#       preexisting audio recordings' variable is used for adding to an 
#       existing collection of audio recordings - it controls how the new 
#       .wav files are named (starting from zero, or something higher).  The 
#       last one, 'the fancy sentence list', is only looked for if the other is
#       present.  It is the absolute path of the sentence list that vmc edited
#       the last time it was creating audio files in the given folder.  Instead
#       of starting from scratch, vmc can simply append the new items into that 
#       list.  
#
#       The integration of the new functions should be seamless, though I 
#       anticipate that it will be a royal pain to get it working.
# 
# USAGE | EXAMPLE--------------------------------------------------------------
# 
#       python3 format_text.py /path/to/sentence-file.txt \
#                              model-name \
#                              audio_folder \
#                              iterations \ 
#                              num_of_preexisting_audio_recordings 
# 
# FILES CREATED ---------------------------------------------------------------
#       All are marked for new information to be appended. Therefore, I don't
#       have to provide the old names of any files - just make sure the model
#       names are the same.  Since none of these come with a model name except
#       the .dict file (.dic??), I should be fine with the current 
#       configuration.
#   
#       audio_folder + "/" +model_name + '.transcription'
#       audio_folder + "/" +model_name + '.fileids'
#       
#       audio_folder+'/'+model_name+'.vocab'
#       audio_folder+'/'+model_name+'.dic'       
# 
# IMPORTS =====================================================================

import pathlib, re, sys, os, string

# VARIABLE DEFINITIONS ========================================================

create_pronunciation_dictionary = False # This may not be desirable

sentence_file = sys.argv[1] # os.path.basename() to get just the filename
model_name = sys.argv[2]
audio_folder = sys.argv[3].rstrip(os.sep)
iterations = int(sys.argv[4])
pronunciation_dictionary = '/opt/vmc/lib/cmudict-en-us.dict'
recording_count = int(sys.argv[5]) # how many audio files already exist

if recording_count == 0:
    append_to_existing=False
else:
    append_to_existing=True
   
# LOGIC =======================================================================

# Print iterations progress ---------------------------------------------------
def printProgress (iteration, total, prefix = '', suffix = '', decimals = 1, barLength = 100):

    formatStr       = "{0:." + str(decimals) + "f}"
    percents        = formatStr.format(100 * (iteration / float(total)))
    filledLength    = int(round(barLength * iteration / float(total)))
    bar             = '█' * filledLength + '-' * (barLength - filledLength)
    sys.stdout.write('\r%s |%s| %s%s %s' % (prefix, bar, percents, '%', suffix)),
    if iteration == total:
        sys.stdout.write('\n')
    sys.stdout.flush()

# create files per-audio recording --------------------------------------------

sentences_text = ""; lines = []; 

with open(sentence_file) as f:
    for line in f: lines.append(line)

for line in lines*iterations:

    def append_to_file(formatted_filename, formatted_text):
        hs = open(formatted_filename,"a")
        hs.write(formatted_text)
        hs.close() 

    sentences_text = sentences_text+' '+line
    recording_count+=1
    formatted_audio_file_number = str('%04d'%recording_count)

    # create transcription file -----------------------------------------------
    
    # clean up the text 
    exclude = set(string.punctuation)
    sentence = ''.join(ch for ch in line if ch not in exclude)
    nice_text = sentence.lower().rstrip()

    # format text string and file name with file ids 
    formatted_text = "</s> "+nice_text+" </s> ("+model_name+"_"+formatted_audio_file_number+")\n"
    formatted_filename = audio_folder + "/" +model_name + '.transcription'

    # save into transcription file
    append_to_file(formatted_filename, formatted_text)
    
    #create fileid file -------------------------------------------------------

    # format file id entry and filename
    formatted_text = model_name + "_" + formatted_audio_file_number + "\n"
    formatted_filename = audio_folder + "/" +model_name + '.fileids'

    # save into fileids file
    append_to_file(formatted_filename, formatted_text)

    # ????
    sentences_text = sentences_text+' '+line # why twice? I have no memory of 
                                             # why I did this.  I don't think 
                                             # it does anything, either. TODO:
                                             # remove and see what happens.

# CREATE PRONUNCIATION DICTIONARY ---------------------------------------------

# this is the same for the new file and the old file
uwordsfilename = str(audio_folder+'/'+model_name+'.vocab') # correct extension

# create unique, sorted word list from sentence list
words = []; print("Creating unique, sorted word list...")

# get words from new sentence file
[words.append(word.strip(string.punctuation).upper().rstrip()) for word in sentences_text.split()]

# add the words from the old word list (if this is appending to an old model)
if append_to_existing:
    with open(uwordsfilename) as f:
        for word in f: words.append(word.strip(string.punctuation).upper().rstrip())

# set() uniques the list, sorted() puts them a-z.
uwords = list(filter(None, sorted(list(set(words)))))

# save word list to file
print("Saving word list to file..."); uwordsfile = open(uwordsfilename, 'w')
for word in uwords:
    uwordsfile.write("%s\n" % word)

# create pronunciation dictionary from word list
if create_pronunciation_dictionary:
    cmudict = []; print("Opening pronunciation dictionary...")
    with open(pronunciation_dictionary) as f:
        for line in f:
            cmudict.append(line)

    print("Extracting entries corresponding to word list...")
    pdict = []; missing_words = []; l = len(uwords); i = 0; curr_line = 0
    printProgress (i, l, prefix = 'Progress:', suffix = 'Complete', decimals = 2, barLength = 20) 

    for word in uwords:
        
        wordmatch=False # a counter to help with efficiency
        for line in cmudict[curr_line:]:        
            
            regex_string = str('^(?P<text>'+str(word.lower()) + '(\(\d\))?)( |\t)(?P<phones>.+)$')

            if re.match(regex_string, line):
                # print("match!")
                ms = re.search(regex_string, line)
                pdict.append(str(ms.group('text')+' '+ms.group('phones')))
                wordmatch=True
            
            # if I already made a match and I'm not now, time to break. this allows
            # for finding alternate pronunciations
            elif wordmatch: 
                # curr_line +=1
                break
                
            # curr_line +=1
        
        # check for words the pronunciation dictionary doesn't have & save
        if not wordmatch:
            missing_words.append(word)

        i +=1
        
        printProgress (i, l, prefix = 'Progress:', suffix = 'Complete', decimals = 2, barLength = 20)

    # save pronunciation dictionary to file
    print("Saving pronunciation dictionary to file...")
    pdictfilename = str(audio_folder+'/'+model_name+'.dic')
    pdictfile = open(pdictfilename, 'w')
    for word_entry in pdict:
        pdictfile.write("%s\n" % word_entry)

# RECORD LIST OF MISSING WORDS ------------------------------------------------

    if missing_words:
        missing_words_filename = str(audio_folder+'/'+model_name+'.missing')
        print("\nWord(s) missing from pronunciation dictionary. See ")
        print(missing_words_filename+" for list.")
        mwordsfile = open(missing_words_filename, 'w')
        for word in missing_words:
            mwordsfile.write("%s\n" % word)
            
# DONE ------------------------------------------------------------------------

print("Data files created.")

