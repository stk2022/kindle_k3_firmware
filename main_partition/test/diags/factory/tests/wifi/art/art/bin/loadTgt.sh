#!/bin/sh

export ART_WORKAREA=`pwd`
export ATH_PLATFORM=SHASTA_NATIVEMMC-SDIO
export EEPROM=${EEPROM:-${ART_WORKAREA}/lab126_15dBm_nodiv_WWR_CTL.bin}

$ART_WORKAREA/host/support/loadART.sh 

