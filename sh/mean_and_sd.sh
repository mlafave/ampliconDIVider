#!/usr/bin/env bash

# Reads from STDIN. Takes a list of numbers, one per line, and returns the mean and population standard deviation.

awk '{ sum += $1; sumsq += ($1)^2 }END{ printf "%.0f %.0f\n", sum/NR, sqrt((sumsq-sum^2/NR)/NR) }'

exit
