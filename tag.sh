#!/bin/bash

#tag.sh <version_number> 
# clone module and tag to remote
#
DEBUG=1

if [ DEBUG -eq 1 ]
then
    OUT="/dev/stdout"
else
    OUT="/dev/null"
fi

#error codes
E_ARG=1

GIT_SERVER="10.12.18.41"
GIT_PORT=10022

MODULES=("ssh://git@$GIT_SERVER:$GIT_PORT/fangcaiqian/ca.git" )

resolve_module_dir_name(){
if [ -z $1 ]
then
    echo "lack arg:module url like ssh://git@10.12.18.41:10022/fangcaiqian/ca.git" >&2
    exit $E_ARG
fi    

echo "$1" |tr -s "/"|cut -d '/' -f 4|cut -d '.' -f 1
}

clone(){
echo
}

make_tags(){
set -- "$@"
echo $1 $@
if [ -z "$1" ]
then
    echo "lack arg: version number like v1.0.1" >&2
    exit $E_ARG
fi

#iterate modules
for module in $MODULES
do
    echo $module &>$OUT
    make_tag $module
    
done
}


#to be continue...
make_tag(){
echo "ready to make tag:"$1 &>$OUT
dir_name=`resolve_module_dir_name $1`
(rm -Rf $dir_name && echo "clear dir $dir_name ok" &>$OUT) || ( echo "" && )

echo ""
}



make_tags "$@"
