#!/bin/sh
dd if=/dev/mem bs=4096 skip=557055 count=1 | xd
