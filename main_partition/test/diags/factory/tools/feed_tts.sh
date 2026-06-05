#!/bin/sh


_TTS_TEST_FILE="$1"
_TTS_FIFO="$2"
echo "feed_tts.sh $_TTS_TEST_FILE $_TTS_FIFO"
if [ -f "$_TTS_TEST_FILE" ]; then
    while [ 1 ]; do
        cat "${_TTS_TEST_FILE}" > "${_TTS_FIFO}"
    done
else
    echo "Cannot find $_TTS_TEST_FILE"
fi
