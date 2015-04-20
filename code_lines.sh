#!/bin/bash
file_matcher='*.py'
matchers=($@)
#echo ${#matchers[@]},${matchers[@]}, $#, $@
if [ ${#matchers[@]} == 0 ]
then
    echo "not input file type tail, default is py"
    matchers[0]="py"
fi
#echo "type:"${matchers[@]} ${#matchers[@]}
find_fields=''
index=0
if [ ${#matchers[@]} -gt 1 ]
then
#    echo "gt 1"
    for e in ${matchers[@]}
    do
        if [ $index -gt 0 ]
        then
            find_fields=$find_fields" -o -name \"*.$e\""
        else
            find_fields="-name \"*.$e\""
        fi
        ((index++))
    done
else
#    echo "le 1"
    find_fields="-name \"*.${matchers[0]}\""
fi
#echo "ff:$find_fields"
count=0
cmd="find -type f $find_fields"
#echo "cmd=$cmd"
#fs=$(eval $cmd)
#echo "----"$fs
for e in $(eval $cmd)
do 
#echo $e
((count+=`cat $e|grep -v '^\s*$'|wc -l`)) >/dev/null 2>&1
done
echo $count
