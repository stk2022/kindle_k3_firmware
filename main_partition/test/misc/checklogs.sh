#!/bin/sh
if [ "x$1" != "x" ]; then
showlog | tail -n $1 | sed '/^[0-9]*:[0-9]* [a-zA-Z_-]*\[*[0-9]*\]*: [D|I|W|E|C] .*:/d'
else
showlog | sed '/^[0-9]*:[0-9]* [a-zA-Z_-]*\[*[0-9]*\]*: [D|I|W|E|C] .*:/d'
fi

