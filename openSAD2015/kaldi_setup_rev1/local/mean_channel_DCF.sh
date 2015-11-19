#! /bin/bash


for channel in B D E F G H; do
    echo "channel $channel: ";
    if [[ $channel == "H" ]];then
        cat exp/scores/*_${channel}.* | grep DCF | cut -d ' ' -f 15 | perl -ne 'if(m/(\S+)/){$num=$num+1;if($num%5 eq 0){$sum=$sum+$1;printf("\t\t%.3f",$sum/16.0);print "\n"}}' | tail -n 1;
    else
        cat exp/scores/*_${channel}.* | grep DCF | cut -d ' ' -f 15 | perl -ne 'if(m/(\S+)/){$num=$num+1;if($num%5 eq 0){$sum=$sum+$1;printf("\t\t%.3f",$sum/30.0);print "\n"}}' | tail -n 1;
    fi;
done;
