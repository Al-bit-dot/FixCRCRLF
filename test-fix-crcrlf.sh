#!/usr/bin/env bash
# Tests fix-crcrlf.sh on a made-up folder tree:   bash test-fix-crcrlf.sh
# Prints one line per check and exits non-zero if any check fails.
set -uo pipefail
export TZ=America/Chicago   # dates below are local times in this zone

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fix-crcrlf.sh"
work="$(mktemp -d)"
trap 'chmod -R u+w "$work"; rm -rf "$work"' EXIT
top="$work/top"
fails=0

check() {  # check DESCRIPTION COMMAND...: report whether COMMAND succeeds
  local what="$1"; shift
  if "$@"; then echo "ok   $what"; else echo "FAIL $what"; fails=$((fails + 1)); fi
}
mk() {  # mk PATH DATE CONTENT: create PATH holding CONTENT (printf %b escapes), modified at DATE
  mkdir -p "$(dirname "$1")"
  printf '%b' "$3" > "$1"
  if [ -n "$2" ]; then touch -d "$2" "$1"; fi
}
has() {  # has FILE CONTENT: FILE holds exactly CONTENT (printf %b escapes)
  cmp -s "$1" <(printf '%b' "$2")
}
state() {  # state FILE...: checksum, modification time and permissions of each FILE
  local f
  for f in "$@"; do echo "$(sha256sum < "$f") $(stat -c '%y %a' "$f") $f"; done
}
logfile() {  # logfile FOLDER KIND: the one fix-crcrlf-KIND-*.csv log in FOLDER
  local logs=("$1"/fix-crcrlf-"$2"-*.csv)
  [ "${#logs[@]}" -eq 1 ] && [ -f "${logs[0]}" ] && echo "${logs[0]}"
}
same() {  # same A B: strings A and B are equal, else show both
  [ "$1" = "$2" ] && return 0
  printf -- '--- expected\n%s\n--- got\n%s\n' "$1" "$2"
  return 1
}

# Lines ending CR CR LF, with UTF-8 text such as the real emails have.
BAD='Subject:  Re: Test\r\r\nFrom:  Al <al@example.com>\r\r\n\r\r\nNon-breaking\xc2\xa0space, “quotes” – dash.\r\r\n> quoted\r\r\n'
GOOD='Subject:  Re: Test\r\nFrom:  Al <al@example.com>\r\n\r\nNon-breaking\xc2\xa0space, “quotes” – dash.\r\n> quoted\r\n'
DAY='2026-06-27 00:33:41'

# Files that must be corrected: top folder, sub-folders at several depths, a
# hidden folder, the first and last second of the day, a comma and quotes in
# the names, lines with mixed endings, and no line ending at the very end.
pos_top="$top/email202603231013_Top.txt"
pos_sub="$top/Sub1/email202604131051_Sub.txt"
pos_deep="$top/Sub1/Sub2/Sub3/email202605010900_Deep.txt"
pos_comma="$top/Folder, with \"quotes\"/email202601011200_Comma, name.txt"
pos_mixed="$top/Sub1/email202602020202_Mixed.txt"
pos_hidden="$top/.hidden/email202603030303_Hidden.txt"
mk "$pos_top" "$DAY" "$BAD"
mk "$pos_sub" '2026-06-27 00:34:05' "$BAD"
mk "$pos_deep" '2026-06-27 23:59:59' 'one\r\r\ntwo\r\r\nlast line, no ending'
chmod 640 "$pos_deep"
mk "$pos_comma" '2026-06-27 00:00:00' "$BAD"
mk "$pos_mixed" "$DAY" 'crcrlf\r\r\ncrlf\r\nlf\ncrcrcrlf\r\r\r\nmid\r\rline\r\r\n'
mk "$pos_hidden" "$DAY" "$BAD"
positives=("$pos_top" "$pos_sub" "$pos_deep" "$pos_comma" "$pos_mixed" "$pos_hidden")

