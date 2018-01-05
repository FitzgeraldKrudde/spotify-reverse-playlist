# spotify-reverse-playlist
This Linux bash script reads an existing Spotify playlist (possibly from another user) and creates a new playlist with the tracks in reversed order. 

Just invoke the script reverse-playlist.sh to get the usage information.

The script uses the [Spotify REST API](https://developer.spotify.com/web-api/). Therefore it requires curl and a few other (standard) binaries. The script will check for these pre-reqs.

Pure bash-ish, no need for temp files etc.
