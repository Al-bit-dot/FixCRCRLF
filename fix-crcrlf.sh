#!/usr/bin/env bash
# Repairs email text files whose lines end CR CR LF instead of the Windows CR LF.
#
#   bash fix-crcrlf.sh [--dry-run] [START_FOLDER]      (default: the current folder)
#
# Looks in START_FOLDER and every folder below it for regular files named
# email20*.txt that were last modified on FIX_DATE (this computer's local time).
# In each one, every line ending in two or more CRs before the LF is changed to
# end in a single CR LF; nothing else in the file changes, and the file keeps its
# modification time and permissions. Files with no such line (already CR LF, or
# Linux LF) are not touched.
#
# A log, fix-crcrlf-log-YYYYMMDD-HHMMSS.csv, is saved in START_FOLDER with one
# "filename","folder" row per corrected file, followed by the totals.
# --dry-run changes nothing and lists the files that would be corrected in
# fix-crcrlf-dry-run-YYYYMMDD-HHMMSS.csv instead.
set -uo pipefail

FIX_DATE=2026-06-27   # YYYY-MM-DD

dry_run=0
start=""
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then dry_run=1
  elif [ -z "$start" ]; then start="$arg"
  else echo "Usage: bash fix-crcrlf.sh [--dry-run] [START_FOLDER]" >&2; exit 2
  fi
done
start="${start:-.}"
if [ ! -d "$start" ]; then
  echo "Not a folder: $start" >&2
  exit 2
fi
start="$(cd "$start" && pwd)"
if [ "$dry_run" -eq 1 ]; then kind=dry-run; else kind=log; fi
log="$start/fix-crcrlf-$kind-$(date +%Y%m%d-%H%M%S).csv"

CR=$'\r'
fix="s/$CR$CR$CR*\n/$CR\n/g"   # for sed -z: two or more CRs then LF -> CR LF
tmp=""
trap 'rm -f "$tmp"' EXIT
trap 'exit 130' INT TERM

csv() {  # csv TEXT: TEXT as one quoted CSV field
  printf '"%s"' "${1//\"/\"\"}"
}

removed=0
fix_file() {  # fix_file PATH: correct PATH in place; sets removed to the number of CRs taken out
  local f="$1" before after
  before=$(wc -c < "$f") || return 1
  after=$(LC_ALL=C sed -z "$fix" "$f" | wc -c) || return 1
  removed=$((before - after))
  if [ "$removed" -le 0 ] || [ "$dry_run" -eq 1 ]; then return 0; fi
  # Write the corrected copy beside the original, give it the original's
  # permissions, owner and times, then swap it in.
  tmp="$(mktemp "${f%/*}/.fix-crcrlf.XXXXXX")" || return 1
  LC_ALL=C sed -z "$fix" "$f" > "$tmp" || return 1
  chmod --reference="$f" "$tmp" 2>/dev/null
  chown --reference="$f" "$tmp" 2>/dev/null
  touch -r "$f" "$tmp" && mv -f "$tmp" "$f" || return 1
  tmp=""
}

# Collect the matching files first; find prints each one's local modification date.
files=()
while IFS= read -r -d '' rec; do
  if [ "${rec:0:10}" = "$FIX_DATE" ]; then files+=("${rec:11}"); fi
done < <(find "$start" -type f -name 'email20*.txt' -printf '%TY-%Tm-%Td %p\0' | LC_ALL=C sort -z)

if [ "$dry_run" -eq 1 ]; then verb="would be corrected"; else verb="corrected"; fi
fixed=0
failed=0
{ csv Filename; printf ,; csv Directory; echo; } > "$log" || exit 1
for f in "${files[@]+"${files[@]}"}"; do
  if ! fix_file "$f"; then
    rm -f "$tmp"; tmp=""
    echo "Could not correct: $f" >&2
    failed=$((failed + 1))
  elif [ "$removed" -gt 0 ]; then
    fixed=$((fixed + 1))
    echo "$verb: $f ($removed extra CRs)"
    { csv "${f##*/}"; printf ,; csv "${f%/*}"; echo; } >> "$log"
  fi
done
{
  echo "Files examined (email20*.txt dated $FIX_DATE),${#files[@]}"
  if [ "$failed" -gt 0 ]; then echo "Files that could not be corrected,$failed"; fi
  if [ "$dry_run" -eq 1 ]; then
    echo "Total files that would be processed (dry run; nothing changed),$fixed"
  else
    echo "Total files processed (corrected),$fixed"
  fi
} >> "$log"

echo "Examined ${#files[@]} email20*.txt files dated $FIX_DATE; $fixed $verb."
if [ "$failed" -gt 0 ]; then echo "$failed could not be corrected (see the messages above)." >&2; fi
echo "Log: $log"
[ "$failed" -eq 0 ]
