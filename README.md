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
http://localhost:8000/RemoveDupNumbers.html.

## Tests

`node test.js` checks the sorting and removal logic. `node test.js SOURCE.txt REMOVE.txt`
also prints a summary for two real files.
