#!/bin/bash

#tag.sh <version_number> 
# clone module and tag to remote
#
DEBUG=1
VERSION=
if [ $DEBUG -eq 1 ]
then
    OUT="/dev/stdout"
else
    OUT="/dev/null"
fi

#error codes
E_ARG=1
E_RM_FILE=2


GIT_SERVER="10.12.18.41"
GIT_PORT=10022

MODULES=("ssh://git@$GIT_SERVER:$GIT_PORT/fangcaiqian/ca.git" 
        "ssh://git@$GIT_SERVER:$GIT_PORT/xujunbin/lugia.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/xujunbin/squirtle.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/liangzhichao/sturgeon.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/liangzhichao/sturgeon-client.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/ouyanghui/monitor.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/wuhailing/storage.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/wuhailing/image.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/chenmingyu/observation.git" 
        "ssh://git@$GIT_SERVER:$GIT_PORT/fangcaiqian/fagent.git"
        "ssh://git@$GIT_SERVER:$GIT_PORT/chenchengfa/windows_client.git"
        )

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
if [ -z "$1" ]
then
    echo "lack arg: version number like v1.0.1" >&2
    exit $E_ARG
else
    VERSION=$1
fi

#iterate modules
for module in ${MODULES[@]}
do
    echo $module &>$OUT
    make_tag $module
    
done
}

valid_tag(){
    for e in `git tag`
    do
        [ "$e" == "$VERSION" ] && echo "version $e already existed!" >&2 && exit \
            $E_VERSION_EXIST
    done
}

#to be continue...
make_tag(){
echo "ready to make tag:"$1 &>$OUT
local origin_pwd=$PWD
local dir_name=`resolve_module_dir_name $1`
rm -Rf $dir_name && echo "clear dir $dir_name ok" &>$OUT
if [ $? -ne 0 ]
then
    echo "remove dir failed!" >&2
    exit $E_RM_FILE
fi

git clone $1 && echo "clone repository ok!" &>$OUT
cd $dir_name
echo $PWD &>$OUT
valid_tag
(git tag -a $VERSION -m 'release for version $VERSION' && git push --tags && \
    echo "create tag $dir_name $VERSION ok!") || ( echo "create tag failed:$dir_name" )
cd $origin_pwd
}



make_tags "$@"
