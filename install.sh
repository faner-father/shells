#!/bin/bash

function install(){
echo "check or install $@"
arr=($@)
total=$#
not_installed_count=0
installed_count=0
install_succ_count=0
not_install_list=()
install_fail_list=()
for e in ${arr[@]}
do 
    echo "begin to check $e"
	dpkg -l|grep $e>/dev/null
    if [ $? != 0 ] 
    then 
        ((not_installed_count+=1))
        not_installed_list+=($e)
        echo 'not found '$e
        echo 'begin install '$e
        cmd="sudo apt-get install $e"
        echo $cmd
        ${cmd}
        if [ $? == 0 ]
        then 
            echo "install $e ok" 
            install_succ_count=`expr $install_succ_count + 1`
        else 
            echo "install failed"
            install_fail_list+=($e)
        fi
    #else
     #   echo "installed:$e"
    fi
done
}

install $@
echo "result:"
echo -n "total:$total, installed:"`expr $total - $not_installed_count`
echo ", not_installed_count:$not_installed_count"
echo "not_installed_list:"${not_installed_list[@]}
echo -n "install success count:$install_succ_count, "
echo "install failed count:"`expr $not_installed_count - $install_succ_count`
