#!/bin/bash

function isPortListening(){
   if [ $# -eq 1 ]
   then 
      local find_port
      if which lsof>/dev/null 2>&1
      then
          find_port="lsof -i:$1"
      elif which netstat>/dev/null 2>&1
      then
         find_port="netstat -an|grep $1|grep -i listen"
      fi
      #echo "cmd is " "$find_port"
      eval $find_port >/dev/null 2>&1
      return $?
    fi
}
watch(){
while true
do
isPortListening $1
code=$?
echo $code
if [ $code -ne 0 ]
then
   echo "not exists: $2"
   ($2 >nohup.out 2>&1 &)
else
  echo "port is listening, do nothing"
fi
sleep 1
done
}
echo $#
if [ $# -ne 2 ]
then 
   echo "lack args! Usage: portwatch.sh <port> <command>"
   exit 1
else
   watch "$@"
fi
