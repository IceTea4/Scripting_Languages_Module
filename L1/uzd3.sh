#!/bin/bash

gen_pass() { #slaptažodžius generuojanti funkcija
[ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
 cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32}
 echo
}

list=()

while IFS= read -r line; do
fullName=`echo $line | awk -F';' '{print $2}'`
name=`echo $fullName | awk '{print $1}'`;
surname=`echo $fullName | awk '{print $2}'`;
login=${name:0:4}${surname:0:4}
pwd=$(gen_pass 10)
list+=("$login $pwd")
done < $1

for i in "${list[@]}"; do
echo $i
done
