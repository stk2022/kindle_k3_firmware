#!/bin/sh

export LD_LIBRARY_PATH=/usr/lib/tts/speech/components/common/:/usr/lib/tts

echo $$ > /var/run/audio.pid

while [ 1 ] ; do
audioServer -I
done

