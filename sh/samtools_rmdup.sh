#!/usr/bin/env bash

INBAM=$1
OUTBAM=$2

source ~/.bashrc

samtools rmdup ${INBAM} ${OUTBAM} 

exit
