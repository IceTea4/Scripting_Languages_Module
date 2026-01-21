#!/bin/bash

source="./failai"
data="$1"
#data=$(date +%Y%m%d)
dest="./backup/full/backup_failai_kopijos_${data}"

rm -rf "./backup"
mkdir -p "$dest"

cp -a "$source" "$dest"/
