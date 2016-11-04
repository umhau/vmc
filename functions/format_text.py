#!/usr/bin/python3
# 
# DESCRIPTION
# 
#       Creates a number of text files dependent on a sentence file which are required for building
#       a CMU Sphinx voice model.  Also uses the extended PocketSphinx pronunciation dictionary.
# 
#       Note that the target directory is the directory where the files should be saved into. This 
#       should be similar to the directory the initial command was given from within.
# 
# USAGE
# 
#       python3 format_text.py /path/to/sentence-file.txt model-name target-directory iterations
# 
# EXAMPLE
# 
#       python3 /opt/vmc/functions/format_text.py ~/sentence-file.txt model-name target-directory 2
#
# DEPENDENCIES
# 
#       python3
# 
# IMPORTS =========================================================================================

import pathlib, re, sys, os, string

# VARIABLE DEFINITIONS ============================================================================

sentence_file = sys.argv[1] # os.path.basename() to get just the filename

model_name = sys.argv[2]

target_directory = sys.argv[3].rstrip(os.sep)

iterations = int(sys.argv[4])

pronunciation_dictionary = '/opt/vmc/tools/cmudict-en-us.dict'

# FUNCTION DEFINITION =============================================================================

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

# LOGIC ===========================================================================================


# FILEID AND TRANSCRIPTION FILES ------------------------------------------------------------------

sentences_text = ""

j=0
lines = []

with open(sentence_file) as f:

    for line in f:
        lines.append(line)

# this was separated out so I can easily multiply the lines by the iterations...doesn't work to do 
# f*iterations (in above loop).
for line in lines*iterations:

    sentences_text = sentences_text+' '+line

    j+=1
    afno = str('%04d'%j)

    # create transcription file
    exclude = set(string.punctuation)
    sentence = ''.join(ch for ch in line if ch not in exclude)

    nice_text = sentence.lower().rstrip()
    formatted_text = "</s> " +  nice_text +  " </s> (" + model_name + "_" + afno + ")\n"
    formatted_filename = target_directory + "/" +model_name + '.transcription'             
    hs = open(formatted_filename,"a")
    hs.write(formatted_text)
    hs.close() 
    
    #create fileid file
    formatted_text = model_name + "_" + afno + "\n"
    formatted_filename = target_directory + "/" +model_name + '.fileids'
    hs = open(formatted_filename,"a")
    hs.write(formatted_text)
    hs.close() 

    sentences_text = sentences_text+' '+line # why twice? I have no memory of why I did this.

# CREATE PRONUNCIATION DICTIONARY -----------------------------------------------------------------

# create unique, sorted word list from sentence list
words = []
print("Creating unique, sorted word list...")
[words.append(word.strip(string.punctuation).upper()) for word in sentences_text.split()]
# set() uniques the list, sorted() puts them a-z.
uwords = sorted(list(set(words))) 

# save word list to file
print("Saving word list to file...")
uwordsfilename = str(target_directory+'/'+model_name+'.vocab') # correct extension
uwordsfile = open(uwordsfilename, 'w')
for word in uwords:
    uwordsfile.write("%s\n" % word)

# create pronunciation dictionary from word list
cmudict = []
print("Opening pronunciation dictionary...")
with open(pronunciation_dictionary) as f:
    for line in f:
        cmudict.append(line)

pdict = []
missing_words = []
l = len(uwords)
i = 0
print("Extracting entries corresponding to word list...")
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

# save pronunciation dictionary to file
print("Saving pronunciation dictionary to file...")
pdictfilename = str(target_directory+'/'+model_name+'.dic')
pdictfile = open(pdictfilename, 'w')
for word_entry in pdict:
    pdictfile.write("%s\n" % word_entry)

# RECORD LIST OF MISSING WORDS --------------------------------------------------------------------

if missing_words:
    missing_words_filename = str(target_directory+'/'+model_name+'.missing')
    print("\nWord(s) missing from pronunciation dictionary. See ")
    print(missing_words_filename+" for list.")
    mwordsfile = open(missing_words_filename, 'w')
    for word in missing_words:
        mwordsfile.write("%s\n" % word)
            
# DONE --------------------------------------------------------------------------------------------

print("Data files created.")

