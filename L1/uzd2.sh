#!/bin/bash

source funkcijos.lib

username=$1
shift

priesagos=("html" "htm" "php")

if [ $# -gt 0 ]; then
priesagos+=("$@")
fi

ssh "$username@158.129.0.29" 'bash -s' -- "$username" "${priesagos[@]}" <<EOF
$(declare -f failu_sarasas)
$(declare -f failu_dydziai)
$(declare -f suma)

username=\$1
shift
priesagos=("\$@")

failu_sarasas \$username \${priesagos[@]}

failu_dydziai \$username \${priesagos[@]}

suma \${sizes[@]}

echo "Uzimama vieta diske: \$sum" | tee -a "\$HOME/rez"
EOF
