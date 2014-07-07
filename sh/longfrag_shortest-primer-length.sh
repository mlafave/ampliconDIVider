#!/usr/bin/env bash

LONGFRAGPRIMERS=$1

source ~/.bashrc

# Capture the length of the shortest primer used in long fragments

awk 'BEGIN{ n = 99999999999 }{if (length($2) <= length($3) && length($2) < n){n=length($2)} else if (length($3) <= length($2) && length($3) < n){n=length($3)}}END{print n}' ${LONGFRAGPRIMERS}

exit
