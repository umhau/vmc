
Voice model creator for CMU Sphinx
===============================================================================

This tool contains basic tools for creating a custom domain voice model for use
with the PocketSphinx decoder.  It is also possible to use the voice models 
created by this tool as the basis for a test-to-speech engine.  

Note this tool has only been tested with Linux Mint 17.3 & 18.

**Please see the LICENSE file for terms of use.**

Linux/Unix installation
-------------------------------------------------------------------------------

You should install dependencies first; this ensures that python-dev, 
PocketSphinx, etc. are available.  Second, install vmc.  Some of the packages 
need to be installed within the user's home directory; ~/tools is recommended.  
This should be specified when installing the dependencies. Full installation on 
an AMD64 computer running Mint 18 would look like this:

Commands:

    $ cd ~/Downloads
    $ git clone https://github.com/umhau/vmc.git
    $ cd ./vmc
    $ sudo bash ./installdependencies.sh ~/tools
    $ sudo bash ./installvmc.sh

See use examples in the next section.

Usage instructions
-------------------------------------------------------------------------------

Example usage, recording new audio with 5 repetitions of each sentence:

    $ vmc.sh new_model -record ~/Downloads/sentences.txt ~/projects/new_model 5

Example usage, importing previously created audio files:

    $ vmc.sh ccmodel -import audio_files cc.list ~/tools/ccmodel

Note that the model name and the name of the model folder should be the same. 
Also note the repetitions specification is optional; it defaults to 1.

The model folder will contain all necessary files to run PocketSphinx with the 
newly created custom voice model.

Note that dependencies are not checked when running vmc.sh.  To check 
dependencies, see the section above. 

Background
-------------------------------------------------------------------------------

This tools brings together a number of disparate data files that are needed for 
creating a voice model.  This graph illustrates the data process involved:

                   word domain
                        +
                        |
                        v
        +-------+ sentence list+----------+
        |               +                 |
        |               |                 |
        v               v                 v
    dictionary      grammar: LM    voice samples
        +               +                 +
        |               |                 |
        |               v                 |
        +--------> voice model <----------+
                    training
                        +
                        |
                        v
                   voice model

Each of these steps, starting with the sentence list (given) and ending with 
the voice model are contained within this tool.

