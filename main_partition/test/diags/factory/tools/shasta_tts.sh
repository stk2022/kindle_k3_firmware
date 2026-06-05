#!/bin/sh

_TTS_TEST_FILE="$1"
_TTS_FIFO="$2"
echo "shasta_tts.sh $_TTS_TEST_FILE $_TTS_FIFO"
if [ -f "$_TTS_TEST_FILE" ]; then
    while [ 1 ]; do
        lipc-wait-event com.lab126.tts ttsDataLow
        cat "${_TTS_TEST_FILE}" > "${_TTS_FIFO}"
        lipc-set-prop com.lab126.audio Control 1
    done
else
    echo "Cannot find $_TTS_TEST_FILE"
fi
