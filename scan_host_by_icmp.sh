#!/bin/bash
#arguments: network, like 192.168.1 
#this shell will scan network+(1~254)


when_trap(){
echo "exit when ctrl c" 
echo ${reachable_hosts[@]}
exit 1
}

trap 'when_trap' 2

reachable_hosts=()

for host in `seq 1 254`
do
    host=192.168.1.$host
    ping -w 1.5 $host &>/dev/null
    if [ $? -eq 0 ]
    then
        reachable_hosts+=("$host")
    fi
done

echo "finished:"
echo ${reachable_hosts[@]}
