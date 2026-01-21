#!/bin/bash

username=$1
shift

priesagos=("html" "htm" "php")

if [ $# -gt 0 ]; then
priesagos+=("$@")
fi

ssh "$username@158.129.0.29" 'bash -s' -- "${priesagos[@]}" << 'EOF'

list_and_sum() {
sum=0

priesagos=("$@")

for i in ${!priesagos[*]}; do
for j in `ls -l /*.${priesagos[$i]} 2> klaidos.txt | awk '{print $9}'`; do
echo $j
size=$(ls -l "$j" 2>> klaidos.txt | awk '{print $5}')
sum=$((sum + size))
done
done
echo "Uzimama vieta diske: $sum"
}

list_and_sum "$@"
EOF
