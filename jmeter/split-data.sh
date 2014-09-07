#!/bin/bash
# There are 2386497 lines in the original file
head -n 200000 sorted100M.1s.hsum.csv > prep-data.csv
tail -n 2186497 sorted100M.1s.hsum.csv > gc-house-data.csv

