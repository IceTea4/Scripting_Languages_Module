#!/bin/bash

full="./backup/full"
increm="./backup/daily"
restore_root="./restore"
name="backup_failai_kopijos_"

# --------- Pagalbiniai ----------

# Ar data formato YYYYMMDD
is_ymd() {
  [[ ${1:-} =~ ^[0-9]{8}$ ]]
}

# Lyginimas kaip skaičių-eiliškumo, bet YYYYMMDD leidžia tiesioginius string palyginimus
le_date() {  # $1 <= $2 ?
  [[ "$1" == "$2" || "$1" < "$2" ]]
}
lt_date() {  # $1 < $2 ?
  [[ "$1" < "$2" ]]
}
gt_date() {  # $1 > $2 ?
  [[ "$1" > "$2" ]]
}

# Kopijavimas: rsync jei yra, kitaip cp -a
copy_tree() {
  # $1 = src_dir (šaknis su turiniu)
  # $2 = dest_dir (atstatymo tikslas)
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete-delay --ignore-errors -- "$src"/ "$dst"/
  else
    # cp -a nepalaiko --delete; darom paprastą uždėjimą (be trynimų)
    # Užduotyje trynimų nereikalaujama, todėl pakanka uždengti pakeistus/naujus failus
    ( shopt -s dotglob nullglob; cp -a "$src"/* "$dst"/ 2>/dev/null || true )
  fi
}

# Rasti vėliausią pilną kopiją, kurios data <= TARGET
find_full_on_or_before() {
  local target="$1"
  local best_date="" best_dir="" d n p
  shopt -s nullglob
  for p in "$full"/"${name}"????????; do
    [[ -d "$p" ]] || continue
    n=${p##*/}
    d=${n#"$name"}
    [[ $d =~ ^[0-9]{8}$ ]] || continue
    if le_date "$d" "$target"; then
      if [[ -z "$best_date" || "$d" > "$best_date" ]]; then
        best_date="$d"
        best_dir="$p"
      fi
    fi
  done
  echo "$best_dir"
}

# Surinkti prieauglines tarp (start_date; end_date], grąžinti sąrašą pagal didėjimą
collect_incrementals_between() {
  local start="$1" end="$2"
  local p n d; local -a list=()
  shopt -s nullglob
  for p in "$increm"/"${name}"????????; do
    [[ -d "$p" ]] || continue
    n=${p##*/}
    d=${n#"$name"}
    [[ $d =~ ^[0-9]{8}$ ]] || continue
    if gt_date "$d" "$start" && le_date "$d" "$end"; then
      list+=( "$d|$p" )
    fi
  done
  if ((${#list[@]})); then
    printf '%s\n' "${list[@]}" | sort | cut -d'|' -f2
  fi
}

# --------- Pagrindas ----------

if [[ $# -ne 1 ]] || ! is_ymd "$1"; then
  echo "Naudojimas: $0 YYYYMMDD" >&2
  exit 1
fi

target="$1"
mkdir -p -- "$restore_root"
restore_dir="$restore_root/$target"

# 1) Rasti pilną kopiją
full_dir="$(find_full_on_or_before "$target")"
if [[ -z "$full_dir" ]]; then
  echo "KLAIDA: Nerasta jokia pilna kopija su data <= $target." >&2
  echo "Pirma sukurkite pilną kopiją (uzd6.sh full YYYYMMDD)." >&2
  exit 2
fi

# 2) Surinkti prieauglines tarp (pilna; target]
full_date="${full_dir##*/}"
full_date="${full_date#"$name"}"

mapfile -t inc_list < <(collect_incrementals_between "$full_date" "$target" || true)

# 3) Švarus atstatymo katalogas
rm -rf -- "$restore_dir"
mkdir -p -- "$restore_dir"

echo "Atstatymas į: $restore_dir"
echo "Naudojama PILNA: $full_dir"
if ((${#inc_list[@]})); then
  echo "Prieauglinės:"
  for d in "${inc_list[@]}"; do
    echo "  - $d"
  done
else
  echo "Prieauglinių tarp $full_date ir $target nėra (arba nereikia)."
fi

# 4) Pirmiausia pilna kopija
copy_tree "$full_dir" "$restore_dir"

# 5) Tada paeiliui uždedame visas prieauglines
for inc_dir in "${inc_list[@]}"; do
  copy_tree "$inc_dir" "$restore_dir"
done

echo "Baigta. Būsena iki $target atkurta kataloge: $restore_dir"
exit 0
