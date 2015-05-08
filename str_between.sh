#!/bin/bash

#find the string betweed begin and end string in string
# such as find string between [ and ] in  [1] , which is 1

#args: first is the target string , second is begin , and the third is end
#such as : str_between.sh a1b a b

str="$1"
begin="$2"
end="$3"

#echo "="$str
#echo "="$begin
#echo "="$end

bindex=`expr index "$str" "$begin"`
eindex=`expr index "$str" "$end"`
len=$((eindex-bindex-1))
#echo $bindex $eindex $len
echo ${str:bindex:len}
