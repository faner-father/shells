#!/bin/bash

VERSION=

if [ -z $1 ]
then
    echo "lack arguments:version"
else
    VERSION=$1
fi

MODULES=("ca" "lugia" "observation" "squirtle" "sturgeon" 
        "sturgeon-client" "storage" "image" "monitor" 
        "fagent" "windows_client")
ORIGIN_DIR=$PWD
for m in ${MODULES[@]}
do
    cd $m
    git tag -d $VERSION && git push origin --delete tag $VERSION && echo \
    "remove $m $VERSION ok!"
    cd $ORIGIN_DIR
done
