#!/bin/bash

##this script is for turn on/off vim configuration for python###
## arguments: on/off, while on is to turn on.
#set exit when code is not 0
#set -e
function switch()
{
if [ $1 == "on" ]
then
    [ -e ~/.vimrc.back ] && mv ~/.vimrc.back ~/.vimrc || [ -e ~/.vimrc ]
    code=$?
    if [ -e ~/.vimrc ]
    then
        echo "turn on vim for python success!"
    else
        echo "turn on vim for python failed, code is:$code"
    fi
elif [ "$1" == "off" ] 
then 
    [ -e ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.back
    code=$?
    if [ ! -e ~/.vimrc ]
    then 
        echo "turn off vim for python success!"
    else
        echo "turn off vim for python failed! code is $code"
    fi
else
    echo "unknown argument:$1!only can be on/off"
fi
}
if [ $# == 0 ]
then
    echo "lack arguments: vim4python.sh on|off"
    exit 1
fi
switch $@
