#!/bin/bash

####clear port watch####
## if not given ports, clear all###

ps -ef|grep portwatch|grep -v grep|awk '{print "kill -9 "$2}'|bash

count=`ps -ef|grep 'portwatch'|grep -v grep|wc -l`
if [ $count -eq 0 ]
then
   echo "clear watch success!"
else
   echo "clear watch failed!Still have $count watch"
fi
