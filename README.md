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

## Standalone program (recommended): Windows 7–11 and Linux

`remove_dup_numbers.py` is packaged into one program per system, so the computer running it does
not need Python or a browser. Download it from the
[latest release](https://github.com/Al-bit-dot/123/releases/tag/latest):

- **Windows:** `RemoveDupNumbers-windows.zip`. Right-click it, choose **Extract All**, then
  double-click `RemoveDupNumbers.exe`. The first time, Windows may warn about an unrecognised app:
  click **More info**, then **Run anyway**. One 32-bit program runs on Windows 7 through 11: it
  carries its own Python (3.7, which needs no Windows updates) and the Microsoft C runtime that
  Windows 7 lacks. The zip also
  holds `remove_dup_numbers.py` and `RemoveDupNumbers.pyw` for a Windows that has Python
  installed (see [Installing Python offline](#installing-python-offline-on-windows)): double-click
  the `.pyw` to open the window without a console.
- **Linux:** `RemoveDupNumbers-linux.tar.gz`. Extract it and run `bash install-shortcut.sh` from
  the extracted folder. It copies the files to `~/Programs` and adds a menu entry and a desktop
  icon that run the packaged `RemoveDupNumbers` program when it starts on that computer (it was
  built on Ubuntu 22.04 and needs that C library or newer, so Fedora and current Ubuntu are fine),
  and otherwise the `remove_dup_numbers.py` script with the system `python3` (Python 3.4 or
  newer, so Ubuntu 14.10 works). The script opens the same window when Python has tkinter; without
  it, it uses file dialogs from `zenity` or `kdialog`, which GNOME, Unity and KDE desktops ship.
  On newer GNOME, if the desktop icon will not start, right-click it and choose **Allow Launching**.

The window works like the `.hta` below: a folder box you can type or paste into, **Go**, **Up**,
**Browse...**, double-click a `[folder]` to open it, click a file to select it, then **Start**.
It opens at the last source folder used, or `E:\SearchInProgress` on Windows the first time
(your home folder on Linux). That folder is kept in `%APPDATA%\RemoveDupNumbers\settings.json`
on Windows and `~/.config/RemoveDupNumbers/settings.json` on Linux.

It also works from a terminal: `RemoveDupNumbers SOURCE.txt REMOVE.txt`. With Python 3.4 or newer
installed you can run `python3 remove_dup_numbers.py` directly instead (`python remove_dup_numbers.py`
on Windows); it needs nothing outside Python's own library.

GitHub builds both programs on every pull request and publishes them to the `latest` release on
every change to `main` (see `.github/workflows/build.yml`).

## Installing Python offline on Windows

Python is only needed on Windows to run `remove_dup_numbers.py` itself; `RemoveDupNumbers.exe`
carries its own. Python's official installers do not need an internet connection, so one file
downloaded on a connected computer and carried over on a USB stick is enough. Pick one:

| Download on a connected computer | For |
|---|---|
| [python-3.8.10.exe](https://www.python.org/ftp/python/3.8.10/python-3.8.10.exe) (32-bit, runs on any Windows) or [python-3.8.10-amd64.exe](https://www.python.org/ftp/python/3.8.10/python-3.8.10-amd64.exe) (64-bit Windows only) | Windows 11; Windows 7 SP1 that has update KB2533623 |
| [python-3.7.6.exe](https://www.python.org/ftp/python/3.7.6/python-3.7.6.exe) or [python-3.7.6-amd64.exe](https://www.python.org/ftp/python/3.7.6/python-3.7.6-amd64.exe) | Windows 7 SP1 without that update (also fine on Windows 11) |

1. Copy the installer over and double-click it. Click **Install Now** (tick **Add Python to PATH**
   first if you want `python` to work in a command prompt). Nothing is downloaded: the file holds
   Python, tkinter for the window, and the Microsoft C runtime that Windows 7 lacks, which it
   installs by itself.
2. On Windows 7, if the installer stops with *Windows 7 Service Pack 1 and all applicable updates
   are required*, the computer lacks update KB2533623 (every Python from 3.7.7 on checks for it).
   Either install that update first (an `.msu` file from the Microsoft Update Catalog; search for
   KB2533623, or for KB3063858, which replaced it) or use the 3.7.6 installer, which has no such check.
   Windows 7 without Service Pack 1 cannot install any of them.
3. Extract `RemoveDupNumbers-windows.zip` and double-click `RemoveDupNumbers.pyw`. It opens the
   same window as the `.exe`, without a console. The settings file is shared with the `.exe`.

Do not use the *Windows installer (web)* downloads (`...-webinstall.exe`): they fetch everything
they install from the internet. Do not use the *embeddable package* zips: they have no tkinter.
Python 3.9 and newer do not install on Windows 7 at all. The site needs no sign-in, and the files
are the same whether downloaded on Windows or Linux.

## Linux without the packaged program

`install-shortcut.sh` says so when the packaged program cannot start on a computer (it needs the C
library of Ubuntu 22.04 or newer; Ubuntu 14.10 has an older one) and points the shortcut at
`remove_dup_numbers.py` run by the system `python3` instead. The script needs only Python 3.4 or
newer. For the window it uses Python's tkinter when that is installed, and otherwise the desktop's
own file dialogs (`zenity` on GNOME and Unity, `kdialog` on KDE), which ask for the source file,
then the to-be-removed file, and show the result. Without either it still works from a terminal:
`python3 ~/Programs/remove_dup_numbers.py SOURCE.txt REMOVE.txt`.

**Ubuntu 14.10** installs Python 3.4.2 and `zenity` but not tkinter, so the dialogs are used
unless you add tkinter. For that, download these two packages on a connected computer (they are
for 64-bit Ubuntu; for 32-bit replace `amd64` with `i386` in both names), copy them over, and
install both in one command:

```
https://old-releases.ubuntu.com/ubuntu/pool/main/b/blt/blt_2.5.3-4_amd64.deb
https://old-releases.ubuntu.com/ubuntu/pool/main/p/python3-stdlib-extensions/python3-tk_3.4.2-1_amd64.deb
sudo dpkg -i blt_2.5.3-4_amd64.deb python3-tk_3.4.2-1_amd64.deb
```

**Fedora** (any current release) runs the packaged program as is, so nothing needs installing.
Running the script there instead needs tkinter or `zenity`, and Fedora Workstation installs
neither by default. Fedora's tkinter package must match the installed Python exactly, so use a
connected Fedora of the same release and update level (`rpm -q python3` prints the same on both),
run `dnf download --resolve python3-tkinter tk tcl` there, copy the `.rpm` files over, and run
`sudo dnf install ./*.rpm` (add `--disablerepo='*'` if it complains about reaching repositories).

## Web page

1. Download `RemoveDupNumbers.html` and open it in **Chrome or Edge** (Windows or Linux).
2. Under **Source file**, click **Choose folder…**, pick the folder, and allow access.
   Click folder names to go into them, `..` or the path links to go back up, and a file to select it.
3. Under **To-be-removed file**, the source folder is listed. Pick a file there, browse elsewhere,
   or click **Choose folder…** for a different folder. **Use source folder** snaps back.
4. Click **Start**. The result is written to the source file's folder, for example
   `E04D1507-order.txt` + `Squeegee_Order1.txt` → `E04D1507-order-w-o-Squeegee_Order1.txt`.
   If that file already exists you are asked before it is replaced.

The page tries to reopen the last source folder next time, but browsers do not always allow it
(for example Edge on Windows 11 when the page is opened from disk); the standalone program
always does. Untick **.txt only** to see every file.

The **Start folder** box (default `E:\SearchInProgress`) is copied to the clipboard when you click
**Choose folder…**, so you can paste it with Ctrl+V into the Windows dialog's Folder box. Browsers
do not let a page fill that box itself. Edit the box to change the path; the page remembers it.

## Windows 7 / Internet Explorer: `RemoveDupNumbers.hta`

Internet Explorer cannot run `RemoveDupNumbers.html`: it has no folder access for web pages and
does not understand the page's modern JavaScript, so allowing its blocked content does not help.
`RemoveDupNumbers.hta` is the same tool as a Windows HTML Application. It runs with the
`mshta.exe` built into every Windows version from XP to 11, needs no browser, and reads and
writes files directly.

1. Download `RemoveDupNumbers.hta` and double-click it. If Windows warns about a downloaded file,
   right-click it, choose **Properties**, tick **Unblock** (or click **Unblock**), then **OK**.
2. The source folder box starts at the last folder you used, or `E:\SearchInProgress` the first
   time. Type or paste any path and press Enter, or use **Up** and **Browse...**. Double-click a
   `[folder]` to open it and click a file to select it.
3. Pick the to-be-removed file (it starts in the source folder) and click **Start**. The result is
   saved beside the source with the same name and rules as the web page.

The last folder is remembered in the registry under `HKCU\Software\RemoveDupNumbers`.

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

`node test.js` checks the sorting and removal logic in both the page and the `.hta`.
`python3 test_remove_dup_numbers.py` runs the same checks on the standalone program. `node test.js SOURCE.txt REMOVE.txt`
also prints a summary for two real files.