# Files that must not be touched. All but the line-ending cases hold CR CR LF.
neg=()
neg_mk() { mk "$1" "$2" "$3"; neg+=("$1"); }
# ...name does not start with email20
neg_mk "$top/Email202603231013_Capital.txt" "$DAY" "$BAD"
neg_mk "$top/email19990101_Old.txt" "$DAY" "$BAD"
neg_mk "$top/myemail202603231013.txt" "$DAY" "$BAD"
neg_mk "$top/email2_026.txt" "$DAY" "$BAD"
neg_mk "$top/Sub1/notes.txt" "$DAY" "$BAD"
# ...not a .txt file
neg_mk "$top/email202603231013_Upper.TXT" "$DAY" "$BAD"
neg_mk "$top/email202603231013.txt.bak" "$DAY" "$BAD"
neg_mk "$top/Sub1/email202603231013.eml" "$DAY" "$BAD"
neg_mk "$top/email202603231013.csv" "$DAY" "$BAD"
neg_mk "$top/email202603231013" "$DAY" "$BAD"
neg_mk "$top/email202603231013_txt" "$DAY" "$BAD"
# ...modified on another day
neg_mk "$top/email202606262359_DayBefore.txt" '2026-06-26 23:59:59' "$BAD"
neg_mk "$top/Sub1/email202606280000_DayAfter.txt" '2026-06-28 00:00:00' "$BAD"
neg_mk "$top/email202506270033_YearBefore.txt" '2025-06-27 00:33:41' "$BAD"
neg_mk "$top/Sub1/Sub2/email202607270033_MonthAfter.txt" '2026-07-27 00:33:41' "$BAD"
neg_mk "$top/Sub1/Sub2/Sub3/email202610080000_Today.txt" '' "$BAD"
# ...right name and day, but no CR CR LF line ending
neg_mk "$top/email202603231013_WindowsCRLF.txt" "$DAY" "$GOOD"
neg_mk "$top/Sub1/email202603231013_LinuxLF.txt" "$DAY" 'Subject:  Re: Test\nFrom:  Al\n\nBody\n'
neg_mk "$top/Sub1/Sub2/email202603231013_OldMacCR.txt" "$DAY" 'Subject:  Re: Test\rFrom:  Al\r'
neg_mk "$top/email202603231013_CRCRinsideLine.txt" "$DAY" 'a\r\rb\r\nc\r\n'
neg_mk "$top/email202603231013_Empty.txt" "$DAY" ''
# ...a folder named like a match, and a link to a file outside the tree
mkdir -p "$top/email20_folder.txt"
neg_mk "$top/email20_folder.txt/inner.txt" "$DAY" "$BAD"
neg_mk "$work/outside/email202603231013_LinkTarget.txt" "$DAY" "$BAD"
ln -s "$work/outside/email202603231013_LinkTarget.txt" "$top/email202603231013_Link.txt"
examined=$(( ${#positives[@]} + 5 ))   # the positives and the five line-ending cases

expected_rows=$(printf '"%s","%s"\n' \
  email202603030303_Hidden.txt "$top/.hidden" \
  'email202601011200_Comma, name.txt' "$top/Folder, with \"\"quotes\"\"" \
  email202605010900_Deep.txt "$top/Sub1/Sub2/Sub3" \
  email202602020202_Mixed.txt "$top/Sub1" \
  email202604131051_Sub.txt "$top/Sub1" \
  email202603231013_Top.txt "$top")

all_files=("${positives[@]}" "${neg[@]}")
before_all="$(state "${all_files[@]}")"
before_neg="$(state "${neg[@]}")"
before_pos="$(state "${positives[@]}" | awk '{print $3, $4, $5, $6, $7}')"   # times and permissions

echo "== Dry run"
out="$(bash "$script" --dry-run "$top" 2>&1)"; status=$?
check "dry run exits 0" [ "$status" -eq 0 ]
check "dry run changes no file" same "$before_all" "$(state "${all_files[@]}")"
log="$(logfile "$top" dry-run)"
check "dry run writes its own log in the start folder" [ -n "$log" ]
check "dry-run log lists the files that would be corrected" same "$(printf '"Filename","Directory"\n%s\nFiles examined (email20*.txt dated 2026-06-27),%s\nTotal files that would be processed (dry run; nothing changed),6' "$expected_rows" "$examined")" "$(cat "$log")"
check "dry run says what it would do" grep -q '6 would be corrected' <<< "$out"
rm -f "$log"

echo "== Run"
out="$(bash "$script" "$top" 2>&1)"; status=$?
check "run exits 0" [ "$status" -eq 0 ]
log="$(logfile "$top" log)"
check "log is written in the start folder" [ -n "$log" ]
check "log lists each corrected file and folder (sorted, CSV quoted) and the totals" same "$(printf '"Filename","Directory"\n%s\nFiles examined (email20*.txt dated 2026-06-27),%s\nTotal files processed (corrected),6' "$expected_rows" "$examined")" "$(cat "$log")"
check "top-folder file corrected" has "$pos_top" "$GOOD"
check "sub-folder file corrected" has "$pos_sub" "$GOOD"
check "file three folders down, at 23:59:59, with no final line ending, corrected" has "$pos_deep" 'one\r\ntwo\r\nlast line, no ending'
check "file at 00:00:00 with a comma and quotes in its path corrected" has "$pos_comma" "$GOOD"
check "hidden-folder file corrected" has "$pos_hidden" "$GOOD"
check "mixed file: only lines ending in 2+ CRs change" has "$pos_mixed" 'crcrlf\r\ncrlf\r\nlf\ncrcrcrlf\r\nmid\r\rline\r\n'
check "corrected files keep their modification times and permissions" same "$before_pos" "$(state "${positives[@]}" | awk '{print $3, $4, $5, $6, $7}')"
check "deep file is still mode 640" [ "$(stat -c %a "$pos_deep")" = 640 ]
check "files that do not qualify are untouched (content, time, permissions)" same "$before_neg" "$(state "${neg[@]}")"
check "the link is still a link" [ -L "$top/email202603231013_Link.txt" ]
check "no temporary files left behind" [ -z "$(find "$work" -name '.fix-crcrlf.*')" ]
check "screen output names the count" grep -q 'Examined 11 email20\*.txt files dated 2026-06-27; 6 corrected.' <<< "$out"
rm -f "$log"

echo "== Second run"
after_first="$(state "${all_files[@]}")"
bash "$script" "$top" > /dev/null 2>&1; status=$?
log="$(logfile "$top" log)"
check "second run exits 0" [ "$status" -eq 0 ]
check "second run corrects nothing (files kept their date, so they are examined again)" same "$(printf '"Filename","Directory"\nFiles examined (email20*.txt dated 2026-06-27),%s\nTotal files processed (corrected),0' "$examined")" "$(cat "$log")"
check "second run changes no file" same "$after_first" "$(state "${all_files[@]}")"

echo "== Start folder from the current folder and from a relative path"
mk "$work/rel/email20_a.txt" "$DAY" "$BAD"
mk "$work/rel/Sub/email20_b.txt" "$DAY" "$BAD"
(cd "$work/rel/Sub" && bash "$script" > /dev/null 2>&1)
check "no argument: the current folder is searched" has "$work/rel/Sub/email20_b.txt" "$GOOD"
check "no argument: folders above it are not" has "$work/rel/email20_a.txt" "$BAD"
log="$(logfile "$work/rel/Sub" log)"
check "no argument: log in the current folder with the full folder path" same "$(printf '"Filename","Directory"\n"email20_b.txt","%s"\nFiles examined (email20*.txt dated 2026-06-27),1\nTotal files processed (corrected),1' "$work/rel/Sub")" "$(cat "$log")"
(cd "$work" && bash "$script" rel > /dev/null 2>&1)
check "relative start folder: searched" has "$work/rel/email20_a.txt" "$GOOD"
log="$(logfile "$work/rel" log)"
check "relative start folder: log shows the full folder path" same "$(printf '"Filename","Directory"\n"email20_a.txt","%s"\nFiles examined (email20*.txt dated 2026-06-27),2\nTotal files processed (corrected),1' "$work/rel")" "$(cat "$log")"

echo "== Problems"
mk "$work/late/email20_late.txt" "$DAY" "$BAD"
bash "$script" "$work/late" --dry-run > /dev/null 2>&1; status=$?
check "--dry-run after the folder is still a dry run" has "$work/late/email20_late.txt" "$BAD"
check "...exits 0" [ "$status" -eq 0 ]
check "...and writes the dry-run log" [ -n "$(logfile "$work/late" dry-run)" ]
bash "$script" "$work/late" "$top" > /dev/null 2>&1; status=$?
check "two folders are refused (exit 2)" [ "$status" -eq 2 ]
check "...and nothing changes" has "$work/late/email20_late.txt" "$BAD"
bash "$script" "$work/no such folder" > /dev/null 2>&1; status=$?
check "a missing start folder is refused (exit 2)" [ "$status" -eq 2 ]
if [ "$(id -u)" -ne 0 ]; then
  mk "$work/perm/locked/email20_locked.txt" "$DAY" "$BAD"
  mk "$work/perm/open/email20_open.txt" "$DAY" "$BAD"
  chmod a-w "$work/perm/locked"
  out="$(bash "$script" "$work/perm" 2>&1)"; status=$?
  chmod u+w "$work/perm/locked"
  check "a file in a read-only folder is reported (exit 1)" [ "$status" -eq 1 ]
  check "...and left as it was" has "$work/perm/locked/email20_locked.txt" "$BAD"
  check "...and the other files are still corrected" has "$work/perm/open/email20_open.txt" "$GOOD"
  check "...and the message names it" grep -q "Could not correct: .*email20_locked.txt" <<< "$out"
  check "...and the log counts it" same "$(printf '"Filename","Directory"\n"email20_open.txt","%s"\nFiles examined (email20*.txt dated 2026-06-27),2\nFiles that could not be corrected,1\nTotal files processed (corrected),1' "$work/perm/open")" "$(cat "$(logfile "$work/perm" log)")"
else
  echo "skip read-only folder checks (running as root, which can write anywhere)"
fi

echo
if [ "$fails" -eq 0 ]; then echo "All checks passed."; else echo "$fails check(s) FAILED."; fi
[ "$fails" -eq 0 ]
