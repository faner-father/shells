#/bin/bash

ARGS=("VM_ID" "FILE")

E_FILE_UNREADABLE=2
E_SPLIT_FILE_ERR=3
E_ARG_LEN_ERR=1
E_RESOLVE_QEM_RESP=4
E_NO_PERMISSION=5
E_CAN_NOT_CLEAR_UPDATE=6
E_UPDATE_FILE=7
E_HASH_NOT_EQUAL=8
E_GUEST_UPDATE=9
VIRSH_CMD_PREFIX='virsh qemu-agent-commnd'

DEST_FILE="qemu-ga.exe"

get_virsh_command(){
local cmd
cmd="virsh qemu-agent-command $VM_ID ""$1"
echo $cmd
}

DEBUG=0
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
split -b 51200 -d "$FILE" "$FILE" && echo "split file ok!" &>$OUT || exit $E_SPLIT_FILE_ERR
}

json_get(){
python -c "import sys, json;fun = eval(''.join(['lambda obj:', sys.argv[2]]));print fun(json.loads(sys.argv[1]));" "$1" ${2:-"obj['return']"}
if [ $? != 0 ]
then
    return $E_RESOLVE_QEM_RESP
fi
}

get_version(){
VERSION_CMD=`get_virsh_command '{"execute":"guest-version"}'` #'sudo virsh qemu-agent-command '"$VM_ID "'{"execute":"guest-version"}'
echo "VCMD="$VERSION_CMD &>$OUT
VERSION_OUT=`$VERSION_CMD`
echo $VERSION_OUT &>$OUT
json_get $VERSION_OUT
}

clear_update(){
echo "clear update ..." &>$OUT
cu_cmd=`get_virsh_command '{"execute":"guest-clear-update"}'`
echo $cu_cmd &>$OUT
out=`$cu_cmd` #$($cu_cmd)
echo $out &>$OUT
if [ $? != 0 ]
then
    echo "can not clear update :$out" >2
    exit $E_CAN_NOT_CLEAR_UPDATE
fi
}

valid_permission(){
if [ $EUID != 0 ]
then
    echo "no permission!please use sudo to run script"
    exit $E_NO_PERMISSION
fi
}

push_update_one_file(){
echo "push update one file $1 ..." &>$OUT
echo "$@" &>$OUT
local content
local puo_cmd
content=`base64 -w 0 $1`
#echo $content &>$OUT
puo_cmd=`get_virsh_command '{"execute":"guest-push-update", "arguments":{"file":"'"$DEST_FILE"'", "content":"'"$content"'"}}'`
out=`$puo_cmd`
ret=$?
echo $out &>$OUT
return $ret 
}

push_update(){
echo "push update..." &>$OUT
echo $FILE"?*" &>$OUT
for f in "$FILE"?*
do
    push_update_one_file $f
    ret=$?
    echo "ret=$ret" &>$OUT
    if [ $ret != 0 ]
    then
        echo "update file $f failed!"
        exit $E_UPDATE_FILE
    fi
done
#pu_cmd=`get_virsh_command `
}

valid_hash(){
local cmd
local dest_hash
cmd=`get_virsh_command '{"execute":"guest-update-file-md5", "arguments":{"file":"'"$DEST_FILE\"}}"`
dest_hash=`$cmd`
echo $dest_hash &>$OUT
dest_hash=`json_get "$dest_hash" "obj['return']"`
echo "dest_hash="$dest_hash &>$OUT
local_hash=`md5sum $FILE | awk '{print $1}'`
[ ! "${local_hash^^}" == "${dest_hash^^}" ] && echo "hash not equal:expected $local_hash , actually $dest_hash" >&2 && exit $E_HASH_NOT_EQUAL
}

guest_update(){
local cmd
local out
cmd=`get_virsh_command '{"execute":"guest-update"}'`
out=`$cmd`
if [ $? -ne 0 ]
then
    echo "guest_update failed" >&2
    exit $E_GUEST_UPDATE
fi
}

valid_args_exist $@
valid_permission
initial_args $@
check_args
split_file
OLD_VERSION=`get_version`

clear_update
push_update
valid_hash
guest_update
echo 'old_version='$OLD_VERSION &>$OUT
sleep 1
NEW_VERSION=`get_version`
echo 'new_version='$NEW_VERSION &>$OUT
