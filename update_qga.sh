#/bin/bash

ARGS=("VM_ID" "FILE")

E_FILE_UNREADABLE=2
E_SPLIT_FILE_ERR=3
E_ARG_LEN_ERR=1

DEBUG=1
if [ $DEBUG == 1 ]
then
OUT='/dev/stdin'
else
OUT='/dev/null'
fi

FILE_CHECK(){
    if [ -r $FILE -a -s $FILE ]
    then
        echo "" &>$OUT
    else
        echo "$FILE can not be read or is empty file!"
        exit $E_FILE_UNREADABLE
    fi
}


valid_args_exist(){
if [ $# != ${#ARGS[@]} ]
then
    echo "arguments length is not ${#ARGS[@]}" &>$OUT
    exit $E_ARG_LEN_ERR
fi
}

initial_args(){
index=1
for arg_name in ${ARGS[@]}
do
    cmd=$arg_name=\$$index
    echo $cmd &>$OUT
    eval $cmd
    ((index++))
    eval "echo $arg_name = \$$arg_name" &>$OUT
done
}

check_args(){
for arg in ${ARGS[@]}
do
    type "$arg""_CHECK" &>$OUT
    ok=$?
    if [ $ok == 0 ]
    then
        echo "$arg""_CHECK EXIST :$ret" &>$OUT
        eval "$arg""_CHECK"
    fi
done
}

split_file(){
#clear files with prefix
rm -f "$FILE"'?*'
split -b 102400 -d "$FILE" "$FILE" && echo "split file ok!" &>$OUT || exit $E_SPLIT_FILE_ERR
}



valid_args_exist $@
initial_args $@
check_args
split_file
VERSION_CMD='sudo virsh qemu-agent-command '"$VM_ID "'{"execute":"guest-version"}'
echo "VCMD="$VERSION_CMD &>$OUT
VERSION=`$VERSION_CMD`
echo $VERSION &>$OUT
