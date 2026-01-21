#!/bin/bash

# Vietos (kaip uzd6.sh)
full="./backup/full"
increm="./backup/daily"
name="backup_failai_kopijos_"

archive_root="./archive"

# --------- Pagalbinės ---------

# parenka GNU date; macOS naudotojams tiks gdate (brew install coreutils)
DATE_CMD="date"

is_ymd() { [[ ${1:-} =~ ^[0-9]{8}$ ]]; }

# grąžina YYYYMMDD - N dienų
ymd_minus_days() {
  local ymd="$1" days="$2"
  "$DATE_CMD" -d "${ymd:0:4}-${ymd:4:2}-${ymd:6:2} - ${days} day" +%Y%m%d
}

# palyginimai (YYYYMMDD tinka leksikografiškai)
lt_date() { [[ "$1" < "$2" ]]; }
le_date() { [[ "$1" == "$2" || "$1" < "$2" ]]; }

# surenka taikinių direktorijas pagal tipą ir cutoff
collect_targets() {
  # $1 = "full" | "increm" | "all"
  # $2 = cutoff_ymd (<= šios datos bus taikiniai)
  local which="$1" cutoff="$2"
  local base p n d

  if [[ "$which" == "full" || "$which" == "all" ]]; then
    base="$full"
    for p in "$base"/"${name}"????????; do
      [[ -d "$p" ]] || continue
      n=${p##*/}; d=${n#"$name"}
      [[ $d =~ ^[0-9]{8}$ ]] || continue
      if le_date "$d" "$cutoff"; then
        printf "full|%s|%s\n" "$d" "$p"
      fi
    done
  fi

  if [[ "$which" == "increm" || "$which" == "all" ]]; then
    base="$increm"
    for p in "$base"/"${name}"????????; do
      [[ -d "$p" ]] || continue
      n=${p##*/}; d=${n#"$name"}
      [[ $d =~ ^[0-9]{8}$ ]] || continue
      if le_date "$d" "$cutoff"; then
        printf "increm|%s|%s\n" "$d" "$p"
      fi
    done
  fi
}

archive_one() {
  # $1 = type(full|increm)  $2 = dir_path
  local t="$1" src="$2" sub outdir out
  if [[ "$t" == "full" ]]; then sub="full"; else sub="daily"; fi
  outdir="$archive_root/$sub"
  mkdir -p -- "$outdir"
  local base="${src##*/}"
  out="$outdir/${base}.tar.gz"
  tar -czf "$out" -C "$(dirname "$src")" "$base"
  rm -rf -- "$src"
  echo "ARCHIVE: $src -> $out"
}

delete_one() {
  local src="$1"
  rm -rf -- "$src"
  echo "DELETE:  $src"
}

usage() {
  cat <<EOF
Naudojimas:
  $0 <archive|delete> <full|increm|all> <YYYYMMDD>

Veiksmas:
  archive  - suarchyvuoti į ./archive/… (po to ištrinti originalą)
  delete   - sunaikinti

Tipas:
  full     - tik pilnos kopijos
  increm   - tik prieauglinės kopijos
  all      - abi rūšys

Data:
  Palyginimui naudojama "senesnės nei 7 dienos nuo DUOTOS datos".
  T.y. taikiniai: datos <= (YYYYMMDD - 7 dienų)
EOF
}

# --------- Argumentai ---------

if [[ $# -ne 3 ]]; then usage; exit 1; fi
action="$1"    # archive|delete
which="$2"     # full|increm|all
ref="$3"       # YYYYMMDD

case "$action" in
  archive|delete) ;;
  *) echo "Klaida: action turi būti archive|delete"; usage; exit 1 ;;
esac
case "$which" in
  full|increm|all) ;;
  *) echo "Klaida: type turi būti full|increm|all"; usage; exit 1 ;;
esac
if ! is_ymd "$ref"; then
  echo "Klaida: data turi būti YYYYMMDD"; usage; exit 1
fi

# --------- Skaičiuojam cutoff ---------
cutoff="$(ymd_minus_days "$ref" 7)"

echo "Veiksmas: $action"
echo "Tipas:    $which"
echo "Duota data: $ref  →  cutoff (<=): $cutoff"
echo

# --------- Surenkam taikinius ---------
mapfile -t targets < <(collect_targets "$which" "$cutoff" | sort)

if ((${#targets[@]}==0)); then
  echo "Nieko nerasta pagal sąlygą (<= $cutoff). Baigta."
  exit 0
fi

# --------- Vykdom ---------
count=0
for line in "${targets[@]}"; do
  IFS='|' read -r t d p <<<"$line"
  if [[ "$action" == "archive" ]]; then
    archive_one "$t" "$p"
  else
    delete_one "$p"
  fi
  ((count++))
done

echo
echo "OK: apdorota objektų: $count"
exit 0
