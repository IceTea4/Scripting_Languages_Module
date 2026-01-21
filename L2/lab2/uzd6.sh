#!/bin/bash

source="./failai"
full="./backup/full"
increm="./backup/daily"
name="backup_failai_kopijos_"

copy_one() {
  # $1 = pilnas failo kelias, $2 = root paskirties aplankas, $3 = source šaknis
  local f="$1" dest_root="$2" src_root="$3" rel
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --relative -- "$f" "$dest_root"/
  else
    # relatyvus kelias nuo source šaknies
    rel="${f#"$src_root"/}"
    mkdir -p -- "$dest_root/$(dirname "$rel")" || return 1
    cp -a -- "$f" "$dest_root/$rel"
  fi
}

get_last_backup_dir() {
  local latest="" best=""
  local path n date

  for base in "$full" "$increm"; do
    for path in "$base"/"${name}"????????; do
      [[ -d "$path" ]] || continue
      n=${path##*/}
      date=${n#"${name}"}
      [[ $date =~ ^[0-9]{8}$ ]] || continue
      if [[ -z $latest || $date > $latest ]]; then
        latest="$date"
        best="$path"
      fi
    done
  done

  [[ -n $best ]] && echo "$best" || echo ""
}

get_last_full_date() {
local path n date latest=""

for path in "$full"/"${name}"????????; do
    [[ -d "$path" ]] || continue
    n=${path##*/}
    date=${n#"${name}"}

    [[ $date =~ ^[0-9]{8}$ ]] || continue

    if [[ -z $latest || $date > $latest ]]; then
      latest=$date
    fi
  done

echo "$latest"
}

diff_days() {
local current="$1" last="$2" diff="$3"
local cur_s last_s
cur_s=$(date -d "${current:0:4}-${current:4:2}-${current:6:2}" +%s) || return 1
last_s=$(date -d "${last:0:4}-${last:4:2}-${last:6:2}" +%s) || return 1

local d=$(( (cur_s - last_s) / 86400 ))
((d < 0 )) && d=$(( -d ))

(( d <= diff ))
}

create_full() {
local data="$1"
local dest="${full}/${name}${data}"
mkdir -p "$dest"
cp -a "${source}"/. "$dest"/
echo "Sukurta pilna kopija"
}

create_incremental() {
local data="$1"
local last="$(get_last_full_date)"

if [[ $last == "" ]]; then
echo "Nerasta pilna kopija. Kuriama pilna kopija..."
create_full "$data"
return
fi

if ! diff_days "$data" "$last" 7; then
echo "Paskutine pilna kopija ($last) sena. Kuriama pilna kopija..."
create_full "$data"
return
fi

local last_dir last_date
last_dir="$(get_last_backup_dir)"
[[ -z "$last_dir" ]] && { echo "Nera ankstesnes kopijos"; create_full "$data"; return; }

local last_date="${last_dir##*_}"

local last_date_fmt="${last_date:0:4}-${last_date:4:2}-${last_date:6:2}"
local data_fmt="${data:0:4}-${data:4:2}-${data:6:2}"

local dest="${increm}/${name}${data}"
mkdir -p "$dest"

changed_count=0
failed_copy=0
while IFS= read -r -d '' f; do
  if copy_one "$f" "$dest" "$source"; then
    ((changed_count++))
  else
    failed_copy=1
  fi
done < <(find "$source" -type f -newermt "$last_date_fmt" ! -newermt "$data_fmt +1 day" -print0)

if (( changed_count == 0 )); then
  rm -rf -- "$dest"
  echo "Nera pasikeitusiu failu prieaugline nekuriama."
elif (( failed_copy == 1 )); then
  echo "Dėmesio: dalis failų nebuvo nukopijuota (rsync nera? patikrink teises/keliai). Paskirtis: $dest (sekmingai?: $changed_count)"
else
  echo "Sukurta prieaugline kopija: $dest (failu?: $changed_count)"
fi
}

if [[ $# -lt 2 ]]; then
echo "Naudojimas: $0 <full|increm> <YYYYMMDD>"
exit 1
fi

#Saugiai sukuria kataloa jei jo nera
mkdir -p "$full" "$increm"

case "$1" in
full)
create_full "$2"
;;
increm)
create_incremental "$2"
;;
*)
echo "Nezinomas tipas: '$1' (tinka: full | increm)"
exit 1
;;
esac

exit 0


#------------------------------------------------
#kitas variantas sprendziant lab2 uzduotis

#Randa naujausia bet kokios kopijos data
latest_any_date() {  # usage: latest_any_date ./backup
  local root="${1:?}"
  local f; local latest=""
  shopt -s nullglob
  for f in "$root"/**/.snapshot_*_*; do
    local d="${f##*_.}"
    d="${f##*snapshot_}" ; d="${d#*_}"
    [[ -z "$latest" || "$d" -gt "$latest" ]] && latest="$d"
  done
  echo "$latest"
}

latest_full_date() {  # usage: latest_full_date ./backup/full
  local full_root="${1:?}"
  local f; local latest=""
  shopt -s nullglob
  for f in "$full_root"/.snapshot_full_*; do
    local d="${f##*.snapshot_full_}"
    [[ -z "$latest" || "$d" -gt "$latest" ]] && latest="$d"
  done
  echo "$latest"
}

#(Full kopija): issaugo viska nuo nurodytos datos i ./backup/full
full_backup() {  # usage: full_backup /home/user/failai ./backup 20231006
  local src="${1:?}"; local backup_root="${2:?}"; local ymd="${3:?YYYYMMDD}"
  local dst="${backup_root}/full/backup_failai_${ymd}"
  
  rm -rf "$dst" && mkdir -p "$dst"
  cp -a "$src"/. "$dst"/
}

#(Incremental kopija): tik pasikeite nuo praitos kopijos
# - Jei nera pilnos per savaite vietoj to daro pilna
incremental_backup() {  # usage: incremental_backup /home/user/failai ./backup 20231008
  local src="${1:?}"; local backup_root="${2:?}"; local ymd="${3:?YYYYMMDD}"

  local full_root="${backup_root}/full"
  local daily_root="${backup_root}/daily"
  mkdir -p "$daily_root"

  #Patikrinam pilna
  local last_full; last_full="$(latest_full_date "$full_root" || true)"
  if [[ -z "$last_full" ]]; then
    echo "Nera pilnos kopijos."
    full_backup "$src" "$backup_root" "$ymd"
    return 0
  fi

  #Jeigu pilna senesne nei 7 dienos darom pilna
  local last_full_h; last_full_h="$(date -d "$last_full" +%Y-%m-%d)"
  local limit_h;      limit_h="$(date -d "${ymd} -7 days" +%Y-%m-%d)"
  if [[ "$last_full_h" < "$limit_h" ]]; then
    echo "Pilna per sena (>7 d.)."
    full_backup "$src" "$backup_root" "$ymd"
    return 0
  fi

  #Darom prieaugline lyginant su paskutine kopija
  local last_any; last_any="$(latest_any_date "$backup_root" || true)"
  [[ -z "$last_any" ]] && last_any="$last_full"

  local last_any_h; last_any_h="$(date -d "$last_any" +%Y-%m-%d)"
  local dst="${daily_root}/backup_failai_${ymd}"
  mkdir -p "$dst"

  local src_root="${src%/}"

  changed_count=0
  failed_copy=0

  while IFS= read -r -d '' f; do
    rel="${f#"$src_root/"}"

    if ! mkdir -p -- "$dst/$(dirname -- "$rel")"; then
      failed_copy=1
      continue
    fi

    if cp -p -- "$f" "$dir/$rel"; then
      ((changed_count++))
    else
      failed_copy=1
    fi
  done < <(find "$src" -type f -newermt "$last_any_h" ! -newermt "$(date -d "${ymd} +1 day" +%Y-%m-%d)" -print0)

  if (( changed_count == 0 )); then
    rm -rf "$dst"
    echo "Nera pasikeitusiu failu prieaugline nekuriama."
  elif (( failed_copy == 1 )); then
    echo "Dalies failu nepavyko nukopijuoti. Sekmingai nukopijuota: $changed_count"
  else
    echo "Sukurta prieaugline kopija: Failu kopiju: $changed_count"
  fi
}

#Differential kopija: tik pasikeite nuo paskutines pilnos
differential_backup() {  # usage: differential_backup /home/user/failai ./backup 20231008
  local src="${1:?}"; local backup_root="${2:?}"; local ymd="${3:?YYYYMMDD}"
  local diff_root="${backup_root}/diff"
  mkdir -p "$diff_root"

  local last_full; last_full="$(latest_full_date "${backup_root}/full" || true)"
  if [[ -z "$last_full" ]]; then
    echo "Nera pilnos kopijos."
    full_backup "$src" "$backup_root" "$ymd"
    return 0
  fi

  local since_h; since_h="$(date -d "$last_full" +%Y-%m-%d)"
  local dst="${diff_root}/backup_failai_${ymd}"
  mkdir -p -- "$dst"

  local src_root="${src%/}"

  changed_count=0
  failed_copy=0

  while IFS= read -r -d '' f; do
    rel="${f#"$src_root/"}"

    if ! mkdir -p -- "$dst/$(dirname -- "$rel")"; then
      failed_copy=1
      continue
    fi

    if cp -p -- "$f" "$dst/$rel"; then
      ((changed_count++))
    else
      failed_copy=1
    fi
  done < <(find "$src_root" -type f -newermt "$since_h" ! -newermt "$(date -d "${ymd} +1 day" +%Y-%m-%d)" -print0)

  if (( changed_count == 0 )); then
    rm -rf -- "$dst"
    echo "Nera pasikeitimu skirtumine nekuriama."
  elif (( failed_copy == 1 )); then
    echo "Dalies failu nepavyko nukopijuoti. Sekmingai nukopijuota: $changed_count"
  else
    echo "Skirtumine kopija sukurta."
  fi
}

#Atstatymo pavyzdys iki nurodytos datos
restore_to_date() {  # usage: restore_to_date ./backup /tmp/restore_here 20231004
  local backup_root="${1:?}"; local restore_dir="${2:?}"; local ymd="${3:?YYYYMMDD}"
  mkdir -p -- "$restore_dir"

  local full_root="${backup_root}/full"
  local daily_root="${backup_root}/daily"

  #Rasti paskutine pilna kopija
  local last_full; last_full="$(latest_full_date "$full_root" || true)"

  local best_full_dir=""
  if [[ -n "$last_full" && "$last_full" -le "$ymd" ]]; then
    best_full_dir="${full_root}/backup_failai_${last_full}"
  else
    local d dir
    for dir in "$full_root"/backup_failai_*; do
      d="${dir##*_}"
      [[ "$d" -le "$ymd" ]] || continue
      [[ -z "$best_full_dir" || "$d" -gt "${best_full_dir##*_}" ]] && best_full_dir="$dir"
    done
  fi

  if [[ -z "$best_full_dir" ]]; then
    echo "Nerasta pilna kopija iki ${ymd}."
    return 1
  fi

  #Atkuriama pilna kopija
  cp -a -- "$best_full_dir"/ "$restore_dir"/

  #Pridedam inkrementines kopijas
  local base_full_date="${best_full_dir##*_}"

  if [[ -d "$daily_root" ]]; then
    local inc_dir inc_date
    for inc_dir in "$daily_root"/backup_failai_*; do
      inc_date="${inc_dir##*_}"
      [[ "$inc_date" -le "$ymd" && "$inc_date" -gt "$base_full_date" ]] || continue
      cp -a -- "$inc_dir"/ "$restore_dir"/
    done
  fi
}

# Sunaikinti ARBA suarchyvuoti kopijas senesnes nei 7 d.
cleanup_or_archive_week_old() {  # usage: cleanup_or_archive_week_old ./backup daily 20231015 archive
  local backup_root="${1:?}"; local kind="${2:?full|daily|diff}"; local ymd="${3:?}"; local action="${4:?delete|archive}"
  local dir="${backup_root}/${kind}"
  [[ -d "$dir" ]] || { echo "Nera $dir"; return 0; }

  #7 dienu riba
  local cutoff; cutoff="$(date -d "${ymd} -7 days" +%Y-%m-%d)"

  if [[ "$action" == "delete" ]]; then
    for old in $(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' ! -newermt "$cutoff"); do
      rm -rf -- "$old"
    done
  else
    #suarchyvuojam i tar.gz ir istrinam saltini
    while IFS= read -r -d '' d; do
      local base; base="$(basename "$d")"
      tar -czf "${d}.tar.gz" -C "$dir" "$base"
      rm -rf "$d"
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -not -newermt "$cutoff" -print0)
  fi
}

