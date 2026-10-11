# Fix CR CR LF email files

`fix-crcrlf.sh` repairs the `email20*.txt` files processed on 2026-06-27 whose lines end CR CR LF
instead of the Windows CR LF. Run it from a Linux terminal with the top folder to search, or `cd`
there and leave the folder out:

```
bash fix-crcrlf.sh /path/to/top/folder
bash fix-crcrlf.sh --dry-run /path/to/top/folder     # only lists what it would correct
```

It searches that folder and every folder below it (hidden ones too) for regular files that

- are named `email20….txt`, in exactly that case (`Email20…`, `….TXT`, `….txt.bak` and links are skipped),
- were last modified on 2026-06-27 in the computer's own time zone (Linux keeps the modification
  date reliably, unlike the creation date; to use another day change `FIX_DATE` at the top of the
  script), and
- have at least one line ending in two or more CRs before the LF.

In those files each such line is changed to end in one CR LF. Nothing else changes: lines that
already end CR LF or LF stay as they are, and the file keeps its modification date and permissions,
so it is still dated 2026-06-27 and a second run finds nothing to do. Files whose lines already end
CR LF or LF are not touched at all.

The log `fix-crcrlf-log-YYYYMMDD-HHMMSS.csv` is saved in the top folder: one row per corrected file
with its name and full folder, then the totals.

```
"Filename","Directory"
"email202603231013_Re_American_Security_Cabinets_18.txt","/mnt/data/Mail/2026/03"
"email202604131051_Re_American_Security_Cabinets_21.txt","/mnt/data/Mail/2026/04"
Files examined (email20*.txt dated 2026-06-27),5
Total files processed (corrected),2
```

`--dry-run` changes nothing and writes the same list to `fix-crcrlf-dry-run-YYYYMMDD-HHMMSS.csv`.
A file that cannot be rewritten (for example in a read-only folder) is named on screen and counted
in the log, the other files are still corrected, and the script ends with exit status 1.

`bash test-fix-crcrlf.sh` builds a sample folder tree and checks that files in sub-folders at every
depth are corrected exactly, and that files with another name start, another extension, another
date, or lines already ending CR LF or LF are left alone.
