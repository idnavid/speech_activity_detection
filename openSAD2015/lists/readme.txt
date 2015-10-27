
### The lists in lists/for_rats are no longer used ###

The original lists in ../rats_sad had some discrepencies with the annotations
available in /scratch2/share/sosXXX/rats_sad 
The lists you see in lists/for_rats only contain the *.flac files for which annotations
were available. 

######################################################




# New lists:

dev_*.txt contain 159 randomly selected source identities. This number was chosen 
such that the dev-to-train ratio matches that of RATS experiments. Assuming
that the people that created those lists had some rational for their choice of
data. (160/800 = 3570)
Language distribution: 61 alv, 73 eng, and 25 urd. 
The language distribution matches that of the original dataset (409/491/170 respectively).
These lists refer to the sad annotation files (dev/train_sad.txt) and the flac files
(train/dev_audio.txt). 
According to the dataset documentation, all the "corrupted" files originate
from here. What you need to pay attention to is the 5 digit id at the beginning of the filename. 

