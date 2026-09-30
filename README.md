# Patent list tools

Two single web pages that run locally in **Chrome or Edge** on Windows or Linux. No files leave your computer.

- [PatCopyPrint](#patcopyprint): turns a list of US patent numbers into a bash script that copies and prints each PDF.
- [Remove Dup Numbers](#remove-dup-numbers): removes from one list every number that appears in another.

# PatCopyPrint

`PatCopyPrint.html` reads a patent list and saves `<list name>out.txt` next to it, for example
`SamplePatList.txt` → `SamplePatListout.txt`. The saved file is a bash script (always Linux line endings)
that copies each PDF from `PatGrant/…` or `PubApp/…` and prints it with `lp`, like `samples/SamplePatListout.txt`.

## Use it

1. Open `PatCopyPrint.html` in Chrome or Edge. Click **Choose folder…** and allow access. Click folders
   to go into them, `..` or the path links to go back up, and a file to select it. Next time the page
   reopens the last folder (the browser may ask for one click to allow it again).
2. Choose **Fetcher Format** or **Raw text**, the print order, and whether a repeated number prints once.
3. Click **Start**. If the script file already exists you are asked before it is replaced.

**Script settings** holds the lines at the top of every script (the share path, `path2`, size limits
and the copies prompt). Edit them there; **Restore default** brings back the original ones.

## Number rules

Every number becomes one of these forms:

| Kind | Allowed in the list | Becomes | PDF |
|---|---|---|---|
| Utility patent | 1–8 digits | 8 digits, zero padded: `9123456` → `09123456` | `PatGrant/09/123/09123456.pdf` |
| Published application | 10 or 11 digits, year 2001 to this year | 11 digits: `2002123457` → `20020123457` | `PubApp/2002/0123/US20020123457A1.pdf` |
| D, H, T, X | letter + 1–7 digits | letter + 7 digits: `D123` → `D0000123` | `PatGrant/D0/000/D0000123.pdf` |
| RE, RD, RX, AI, PP | two letters + 1–6 digits | two letters + 6 digits | `PatGrant/RE/012/RE012345.pdf` |

Lower case letters and spaces around an entry are accepted.

## Fetcher Format

One number per line; blank lines are ignored; Windows or Linux line endings. If every line is valid
the script is saved straight away. Otherwise a table lists each problem line with the reason and, where
one can be worked out, a correction already filled in (extra leading zeros dropped, spaces and commas
removed, `US 7,123,456 B2` → `07123456`, `Des. 512,345` → `D0512345`). Edit any correction or tick
**Skip**, then **Apply and create script**. Tick **Also save these corrections** to fix the list file
itself (the original is kept as `<list>.txt.bak`).

## Raw text

Any text, such as a patent's References Cited section. Numbers are picked out and shown in a table with
the text around them. Clear matches are ticked; doubtful ones are greyed and unticked with the reason;
tick or untick any row, then **Create script**. It recognises:

- `7,123,456`, `7123456`, `US 7,123,456 B2`, `U.S. Pat. No. 7,123,456`, lists like `Nos. 7,123,456, 6,234,567 and 5,345,678`
- `D512,345`, `D 512,345`, `Des. 512,345`, `Design 512,345`, `Des. Pat. No. 512,345`, `USD512345S`
- `RE45,678`, `Re. 45,678`, `Reissue 45,678`, `Plant 12,345` (→ `PP012345`), and the other letter prefixes
- `2005/0123456`, `US 2005/0123456 A1`, `US20050123456A1`, `2005-0123456`, `20050123456`, `2005123456`

It never takes:

- a slash form unless exactly four digits (a year from 2001 to this year) come before the slash and nothing
  follows the number: `2001/1` → `20010000001`, but not `201/1/1`, `2001/1/5`, `12/31/2005` or
  application numbers like `10/123,456`
- decimals (`3.14`), dashed runs (`555-1234`), numbers inside words, foreign documents (`WO 2010/123456`,
  `EP1234567`, `DE 10 2004 …`), or numbers of 9 or 12+ digits (listed under "not usable")

Doubtful (unticked): short bare numbers with no `Pat.`/`No.` before them, figure, claim, column, line or
page references, `2020/12` (could be a date), 10-digit bare numbers (could be phone numbers), letter
prefixes followed by a space other than `D` and `RE`, and patent numbers above the limit set in
**Script settings** (13,500,000 by default).

## Tests

`node test-patcopyprint.js` checks the rules and that `samples/SamplePatList.txt` gives exactly
`samples/SamplePatListout.txt`. `node test-patcopyprint.js LIST.txt` (add `--raw` for raw text) prints
what a real file converts to.

# Remove Dup Numbers

A single web page, `RemoveDupNumbers.html`, that removes from a **source** list every number that
also appears in a **to-be-removed** list, and saves the result next to the source as
`<source>-w-o-<removed>.txt`. It runs locally in your browser; no files leave your computer.

## Use it

1. Download `RemoveDupNumbers.html` and open it in **Chrome or Edge** (Windows or Linux).
2. Under **Source file**, click **Choose folder…**, pick the folder, and allow access.
   Click folder names to go into them, `..` or the path links to go back up, and a file to select it.
3. Under **To-be-removed file**, the source folder is listed. Pick a file there, browse elsewhere,
   or click **Choose folder…** for a different folder. **Use source folder** snaps back.
4. Click **Start**. The result is written to the source file's folder, for example
   `E04D1507-order.txt` + `Squeegee_Order1.txt` → `E04D1507-order-w-o-Squeegee_Order1.txt`.
   If that file already exists you are asked before it is replaced.

Next time you open the page it reopens the last source folder (the browser may ask you to
confirm access with one click). Untick **.txt only** to see every file.

## Rules

- One entry per line; Windows (CRLF) and Linux (LF) line endings both work, blank lines are ignored.
- Numbers are compared by value, so `02847689` matches `2847689`. The saved file keeps the
  source's original spelling (leading zeros stay) and its line-ending style.
- The result is sorted by numeric value, lowest first. Entries that are not plain numbers
  (like `H000982`) are kept and listed at the end; they are removed only if the removal file
  contains exactly the same text.
- After a run, **Show result details** lists what was removed and which removal entries were
  not in the source.

## Firefox and other browsers

Browsers without folder access (Firefox, Safari) show two plain file pickers instead, and the
result is downloaded to your Downloads folder rather than saved beside the source.

If Chrome refuses folder access when the page is opened straight from disk, serve it locally
instead: run `python3 -m http.server` in the folder that holds the page and open
http://localhost:8000/RemoveDupNumbers.html (or `/PatCopyPrint.html`).

## Remove Dup Numbers tests

`node test.js` checks the sorting and removal logic. `node test.js SOURCE.txt REMOVE.txt`
also prints a summary for two real files.
