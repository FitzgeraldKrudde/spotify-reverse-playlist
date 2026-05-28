# macOS Compatibility Notes

This script (`reverse-playlist.sh`) was originally written for Linux. The following changes were made for macOS:

## Changes applied

1. **Added `#!/bin/bash` shebang** — the script uses bash-specific features (`[[ ]]`, `<<<`)
2. **`tac` → `tail -r`** — macOS doesn't have `tac`; a `tac() { tail -r ; }` shim is defined
3. **`nc -l PORT` instead of `nc -l -p PORT`** — BSD nc on macOS uses `-l <port>` without `-p`
4. **`cut -d` instead of `cut --delimiter=`** — macOS `cut` doesn't support long options
5. **`printf` instead of `echo -e ... \c`** — for portable newline suppression
6. **`checkForBinary base64` instead of `checkForBrewBinary base64`** — macOS ships base64 natively
7. **`printf '%s\n'` instead of `echo | xargs --max-args=1`** — more reliable normalization of track URIs
8. **1 track per API request with 2s delay** — adds tracks one at a time so they get distinct timestamps for "Recently Added" sorting
9. **Retry on 429/5xx** — on rate limit or server errors, waits 5s and retries up to 5 times
10. **Process substitution instead of pipe** — `while read` loop uses `< <(...)` so `exit 1` properly stops the script (no subshell leak)

## Running

```bash
./reverse-playlist.sh <playlist-id> [new-name] [new-description]
```

The script will open a browser for Spotify OAuth authorization.

----
Credits:
https://github.com/FitzgeraldKrudde/spotify-reverse-playlist
