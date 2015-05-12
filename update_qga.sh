#/bin/bash

#usage:
#update_qga.sh vm_id_or_name ~/qemu-ga.exe
#

ARGS=("VMS" "FILE")
VM_ID=  #current operate VM ID
#ERROR codes definition
E_FILE_UNREADABLE=2
E_SPLIT_FILE_ERR=3
E_ARG_LEN_ERR=1
E_RESOLVE_QEM_RESP=4
E_NO_PERMISSION=5
E_CAN_NOT_CLEAR_UPDATE=6
E_UPDATE_FILE=7
E_HASH_NOT_EQUAL=8
E_GUEST_UPDATE=9
E_ARG_VM_LIST_NULL=10

#for OUTPUT 
OUTPUT_EXIT_CODES=()
OUTPUT_MSGES=()
OUTPUT_MSG_DESTINATION=/dev/stdout
OUT_BEGIN=0

VIRSH_CMD_PREFIX='virsh qemu-agent-commnd'

#DEST_FILE save to VM(filename)
DEST_FILE="qemu-ga.exe"

get_virsh_command(){
local cmd
cmd="virsh qemu-agent-command $VM_ID ""$1"
echo $cmd
}

#OUTPUT Delimiter
OUTPUT_DELIMITER="||"
ITEM_BEGIN_IDENTIFER="==="

DEBUG=1
if [ $DEBUG == 1 ]
then
    OUT='debug.log'
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
VERSION_OUT=`$VERSION_CMD 2>&1`
LAST_EC=$?
if [ $LAST_EC -ne 0 ]
then
    set_result 22 "for test" false
    set_result $LAST_EC "$VERSION_OUT " true
fi
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
}

check_exit(){
last_ec=$?
last_msg="$1"
if [ $last_ec -ne 0 ]
then
    echo "$last_msg" >$OUTPUT_MSG_DESTINATION
    exit $last_ec
fi
}

_do_push(){
        #OUTPUT_MSG_DESTINATION=$VM_ID".log"
        OLD_VERSION=`get_version`
	check_exit "$OLD_VERSION"
        local out
        out=`clear_update && push_update && valid_hash && guest_update`
        ec=$?
        echo $ec >$OUT
        if [ $ec -ne 0 ]
        then
            echo $out >2
            exit $ec
        fi
        echo 'old_version='$OLD_VERSION &>$OUT
        sleep 0.3
        NEW_VERSION=`get_version`
        echo 'new_version='$NEW_VERSION &>$OUT
        exit $ec
}

pushes(){
    for vm in $VMS
    do
        VM_ID=$vm
        _do_push &>$vm".log" & 
    done
}

summary_results(){
    for vm in $VMS
    do
      #output format : line1 : vm_id , line2 vm.log which every line is a exitcode \t error msg , if empty , this is ok
    #only output the error
        error=`cat "$vm"'.log'`
        if [ -n "$error" ]
            then
            echo "$ITEM_BEGIN_IDENTIFER$vm"
            echo "$error"
        fi
    done
}



set_result(){
# arg3:whether to exit, true to exit , or false not to exit
#arg1: exit code
# arg2: error msg
# arg4: output destination
    echo "$@" >$OUT
    OUTPUT_EXIT_CODES+=( "$1" )
    OUTPUT_MSGES+=( "$2" )
    if [ -n "$4" ]
    then
        OUTPUT_MSG_DESTINATION="$4"
    fi
    if [ "$3" = "true" ]
    then
        out_result
    fi
}

_parse_str(){
    if [ -n "$1" ]
    then
        echo `echo "$1"|tr "\n" "\t"`
    fi     
}

out_result(){
    #: >$OUTPUT_MSG_DESTINATION
    echo "${OUTPUT_EXIT_CODES[@]}" >$OUT
    echo "${OUTPUT_MSGES[@]}" >$OUT
    len=${#OUTPUT_EXIT_CODES}
    blen=$len
    [ $OUT_BEGIN -eq 0 ] &&  cat /dev/null>$OUTPUT_MSG_DESTINATION && ((OUT_BEGIN=1))
    until [ $len -eq 0 ]
    do
         #out_exit_codes+=( ${OUTPUT_EXIT_CODES[len-1]} )
         #out_msges+=( ${OUTPUT_MSGES[len-1]} )
        echo -ne "${OUTPUT_EXIT_CODES[len-1]}$OUTPUT_DELIMITER">>$OUTPUT_MSG_DESTINATION
	echo -E `_parse_str "${OUTPUT_MSGES[len-1]}"` >>$OUTPUT_MSG_DESTINATION
        (( len-- ))
    done
    exit ${OUTPUT_EXIT_CODES[blen-1]}
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
    if [ "${local_hash^^}" != "${dest_hash^^}" ]
    then 
        set_result $E_HASH_NOT_EQUAL \ 
            "hash not equal:expected $local_hash, actually $dest_hash" \
            true 
    fi
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

split_vms(){
    vms=$1
    vms=`echo $vms|tr -d ' '|tr -t ',' "\n"`
	local ret
	ret=()
	for vm in ${vms[@]}
	do
		if [ -n "$vm" ]
		then
			ret+=($vm)
		fi
	done
    echo "${vms[@]}"
}

VMS_CHECK(){
    echo "call check vms" &>$OUT
    VMS=`split_vms "$VMS"`
    echo 'VMS='$VMS &>$OUT
    if [ -z "$VMS" ]
    then
        echo "argument:vm id list is null!$VMS"
        exit $E_ARG_VM_LIST_NULL
    fi
}

valid_args_exist "$@"
valid_permission
initial_args "$@"
check_args
split_file
pushes
wait
summary_results
