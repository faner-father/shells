#!/bin/bash

out=`git log` ; line=`echo "$out"|grep -n 'commit'|awk 'NR==2{print $1}'|cut -f 1 -d ':'` ; echo "$out" |head -$((line - 1))
