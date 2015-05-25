#!/bin/bash

out=`git log` 
#echo "$out"
line=`echo "$out"|grep -n '^commit'|awk 'NR==2{print $1}'|cut -f 1 -d ':'` 
echo $line $((line - 1))
echo "$out" |head -$((line - 1))
