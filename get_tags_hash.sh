#!/bin/bash
OUT="/dev/null"
if [ -z $1 ]
then
    echo "lack version"
    exit 1
fi
org_dir=$PWD;cdr=$PWD;for e in `find . -maxdepth 1 -type d|grep './'|cut -d '/' -f 2`;do cd $cdr/$e;echo "now at "$PWDi &>$OUT;echo "$e:$1 ("`git show $1|grep commit|cut -d " " -f 2|head -n 1`")";done;cd $org_dir
