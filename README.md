# spotify-reverse-playlist-recently-added

Fork of [spotify-reverse-playlist](https://github.com/FitzgeraldKrudde/spotify-reverse-playlist) that adds tracks one at a time with a delay, so they appear in reversed order when sorted by "Recently Added" in Spotify.

## Features

- Reverses the track order in any Spotify playlist
- Adds **1 track per API request** with **2-second delay** — each track gets a distinct timestamp for "Recently Added" sorting
- **Retry on 429/5xx errors** — waits 5s and retries up to 5 times on rate limits or server errors
- **macOS compatible** — tested on macOS with native tools
- No temp files, pure bash

## Usage

```bash
./reverse-playlist.sh <playlist-id> [new-name] [new-description]
```

The script will open a browser for Spotify OAuth authorization.

### Example

```bash
./reverse-playlist.sh 3QAm7nt7EiPP1wJpadZeMF
```

## Requirements

- bash
- curl
- jq
- nc (netcat)
- base64

All ship natively on macOS.

## How it works

1. Authorizes with Spotify via OAuth
2. Reads all tracks from the source playlist
3. Creates a new playlist
4. Adds tracks one at a time (reversed order) with 2-second intervals
5. If rate-limited (429) or server error (5xx), waits 5s and retries

Sort the new playlist by "Recently Added" to see tracks in reversed order.

## Credits

Original script by [FitzgeraldKrudde](https://github.com/FitzgeraldKrudde/spotify-reverse-playlist)
