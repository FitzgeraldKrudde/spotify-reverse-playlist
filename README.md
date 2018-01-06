# spotify-reverse-playlist
This Linux bash script reverses the tracks in a playlist.

When reversing a playlist of another user then a new playlist will be created in your account.

Just invoke the script reverse-playlist.sh to get the usage information.

The script uses the [Spotify REST API](https://developer.spotify.com/web-api/). Therefore it requires curl and a few other (standard) binaries. The script will check for these pre-reqs.

Pure bash-ish, no need for temp files etc.
